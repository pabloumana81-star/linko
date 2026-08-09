alter table public.reports drop constraint if exists reports_status_check;
alter table public.reports add constraint reports_status_check
check (status in ('open', 'in_review', 'escalated', 'resolved', 'dismissed'));

create table if not exists public.admin_report_audit_log (
  id uuid primary key default gen_random_uuid(),
  admin_id uuid not null references public.profiles(id) on delete restrict,
  report_id uuid not null references public.reports(id) on delete restrict,
  action text not null check (action in ('resolved', 'dismissed', 'escalated')),
  previous_status text not null,
  new_status text not null,
  note text not null check (length(trim(note)) > 0),
  created_at timestamptz not null default now()
);
alter table public.admin_report_audit_log enable row level security;
drop policy if exists "Admins can read report operations audit"
on public.admin_report_audit_log;
create policy "Admins can read report operations audit"
on public.admin_report_audit_log for select to authenticated
using (exists (select 1 from public.profiles profile
  where profile.id = (select auth.uid()) and profile.role = 'admin'));
revoke all on public.admin_report_audit_log from public, anon, authenticated;
grant select on public.admin_report_audit_log to authenticated;
create index if not exists admin_report_audit_log_report_created_idx
on public.admin_report_audit_log(report_id, created_at desc);

create or replace function public.perform_admin_report_action(
  p_report_id uuid, p_action text, p_note text
)
returns void language plpgsql security definer set search_path = '' as $$
declare actor uuid := (select auth.uid()); previous text; next text;
begin
  if not exists (select 1 from public.profiles profile
    where profile.id = actor and profile.role = 'admin') then
    raise exception 'No tienes permisos de administrador.';
  end if;
  if coalesce(trim(p_note), '') = '' then
    raise exception 'Debes indicar una nota o motivo.';
  end if;
  select status into previous from public.reports
  where id = p_report_id for update;
  if previous is null then raise exception 'Reporte no encontrado.'; end if;
  next := case p_action
    when 'resolve' then 'resolved'
    when 'dismiss' then 'dismissed'
    when 'escalate' then 'escalated'
    else null end;
  if next is null then raise exception 'Acción de reporte inválida.'; end if;
  if previous in ('resolved', 'dismissed') then
    raise exception 'El reporte ya está cerrado.';
  end if;
  if previous = next then raise exception 'El reporte ya tiene ese estado.'; end if;
  update public.reports set status = next, updated_at = now()
  where id = p_report_id;
  insert into public.admin_report_audit_log (
    admin_id, report_id, action, previous_status, new_status, note
  ) values (actor, p_report_id, next, previous, next, trim(p_note));
end;
$$;

drop function if exists public.list_admin_reports();
create function public.list_admin_reports()
returns table (
  id uuid, reporter_name text, request_title text, reason text,
  status text, created_at timestamptz, updated_at timestamptz,
  audit_history jsonb
)
language plpgsql security definer set search_path = '' stable as $$
begin
  if not exists (select 1 from public.profiles profile
    where profile.id = (select auth.uid()) and profile.role = 'admin') then
    raise exception 'No tienes permisos de administrador.';
  end if;
  return query select report.id, reporter.display_name, request.title,
    report.reason, report.status, report.created_at, report.updated_at,
    coalesce((select jsonb_agg(jsonb_build_object(
      'id', audit.id, 'admin_id', audit.admin_id, 'action', audit.action,
      'previous_status', audit.previous_status, 'new_status', audit.new_status,
      'note', audit.note, 'created_at', audit.created_at)
      order by audit.created_at desc)
      from public.admin_report_audit_log audit
      where audit.report_id = report.id), '[]'::jsonb)
  from public.reports report
  join public.profiles reporter on reporter.id = report.reporter_id
  left join public.service_requests request on request.id = report.request_id
  order by report.updated_at desc;
end;
$$;

alter table public.service_requests
add column if not exists admin_review_flag boolean not null default false;
alter table public.admin_request_audit_log
add column if not exists action text not null default 'legacyStatusCorrection';
alter table public.admin_request_audit_log
add column if not exists note text not null default 'Corrección administrativa histórica';
create index if not exists admin_request_audit_log_request_created_idx
on public.admin_request_audit_log(request_id, created_at desc);

revoke execute on function public.correct_admin_request_status(uuid,text)
from public, anon, authenticated;

create or replace function public.perform_admin_request_action(
  p_request_id uuid, p_action text, p_note text
)
returns void language plpgsql security definer set search_path = '' as $$
declare actor uuid := (select auth.uid()); previous text; next text; flagged boolean;
begin
  if not exists (select 1 from public.profiles profile
    where profile.id = actor and profile.role = 'admin') then
    raise exception 'No tienes permisos de administrador.';
  end if;
  if coalesce(trim(p_note), '') = '' then
    raise exception 'Debes indicar una nota o motivo.';
  end if;
  select status, admin_review_flag into previous, flagged
  from public.service_requests where id = p_request_id for update;
  if previous is null then raise exception 'Solicitud no encontrada.'; end if;
  next := previous;
  if p_action = 'flagForReview' then
    if flagged then raise exception 'La solicitud ya está marcada para revisión.'; end if;
    if previous in ('completed', 'reviewed', 'cancelled') then
      raise exception 'No puedes marcar una solicitud archivada.';
    end if;
    update public.service_requests set admin_review_flag = true
    where id = p_request_id;
  elsif p_action = 'addInterventionNote' then
    null;
  elsif p_action = 'cancel' then
    if previous in ('pending_customer_confirmation', 'completed', 'reviewed', 'cancelled') then
      raise exception 'No puedes cancelar una solicitud finalizada.';
    end if;
    next := 'cancelled';
    update public.service_requests set status = next
    where id = p_request_id;
  else raise exception 'Acción de solicitud inválida.';
  end if;
  insert into public.admin_request_audit_log (
    admin_id, request_id, previous_status, new_status, action, note
  ) values (actor, p_request_id, previous, next, p_action, trim(p_note));
end;
$$;

drop function if exists public.list_admin_requests();
create function public.list_admin_requests()
returns table (
  id uuid, title text, category text, description text, status text,
  customer_name text, professional_name text, scheduled_at timestamptz,
  created_at timestamptz, updated_at timestamptz, admin_review_flag boolean,
  audit_history jsonb
)
language plpgsql security definer set search_path = '' stable as $$
begin
  if not exists (select 1 from public.profiles profile
    where profile.id = (select auth.uid()) and profile.role = 'admin') then
    raise exception 'No tienes permisos de administrador.';
  end if;
  return query select request.id, request.title, request.service_category,
    request.description, request.status, customer.display_name,
    professional.display_name, request.scheduled_at, request.created_at,
    request.updated_at, request.admin_review_flag,
    coalesce((select jsonb_agg(jsonb_build_object(
      'id', audit.id, 'admin_id', audit.admin_id, 'action', audit.action,
      'previous_status', audit.previous_status, 'new_status', audit.new_status,
      'note', audit.note, 'created_at', audit.created_at)
      order by audit.created_at desc)
      from public.admin_request_audit_log audit
      where audit.request_id = request.id), '[]'::jsonb)
  from public.service_requests request
  join public.profiles customer on customer.id = request.customer_id
  join public.profiles professional on professional.id = request.professional_id
  order by request.updated_at desc;
end;
$$;

revoke execute on function public.perform_admin_report_action(uuid,text,text),
  public.perform_admin_request_action(uuid,text,text),
  public.list_admin_reports(), public.list_admin_requests() from public, anon;
grant execute on function public.perform_admin_report_action(uuid,text,text),
  public.perform_admin_request_action(uuid,text,text),
  public.list_admin_reports(), public.list_admin_requests() to authenticated;
