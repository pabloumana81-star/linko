alter table public.professional_profiles
add column if not exists categories text[] not null default '{}';

alter table public.professional_profiles
add column if not exists coverage_area text not null default '';

alter table public.professional_profiles
add column if not exists experience_years integer not null default 0
check (experience_years >= 0);

alter table public.professional_profiles
add column if not exists verification_documents jsonb not null default '[]'::jsonb;

alter table public.admin_professional_audit_log
add column if not exists reason text;

alter table public.admin_professional_audit_log
drop constraint if exists admin_professional_audit_log_action_check;
alter table public.admin_professional_audit_log
add constraint admin_professional_audit_log_action_check check (action in (
  'verificationApproved', 'verificationRejected',
  'additionalInformationRequested',
  'accountSuspended', 'accountReactivated'
));

alter table public.admin_audit_logs
drop constraint if exists admin_audit_log_action_check;
alter table public.admin_audit_logs
add constraint admin_audit_logs_action_check check (action in (
  'accountSuspended', 'accountReactivated', 'onboardingReset',
  'verificationApproved', 'verificationRejected',
  'additionalInformationRequested'
));

drop function if exists public.list_admin_professionals(text,text,text,text);
create function public.list_admin_professionals(
  p_search text default '',
  p_verification text default null,
  p_account_status text default null,
  p_rating_filter text default null
)
returns table (
  id uuid, name text, email text, photo_url text, categories text[],
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
    profile.avatar_url,
    case when cardinality(professional.categories) > 0
      then professional.categories
      when cardinality(professional.skills) > 0 then professional.skills
      else array[professional.profession] end,
    professional.verification_status,
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
  order by case when p_rating_filter = 'topRated' then professional.rating end desc,
    case when p_rating_filter = 'lowRated' then professional.rating end asc,
    professional.created_at desc;
end;
$$;

create or replace function public.get_admin_professional_detail(
  p_professional_id uuid
)
returns jsonb language plpgsql security definer set search_path = '' as $$
declare result jsonb;
begin
  if not exists (select 1 from public.profiles profile
    where profile.id = (select auth.uid()) and profile.role = 'admin') then
    raise exception 'No tienes permisos de administrador.';
  end if;
  if not exists (select 1 from public.professional_profiles professional
    where professional.id = p_professional_id) then return null; end if;

  select jsonb_build_object(
    'professional', jsonb_build_object(
      'id', professional.id, 'name', professional.display_name,
      'email', profile.email, 'photo_url', profile.avatar_url,
      'categories', case when cardinality(professional.categories) > 0
        then professional.categories else professional.skills end,
      'verification', professional.verification_status,
      'average_rating', professional.rating,
      'completed_jobs', (select count(*) from public.service_requests request
        where request.professional_id = professional.id
          and request.status in ('completed', 'reviewed')),
      'active_jobs', (select count(*) from public.service_requests request
        where request.professional_id = professional.id
          and request.status not in ('completed', 'reviewed', 'cancelled')),
      'registered_at', professional.created_at,
      'account_status', profile.account_status),
    'profession', professional.profession,
    'location', professional.location,
    'coverage_area', professional.coverage_area,
    'experience_years', professional.experience_years,
    'skills', to_jsonb(professional.skills),
    'portfolio', professional.portfolio,
    'verification_documents', professional.verification_documents,
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
      'reason', audit.reason, 'timestamp', audit.created_at)
      order by audit.created_at desc)
      from public.admin_professional_audit_log audit
      where audit.professional_id = professional.id), '[]'::jsonb)
  ) into result
  from public.professional_profiles professional
  join public.profiles profile on profile.id = professional.id
  where professional.id = p_professional_id;
  return result;
end;
$$;

drop function if exists public.perform_admin_professional_action(uuid,text);
create or replace function public.perform_admin_professional_action(
  p_professional_id uuid, p_action text, p_reason text default null
)
returns void language plpgsql security definer set search_path = '' as $$
declare actor uuid := (select auth.uid()); previous text; next text;
begin
  if not exists (select 1 from public.profiles profile
    where profile.id = actor and profile.role = 'admin') then
    raise exception 'No tienes permisos de administrador.';
  end if;
  if p_action in ('verificationRejected', 'additionalInformationRequested')
     and coalesce(trim(p_reason), '') = '' then
    raise exception 'Debes indicar un motivo.';
  end if;

  if p_action in ('verificationApproved', 'verificationRejected',
                   'additionalInformationRequested') then
    select verification_status into previous
    from public.professional_profiles where id = p_professional_id for update;
    next := case
      when p_action = 'verificationApproved' then 'verified'
      when p_action = 'verificationRejected' then 'rejected'
      else 'pending' end;
    update public.professional_profiles set
      verification_status = next, updated_at = now()
    where id = p_professional_id
      and (verification_status <> next
        or p_action = 'additionalInformationRequested');
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
    admin_id, professional_id, action, previous_value, new_value, reason
  ) values (actor, p_professional_id, p_action, previous, next, trim(p_reason));
  insert into public.admin_audit_logs (admin_id, user_id, action)
  values (actor, p_professional_id, p_action);
end;
$$;

revoke execute on function public.list_admin_professionals(text,text,text,text)
from public, anon;
revoke execute on function public.get_admin_professional_detail(uuid)
from public, anon;
revoke execute on function public.perform_admin_professional_action(uuid,text,text)
from public, anon;
grant execute on function public.list_admin_professionals(text,text,text,text),
  public.get_admin_professional_detail(uuid),
  public.perform_admin_professional_action(uuid,text,text) to authenticated;
