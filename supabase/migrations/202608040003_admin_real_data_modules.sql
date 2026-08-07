create or replace function public.list_admin_requests()
returns table (
  id uuid,
  title text,
  category text,
  status text,
  customer_name text,
  professional_name text,
  created_at timestamptz,
  updated_at timestamptz
)
language plpgsql
security definer
set search_path = ''
stable
as $$
begin
  if not exists (
    select 1 from public.profiles profile
    where profile.id = (select auth.uid()) and profile.role = 'admin'
  ) then raise exception 'No tienes permisos de administrador.'; end if;

  return query
  select request.id, request.title, request.service_category, request.status,
    customer.display_name, professional.display_name,
    request.created_at, request.updated_at
  from public.service_requests request
  join public.profiles customer on customer.id = request.customer_id
  join public.profiles professional on professional.id = request.professional_id
  order by request.updated_at desc;
end;
$$;

create or replace function public.list_admin_reports()
returns table (
  id uuid,
  reporter_name text,
  request_title text,
  reason text,
  status text,
  created_at timestamptz
)
language plpgsql
security definer
set search_path = ''
stable
as $$
begin
  if not exists (
    select 1 from public.profiles profile
    where profile.id = (select auth.uid()) and profile.role = 'admin'
  ) then raise exception 'No tienes permisos de administrador.'; end if;

  return query
  select report.id, reporter.display_name, request.title,
    report.reason, report.status, report.created_at
  from public.reports report
  join public.profiles reporter on reporter.id = report.reporter_id
  left join public.service_requests request on request.id = report.request_id
  order by report.created_at desc;
end;
$$;

revoke execute on function public.list_admin_requests() from public, anon;
revoke execute on function public.list_admin_reports() from public, anon;
grant execute on function public.list_admin_requests() to authenticated;
grant execute on function public.list_admin_reports() to authenticated;
