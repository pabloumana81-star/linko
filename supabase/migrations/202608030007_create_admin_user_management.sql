alter table public.profiles
add column if not exists account_status text not null default 'active'
check (account_status in ('active', 'suspended'));

alter table public.profiles
add column if not exists onboarding_completed boolean not null default true;

create table if not exists public.admin_audit_log (
  id uuid primary key default gen_random_uuid(),
  admin_id uuid not null references public.profiles(id) on delete restrict,
  user_id uuid not null references public.profiles(id) on delete restrict,
  action text not null check (action in (
    'accountSuspended',
    'accountReactivated',
    'onboardingReset'
  )),
  created_at timestamptz not null default now()
);

create index if not exists admin_audit_user_created_idx
on public.admin_audit_log (user_id, created_at desc);

alter table public.admin_audit_log enable row level security;

create policy "Admins can read audit log"
on public.admin_audit_log for select to authenticated
using (exists (
  select 1 from public.profiles profile
  where profile.id = (select auth.uid()) and profile.role = 'admin'
));

create or replace function public.list_admin_users(
  p_search text default '',
  p_status text default null,
  p_account_type text default null
)
returns table (
  id uuid,
  name text,
  email text,
  avatar_url text,
  account_type text,
  status text,
  registered_at timestamptz,
  last_login_at timestamptz
)
language plpgsql
security definer
set search_path = ''
as $$
begin
  if not exists (
    select 1 from public.profiles profile
    where profile.id = (select auth.uid()) and profile.role = 'admin'
  ) then raise exception 'No tienes permisos de administrador.'; end if;

  return query
  select
    profile.id,
    profile.display_name,
    profile.email,
    profile.avatar_url,
    case
      when profile.role = 'admin' then 'admin'
      when professional.id is not null then 'professional'
      else 'customer'
    end,
    profile.account_status,
    profile.created_at,
    auth_user.last_sign_in_at
  from public.profiles profile
  left join public.professional_profiles professional on professional.id = profile.id
  left join auth.users auth_user on auth_user.id = profile.id
  where (
    coalesce(trim(p_search), '') = ''
    or profile.display_name ilike '%' || trim(p_search) || '%'
    or coalesce(profile.email, '') ilike '%' || trim(p_search) || '%'
    or profile.id::text ilike '%' || trim(p_search) || '%'
  )
  and (p_status is null or profile.account_status = p_status)
  and (
    p_account_type is null
    or case
      when profile.role = 'admin' then 'admin'
      when professional.id is not null then 'professional'
      else 'customer'
    end = p_account_type
  )
  order by profile.created_at desc;
end;
$$;

create or replace function public.get_admin_user_detail(p_user_id uuid)
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
  ) then raise exception 'No tienes permisos de administrador.'; end if;
  if not exists (
    select 1 from public.profiles target where target.id = p_user_id
  ) then
    return null;
  end if;

  select jsonb_build_object(
    'user', jsonb_build_object(
      'id', profile.id,
      'name', profile.display_name,
      'email', profile.email,
      'avatar_url', profile.avatar_url,
      'account_type', case
        when profile.role = 'admin' then 'admin'
        when professional.id is not null then 'professional'
        else 'customer'
      end,
      'status', profile.account_status,
      'registered_at', profile.created_at,
      'last_login_at', auth_user.last_sign_in_at
    ),
    'active_requests', (
      select count(*) from public.service_requests request
      where p_user_id in (request.customer_id, request.professional_id)
        and request.status not in ('completed', 'reviewed', 'cancelled')
    ),
    'completed_requests', (
      select count(*) from public.service_requests request
      where p_user_id in (request.customer_id, request.professional_id)
        and request.status in ('completed', 'reviewed')
    ),
    'ratings', (
      select count(*) from public.ratings rating
      where p_user_id in (rating.customer_id, rating.professional_id)
    ),
    'reports', (
      select count(*) from public.reports report
      where report.reporter_id = p_user_id
    ),
    'onboarding_completed', profile.onboarding_completed,
    'history', coalesce((
      select jsonb_agg(jsonb_build_object(
        'id', audit.id,
        'admin_id', audit.admin_id,
        'user_id', audit.user_id,
        'action', audit.action,
        'timestamp', audit.created_at
      ) order by audit.created_at desc)
      from public.admin_audit_log audit where audit.user_id = p_user_id
    ), '[]'::jsonb)
  ) into result
  from public.profiles profile
  left join public.professional_profiles professional on professional.id = profile.id
  left join auth.users auth_user on auth_user.id = profile.id
  where profile.id = p_user_id;

  return result;
end;
$$;

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

  insert into public.admin_audit_log (admin_id, user_id, action)
  values (actor, p_user_id, p_action);
end;
$$;

revoke execute on function public.list_admin_users(text, text, text)
from public, anon;
revoke execute on function public.get_admin_user_detail(uuid)
from public, anon;
revoke execute on function public.perform_admin_user_action(uuid, text)
from public, anon;
grant execute on function public.list_admin_users(text, text, text)
to authenticated;
grant execute on function public.get_admin_user_detail(uuid)
to authenticated;
grant execute on function public.perform_admin_user_action(uuid, text)
to authenticated;
