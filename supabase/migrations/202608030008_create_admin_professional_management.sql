alter table public.professional_profiles
add column if not exists verification_status text not null default 'pending'
check (verification_status in ('pending', 'verified', 'rejected'));

alter table public.professional_profiles
add column if not exists skills text[] not null default '{}';

alter table public.professional_profiles
add column if not exists portfolio jsonb not null default '[]'::jsonb;

create table if not exists public.admin_professional_audit_log (
  id uuid primary key default gen_random_uuid(),
  admin_id uuid not null references public.profiles(id) on delete restrict,
  professional_id uuid not null
    references public.professional_profiles(id) on delete restrict,
  action text not null check (action in (
    'verificationApproved', 'verificationRejected',
    'accountSuspended', 'accountReactivated'
  )),
  previous_value text not null,
  new_value text not null,
  created_at timestamptz not null default now()
);

alter table public.admin_professional_audit_log enable row level security;
create policy "Admins can read professional audit log"
on public.admin_professional_audit_log for select to authenticated
using (exists (
  select 1 from public.profiles profile
  where profile.id = (select auth.uid()) and profile.role = 'admin'
));

create or replace function public.list_admin_professionals(
  p_search text default '',
  p_verification text default null,
  p_account_status text default null,
  p_rating_filter text default null
)
returns table (
  id uuid, name text, email text, photo_url text,
  verification text, average_rating double precision,
  completed_jobs bigint, active_jobs bigint,
  registered_at timestamptz, account_status text
)
language plpgsql security definer set search_path = '' as $$
begin
  if not exists (
    select 1 from public.profiles profile
    where profile.id = (select auth.uid()) and profile.role = 'admin'
  ) then raise exception 'No tienes permisos de administrador.'; end if;
  return query
  select professional.id, professional.display_name, profile.email,
    profile.avatar_url, professional.verification_status,
    professional.rating::double precision,
    (select count(*) from public.service_requests request
      where request.professional_id = professional.id
        and request.status in ('completed', 'reviewed')),
    (select count(*) from public.service_requests request
      where request.professional_id = professional.id
        and request.status not in ('completed', 'reviewed', 'cancelled')),
    professional.created_at, profile.account_status
  from public.professional_profiles professional
  join public.profiles profile on profile.id = professional.id
  where (coalesce(trim(p_search), '') = ''
    or professional.display_name ilike '%' || trim(p_search) || '%'
    or coalesce(profile.email, '') ilike '%' || trim(p_search) || '%'
    or professional.id::text ilike '%' || trim(p_search) || '%')
    and (p_verification is null
      or professional.verification_status = p_verification)
    and (p_account_status is null
      or profile.account_status = p_account_status)
    and (p_rating_filter is null
      or (p_rating_filter = 'topRated' and professional.rating >= 4.8)
      or (p_rating_filter = 'lowRated' and professional.rating < 4.8))
  order by professional.created_at desc;
end;
$$;

create or replace function public.get_admin_professional_detail(
  p_professional_id uuid
)
returns jsonb language plpgsql security definer set search_path = '' as $$
declare result jsonb;
begin
  if not exists (
    select 1 from public.profiles profile
    where profile.id = (select auth.uid()) and profile.role = 'admin'
  ) then raise exception 'No tienes permisos de administrador.'; end if;
  if not exists (
    select 1 from public.professional_profiles professional
    where professional.id = p_professional_id
  ) then return null; end if;

  select jsonb_build_object(
    'professional', jsonb_build_object(
      'id', professional.id, 'name', professional.display_name,
      'email', profile.email, 'photo_url', profile.avatar_url,
      'verification', professional.verification_status,
      'average_rating', professional.rating,
      'completed_jobs', (select count(*) from public.service_requests request
        where request.professional_id = professional.id
          and request.status in ('completed', 'reviewed')),
      'active_jobs', (select count(*) from public.service_requests request
        where request.professional_id = professional.id
          and request.status not in ('completed', 'reviewed', 'cancelled')),
      'registered_at', professional.created_at,
      'account_status', profile.account_status
    ),
    'profession', professional.profession,
    'location', professional.location,
    'skills', to_jsonb(professional.skills),
    'portfolio', professional.portfolio,
    'review_count', professional.review_count,
    'reviews', coalesce((select jsonb_agg(rating.comment)
      from public.ratings rating where rating.professional_id = professional.id
        and rating.comment is not null), '[]'::jsonb),
    'cancelled_jobs', (select count(*) from public.service_requests request
      where request.professional_id = professional.id
        and request.status = 'cancelled'),
    'current_requests', coalesce((select jsonb_agg(request.title)
      from public.service_requests request
      where request.professional_id = professional.id
        and request.status not in ('completed', 'reviewed', 'cancelled')),
      '[]'::jsonb),
    'conversation_count', (select count(*) from public.conversations conversation
      join public.service_requests request
        on request.id = conversation.service_request_id
      where request.professional_id = professional.id),
    'timeline', coalesce((select jsonb_agg(jsonb_build_object(
      'id', audit.id, 'admin_id', audit.admin_id,
      'professional_id', audit.professional_id, 'action', audit.action,
      'previous_value', audit.previous_value, 'new_value', audit.new_value,
      'timestamp', audit.created_at) order by audit.created_at desc)
      from public.admin_professional_audit_log audit
      where audit.professional_id = professional.id), '[]'::jsonb)
  ) into result
  from public.professional_profiles professional
  join public.profiles profile on profile.id = professional.id
  where professional.id = p_professional_id;
  return result;
end;
$$;

create or replace function public.perform_admin_professional_action(
  p_professional_id uuid, p_action text
)
returns void language plpgsql security definer set search_path = '' as $$
declare actor uuid := (select auth.uid()); previous text; next text;
begin
  if not exists (select 1 from public.profiles profile
    where profile.id = actor and profile.role = 'admin') then
    raise exception 'No tienes permisos de administrador.';
  end if;
  if p_action in ('verificationApproved', 'verificationRejected') then
    select verification_status into previous
    from public.professional_profiles where id = p_professional_id for update;
    next := case when p_action = 'verificationApproved'
      then 'verified' else 'rejected' end;
    update public.professional_profiles set verification_status = next
    where id = p_professional_id and verification_status <> next;
  elsif p_action in ('accountSuspended', 'accountReactivated') then
    select account_status into previous from public.profiles
    where id = p_professional_id for update;
    next := case when p_action = 'accountSuspended'
      then 'suspended' else 'active' end;
    update public.profiles set account_status = next
    where id = p_professional_id and account_status <> next;
  else raise exception 'Acción administrativa inválida.';
  end if;
  if not found then raise exception 'La cuenta ya tiene ese estado.'; end if;
  insert into public.admin_professional_audit_log (
    admin_id, professional_id, action, previous_value, new_value
  ) values (actor, p_professional_id, p_action, previous, next);
end;
$$;

create or replace function public.count_active_admin_professionals()
returns integer language plpgsql security definer set search_path = '' as $$
begin
  if not exists (select 1 from public.profiles profile
    where profile.id = (select auth.uid()) and profile.role = 'admin') then
    raise exception 'No tienes permisos de administrador.';
  end if;
  return (select count(*)::integer
    from public.professional_profiles professional
    join public.profiles profile on profile.id = professional.id
    where professional.verification_status = 'verified'
      and profile.account_status = 'active');
end;
$$;

revoke execute on function public.list_admin_professionals(text,text,text,text)
from public, anon;
revoke execute on function public.get_admin_professional_detail(uuid)
from public, anon;
revoke execute on function public.perform_admin_professional_action(uuid,text)
from public, anon;
revoke execute on function public.count_active_admin_professionals()
from public, anon;
grant execute on function public.list_admin_professionals(text,text,text,text),
  public.get_admin_professional_detail(uuid),
  public.perform_admin_professional_action(uuid,text),
  public.count_active_admin_professionals() to authenticated;
