create table if not exists public.professional_profiles (
  id uuid primary key references public.profiles(id) on delete cascade,
  display_name text not null,
  profession text not null,
  rating numeric(3, 2) not null default 0 check (rating between 0 and 5),
  review_count integer not null default 0 check (review_count >= 0),
  location text not null default '',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.professional_profiles enable row level security;
create policy "Authenticated users can discover professionals"
on public.professional_profiles for select to authenticated using (true);
create policy "Professionals can manage their listing"
on public.professional_profiles for all to authenticated
using ((select auth.uid()) = id)
with check ((select auth.uid()) = id);

create policy "Request participants can read counterpart profiles"
on public.profiles for select to authenticated
using (
  (select auth.uid()) = id
  or exists (
    select 1 from public.service_requests request
    where (select auth.uid()) in (request.customer_id, request.professional_id)
      and profiles.id in (request.customer_id, request.professional_id)
  )
);

create table if not exists public.ratings (
  request_id uuid primary key references public.service_requests(id) on delete cascade,
  professional_id uuid not null references public.profiles(id) on delete cascade,
  customer_id uuid not null references public.profiles(id) on delete cascade,
  stars integer not null check (stars between 1 and 5),
  comment text,
  created_at timestamptz not null default now()
);

alter table public.ratings enable row level security;
create policy "Request participants can read ratings"
on public.ratings for select to authenticated
using ((select auth.uid()) in (customer_id, professional_id));

create or replace view public.professional_rating_summaries
with (security_invoker = true) as
select
  professional_id,
  coalesce(avg(stars), 0)::double precision as average_rating,
  count(*)::integer as review_count,
  count(*)::integer as completed_jobs_count
from public.ratings
group by professional_id;

create or replace function public.submit_service_rating(
  p_request_id uuid,
  p_professional_id uuid,
  p_stars integer,
  p_comment text default null
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  if p_stars not between 1 and 5 then
    raise exception 'La calificación debe estar entre 1 y 5.';
  end if;
  if not exists (
    select 1 from public.service_requests request
    where request.id = p_request_id
      and request.customer_id = (select auth.uid())
      and request.professional_id = p_professional_id
      and request.status = 'completed'
  ) then
    raise exception 'No puedes calificar esta solicitud.';
  end if;
  insert into public.ratings (
    request_id, professional_id, customer_id, stars, comment
  ) values (
    p_request_id, p_professional_id, (select auth.uid()), p_stars, p_comment
  );
  update public.service_requests set status = 'reviewed'
  where id = p_request_id and status = 'completed';
end;
$$;
revoke execute on function public.submit_service_rating(uuid, uuid, integer, text)
from public, anon;
grant execute on function public.submit_service_rating(uuid, uuid, integer, text)
to authenticated;

drop policy if exists "Involved users can update requests"
on public.service_requests;

revoke execute on function public.apply_request_transition(
  uuid, text, text, text, jsonb
) from authenticated;
revoke execute on function public.append_request_event(uuid, text, jsonb)
from authenticated;

create or replace function public.transition_request_status(
  p_request_id uuid,
  p_expected_status text,
  p_new_status text,
  p_event_type text default null,
  p_payload jsonb default '{}'::jsonb
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  request public.service_requests%rowtype;
  actor uuid := (select auth.uid());
  allowed boolean := false;
begin
  select * into request from public.service_requests where id = p_request_id;
  if request.id is null or actor not in (request.customer_id, request.professional_id) then
    raise exception 'No tienes acceso a esta solicitud.';
  end if;
  allowed := case
    when p_expected_status in ('pending', 'under_review')
      and p_new_status = 'cancelled' and actor = request.professional_id
      and p_event_type is null then true
    when p_expected_status = 'accepted' and p_new_status = 'scheduled'
      and actor = request.customer_id and p_event_type = 'schedule_accepted' then true
    when p_expected_status = 'scheduled' and p_new_status = 'in_progress'
      and actor = request.professional_id and p_event_type = 'work_started' then true
    when p_expected_status = 'in_progress'
      and p_new_status = 'pending_customer_confirmation'
      and actor = request.professional_id and p_event_type = 'work_completed' then true
    when p_expected_status = 'pending_customer_confirmation'
      and p_new_status = 'completed'
      and actor = request.customer_id and p_event_type = 'rating_requested' then true
    else false
  end;
  if not allowed then raise exception 'Transición de solicitud no permitida.'; end if;
  update public.service_requests set status = p_new_status
  where id = p_request_id and status = p_expected_status;
  if not found then
    raise exception 'La solicitud cambió. Actualiza e intenta nuevamente.';
  end if;
  if p_event_type is not null then
    insert into public.request_events (request_id, type, payload)
    values (p_request_id, p_event_type, coalesce(p_payload, '{}'::jsonb));
  end if;
end;
$$;

create or replace function public.propose_request_schedule(
  p_request_id uuid,
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
      and request.professional_id = (select auth.uid())
      and request.status = 'accepted'
  ) then raise exception 'No puedes proponer un horario para esta solicitud.'; end if;
  insert into public.request_events (request_id, type, payload)
  values (p_request_id, 'schedule_proposed', coalesce(p_payload, '{}'::jsonb));
end;
$$;

create or replace function public.update_request_schedule(
  p_request_id uuid,
  p_scheduled_at timestamptz
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  update public.service_requests request set scheduled_at = p_scheduled_at
  where request.id = p_request_id
    and (select auth.uid()) in (request.customer_id, request.professional_id);
  if not found then raise exception 'No tienes acceso a esta solicitud.'; end if;
end;
$$;

revoke execute on function public.transition_request_status(uuid, text, text, text, jsonb)
from public, anon;
revoke execute on function public.propose_request_schedule(uuid, jsonb)
from public, anon;
revoke execute on function public.update_request_schedule(uuid, timestamptz)
from public, anon;
grant execute on function public.transition_request_status(uuid, text, text, text, jsonb)
to authenticated;
grant execute on function public.propose_request_schedule(uuid, jsonb)
to authenticated;
grant execute on function public.update_request_schedule(uuid, timestamptz)
to authenticated;
