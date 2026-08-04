-- Use the production table name while retaining a read-compatible legacy view.
do $$
begin
  if to_regclass('public.admin_audit_logs') is null
     and to_regclass('public.admin_audit_log') is not null then
    alter table public.admin_audit_log rename to admin_audit_logs;
  end if;
end $$;

create or replace view public.admin_audit_log
with (security_invoker = true)
as select * from public.admin_audit_logs;

create or replace function public.perform_admin_user_action(
  p_user_id uuid,
  p_action text
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  actor uuid := (select auth.uid());
begin
  if not exists (
    select 1 from public.profiles profile
    where profile.id = actor and profile.role = 'admin'
  ) then raise exception 'No tienes permisos de administrador.'; end if;
  if actor = p_user_id and p_action = 'accountSuspended' then
    raise exception 'No puedes suspender tu propia cuenta.';
  end if;

  if p_action = 'accountSuspended' then
    update public.profiles set account_status = 'suspended'
    where id = p_user_id and account_status = 'active';
  elsif p_action = 'accountReactivated' then
    update public.profiles set account_status = 'active'
    where id = p_user_id and account_status = 'suspended';
  elsif p_action = 'onboardingReset' then
    update public.profiles set onboarding_completed = false
    where id = p_user_id;
  else
    raise exception 'Acción administrativa inválida.';
  end if;
  if not found then raise exception 'La cuenta ya tiene ese estado.'; end if;

  insert into public.admin_audit_logs (admin_id, user_id, action)
  values (actor, p_user_id, p_action);
end;
$$;

revoke execute on function public.perform_admin_user_action(uuid, text)
from public, anon;
grant execute on function public.perform_admin_user_action(uuid, text)
to authenticated;
