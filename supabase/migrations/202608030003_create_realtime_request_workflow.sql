create table if not exists public.quotations (
  request_id uuid primary key
    references public.service_requests(id) on delete cascade,
  professional_id uuid not null references public.profiles(id) on delete cascade,
  price numeric(12, 2) not null check (price >= 0),
  description text not null,
  estimated_duration text not null,
  status text not null default 'pending'
    check (status in ('pending', 'accepted', 'rejected')),
  created_at timestamptz not null default now()
);

create table if not exists public.request_events (
  id uuid primary key default gen_random_uuid(),
  request_id uuid not null
    references public.service_requests(id) on delete cascade,
  type text not null check (type in (
    'quotation_created',
    'quotation_accepted',
    'quotation_rejected',
    'schedule_proposed',
    'schedule_accepted',
    'work_started',
    'work_completed',
    'rating_requested'
  )),
  payload jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create index if not exists request_events_request_created_idx
on public.request_events (request_id, created_at, id);

alter table public.quotations enable row level security;
alter table public.request_events enable row level security;

create policy "Request participants can read quotations"
on public.quotations for select to authenticated
using (exists (
  select 1 from public.service_requests request
  where request.id = quotations.request_id
    and (select auth.uid()) in (request.customer_id, request.professional_id)
));

create policy "Assigned professionals can create quotations"
on public.quotations for insert to authenticated
with check (
  professional_id = (select auth.uid())
  and exists (
    select 1 from public.service_requests request
    where request.id = quotations.request_id
      and request.professional_id = (select auth.uid())
  )
);

create policy "Request participants can read events"
on public.request_events for select to authenticated
using (exists (
  select 1 from public.service_requests request
  where request.id = request_events.request_id
    and (select auth.uid()) in (request.customer_id, request.professional_id)
));

create or replace function public.apply_request_transition(
  p_request_id uuid,
  p_expected_status text,
  p_new_status text,
  p_event_type text,
  p_payload jsonb default '{}'::jsonb
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  affected integer;
begin
  if not exists (
    select 1 from public.service_requests request
    where request.id = p_request_id
      and (select auth.uid()) in (
        request.customer_id,
        request.professional_id
      )
  ) then
    raise exception 'No tienes acceso a esta solicitud.';
  end if;

  update public.service_requests
  set status = p_new_status
  where id = p_request_id and status = p_expected_status;
  get diagnostics affected = row_count;
  if affected <> 1 then
    raise exception 'La solicitud cambió. Actualiza e intenta nuevamente.';
  end if;

  insert into public.request_events (request_id, type, payload)
  values (p_request_id, p_event_type, coalesce(p_payload, '{}'::jsonb));
end;
$$;

create or replace function public.create_request_quotation(
  p_request_id uuid,
  p_expected_status text,
  p_price numeric,
  p_description text,
  p_estimated_duration text
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  professional uuid;
begin
  select request.professional_id into professional
  from public.service_requests request
  where request.id = p_request_id
    and request.status = p_expected_status
    and request.professional_id = (select auth.uid());
  if professional is null then
    raise exception 'No puedes cotizar esta solicitud.';
  end if;

  insert into public.quotations (
    request_id, professional_id, price, description, estimated_duration
  ) values (
    p_request_id, professional, p_price, p_description, p_estimated_duration
  );

  perform public.apply_request_transition(
    p_request_id,
    p_expected_status,
    'quoted',
    'quotation_created',
    jsonb_build_object('price', p_price)
  );
end;
$$;

create or replace function public.append_request_event(
  p_request_id uuid,
  p_event_type text,
  p_payload jsonb default '{}'::jsonb
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  if not exists (
    select 1 from public.service_requests request
    where request.id = p_request_id
      and (select auth.uid()) in (
        request.customer_id,
        request.professional_id
      )
  ) then
    raise exception 'No tienes acceso a esta solicitud.';
  end if;
  insert into public.request_events (request_id, type, payload)
  values (p_request_id, p_event_type, coalesce(p_payload, '{}'::jsonb));
end;
$$;

create or replace function public.resolve_request_quotation(
  p_request_id uuid,
  p_expected_status text,
  p_resolution text
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  next_status text;
  event_type text;
begin
  if p_resolution = 'accepted' then
    next_status := 'accepted';
    event_type := 'quotation_accepted';
  elsif p_resolution = 'rejected' then
    next_status := 'cancelled';
    event_type := 'quotation_rejected';
  else
    raise exception 'Resolución de cotización inválida.';
  end if;

  update public.quotations
  set status = p_resolution
  where request_id = p_request_id
    and status = 'pending'
    and exists (
      select 1 from public.service_requests request
      where request.id = p_request_id
        and request.customer_id = (select auth.uid())
    );
  if not found then
    raise exception 'La cotización ya no está disponible.';
  end if;

  perform public.apply_request_transition(
    p_request_id,
    p_expected_status,
    next_status,
    event_type,
    '{}'::jsonb
  );
end;
$$;

revoke execute on function public.apply_request_transition(
  uuid, text, text, text, jsonb
) from public, anon;
revoke execute on function public.create_request_quotation(
  uuid, text, numeric, text, text
) from public, anon;
revoke execute on function public.append_request_event(uuid, text, jsonb)
from public, anon;
revoke execute on function public.resolve_request_quotation(
  uuid, text, text
) from public, anon;
grant execute on function public.apply_request_transition(
  uuid, text, text, text, jsonb
) to authenticated;
grant execute on function public.create_request_quotation(
  uuid, text, numeric, text, text
) to authenticated;
grant execute on function public.append_request_event(uuid, text, jsonb)
to authenticated;
grant execute on function public.resolve_request_quotation(
  uuid, text, text
) to authenticated;

do $$
begin
  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public'
      and tablename = 'quotations'
  ) then
    alter publication supabase_realtime add table public.quotations;
  end if;
  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public'
      and tablename = 'request_events'
  ) then
    alter publication supabase_realtime add table public.request_events;
  end if;
end;
$$;
