create table if not exists public.reports (
  id uuid primary key default gen_random_uuid(),
  reporter_id uuid not null references public.profiles(id) on delete cascade,
  request_id uuid references public.service_requests(id) on delete set null,
  reason text not null,
  status text not null default 'open'
    check (status in ('open', 'in_review', 'resolved', 'dismissed')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists reports_created_idx
on public.reports (created_at desc);

alter table public.reports enable row level security;

create policy "Users can open reports"
on public.reports for insert to authenticated
with check ((select auth.uid()) = reporter_id);

create policy "Admins can read reports"
on public.reports for select to authenticated
using (exists (
  select 1 from public.profiles profile
  where profile.id = (select auth.uid()) and profile.role = 'admin'
));

create or replace function public.get_admin_dashboard(p_since timestamptz)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  result jsonb;
begin
  if not exists (
    select 1 from public.profiles profile
    where profile.id = (select auth.uid()) and profile.role = 'admin'
  ) then
    raise exception 'No tienes permisos de administrador.';
  end if;

  with activity as (
    select
      'user-' || profile.id::text as id,
      'userRegistered' as type,
      'Nuevo usuario: ' || profile.display_name as title,
      profile.created_at as occurred_at
    from public.profiles profile
    where profile.created_at >= p_since
    union all
    select
      'professional-' || professional.id::text,
      'professionalCreated',
      'Nuevo profesional: ' || professional.display_name,
      professional.created_at
    from public.professional_profiles professional
    where professional.created_at >= p_since
    union all
    select
      'request-' || request.id::text,
      'requestCreated',
      'Solicitud creada: ' || request.title,
      request.created_at
    from public.service_requests request
    where request.created_at >= p_since
    union all
    select
      'quotation-' || quotation.request_id::text,
      'quotationSent',
      'Cotización enviada',
      quotation.created_at
    from public.quotations quotation
    where quotation.created_at >= p_since
    union all
    select
      'completed-' || event.id::text,
      'jobCompleted',
      'Trabajo completado',
      event.created_at
    from public.request_events event
    where event.type = 'work_completed' and event.created_at >= p_since
    union all
    select
      'report-' || report.id::text,
      'reportOpened',
      'Reporte abierto: ' || report.reason,
      report.created_at
    from public.reports report
    where report.created_at >= p_since
  ), recent_activity as (
    select * from activity order by occurred_at desc limit 20
  )
  select jsonb_build_object(
    'metrics', jsonb_build_object(
      'total_users', (
        select count(*) from public.profiles where created_at >= p_since
      ),
      'total_professionals', (
        select count(*) from public.professional_profiles
        where created_at >= p_since
      ),
      'active_requests', (
        select count(*) from public.service_requests
        where created_at >= p_since
          and status not in ('completed', 'reviewed', 'cancelled')
      ),
      'completed_jobs', (
        select count(*) from public.service_requests
        where updated_at >= p_since and status in ('completed', 'reviewed')
      ),
      'cancelled_requests', (
        select count(*) from public.service_requests
        where updated_at >= p_since and status = 'cancelled'
      ),
      'average_rating', coalesce((
        select round(avg(stars)::numeric, 2) from public.ratings
        where created_at >= p_since
      ), 0)
    ),
    'activities', coalesce((
      select jsonb_agg(jsonb_build_object(
        'id', id,
        'type', type,
        'title', title,
        'timestamp', occurred_at
      ) order by occurred_at desc)
      from recent_activity
    ), '[]'::jsonb)
  ) into result;

  return result;
end;
$$;

revoke execute on function public.get_admin_dashboard(timestamptz)
from public, anon;
grant execute on function public.get_admin_dashboard(timestamptz)
to authenticated;
