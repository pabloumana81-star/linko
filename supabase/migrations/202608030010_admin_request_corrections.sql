create table if not exists public.admin_request_audit_log (
  id uuid primary key default gen_random_uuid(),
  admin_id uuid not null references public.profiles(id) on delete restrict,
  request_id uuid not null references public.service_requests(id) on delete cascade,
  previous_status text not null,
  new_status text not null,
  created_at timestamptz not null default now()
);

alter table public.admin_request_audit_log enable row level security;
create policy "Admins can read request correction audit"
on public.admin_request_audit_log for select to authenticated
using (exists (
  select 1 from public.profiles profile
  where profile.id = (select auth.uid()) and profile.role = 'admin'
));

create or replace function public.correct_admin_request_status(
  p_request_id uuid,
  p_new_status text
)
returns void language plpgsql security definer set search_path = '' as $$
declare actor uuid := (select auth.uid()); previous text;
begin
  if not exists (select 1 from public.profiles profile
    where profile.id = actor and profile.role = 'admin') then
    raise exception 'No tienes permisos de administrador.';
  end if;
  if p_new_status not in ('pending', 'under_review', 'quoted', 'accepted',
    'scheduled', 'in_progress', 'pending_customer_confirmation', 'completed',
    'reviewed', 'cancelled') then
    raise exception 'Estado de solicitud inválido.';
  end if;
  select status into previous from public.service_requests
  where id = p_request_id for update;
  if previous is null then raise exception 'Solicitud no encontrada.'; end if;
  if previous = p_new_status then return; end if;
  update public.service_requests set status = p_new_status
  where id = p_request_id;
  insert into public.admin_request_audit_log (
    admin_id, request_id, previous_status, new_status
  ) values (actor, p_request_id, previous, p_new_status);
end;
$$;

revoke execute on function public.correct_admin_request_status(uuid,text)
from public, anon;
grant execute on function public.correct_admin_request_status(uuid,text)
to authenticated;
