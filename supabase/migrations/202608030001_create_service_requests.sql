create table if not exists public.service_requests (
  id uuid primary key default gen_random_uuid(),
  customer_id uuid not null references public.profiles(id) on delete cascade,
  professional_id uuid not null references public.profiles(id) on delete restrict,
  service_category text not null,
  title text not null,
  description text not null,
  status text not null default 'pending' check (status in (
    'pending',
    'under_review',
    'quoted',
    'accepted',
    'scheduled',
    'in_progress',
    'pending_customer_confirmation',
    'completed',
    'reviewed',
    'cancelled'
  )),
  scheduled_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists service_requests_customer_updated_idx
on public.service_requests (customer_id, updated_at desc);

create index if not exists service_requests_professional_updated_idx
on public.service_requests (professional_id, updated_at desc);

alter table public.service_requests enable row level security;

create policy "Customers can create their requests"
on public.service_requests for insert to authenticated
with check ((select auth.uid()) = customer_id);

create policy "Involved users can read requests"
on public.service_requests for select to authenticated
using ((select auth.uid()) in (customer_id, professional_id));

create policy "Involved users can update requests"
on public.service_requests for update to authenticated
using ((select auth.uid()) in (customer_id, professional_id))
with check ((select auth.uid()) in (customer_id, professional_id));

create or replace function public.protect_service_request_fields()
returns trigger
language plpgsql
security invoker
set search_path = ''
as $$
begin
  if new.id <> old.id
    or new.customer_id <> old.customer_id
    or new.professional_id <> old.professional_id
    or new.service_category <> old.service_category
    or new.title <> old.title
    or new.description <> old.description then
    raise exception 'Solo se pueden actualizar el estado y la programación.';
  end if;
  new.created_at = old.created_at;
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists service_requests_protect_fields
on public.service_requests;
create trigger service_requests_protect_fields
before update on public.service_requests
for each row execute function public.protect_service_request_fields();
