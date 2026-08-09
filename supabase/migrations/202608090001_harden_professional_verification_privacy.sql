create table if not exists public.professional_verification_submissions (
  professional_id uuid primary key
    references public.professional_profiles(id) on delete cascade,
  documents jsonb not null default '[]'::jsonb
    check (jsonb_typeof(documents) = 'array'),
  submission_metadata jsonb not null default '{}'::jsonb
    check (jsonb_typeof(submission_metadata) = 'object'),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.professional_verification_submissions enable row level security;

revoke all on table public.professional_verification_submissions
from public, anon, authenticated;
grant select, insert on table public.professional_verification_submissions
to authenticated;
grant update (documents, submission_metadata)
on table public.professional_verification_submissions to authenticated;

drop policy if exists "Owners can read verification submissions"
on public.professional_verification_submissions;
create policy "Owners can read verification submissions"
on public.professional_verification_submissions for select to authenticated
using ((select auth.uid()) = professional_id);

drop policy if exists "Admins can read verification submissions"
on public.professional_verification_submissions;
create policy "Admins can read verification submissions"
on public.professional_verification_submissions for select to authenticated
using (exists (
  select 1 from public.profiles profile
  where profile.id = (select auth.uid()) and profile.role = 'admin'
));

drop policy if exists "Owners can submit verification material"
on public.professional_verification_submissions;
create policy "Owners can submit verification material"
on public.professional_verification_submissions for insert to authenticated
with check ((select auth.uid()) = professional_id);

drop policy if exists "Owners can update verification material"
on public.professional_verification_submissions;
create policy "Owners can update verification material"
on public.professional_verification_submissions for update to authenticated
using ((select auth.uid()) = professional_id)
with check ((select auth.uid()) = professional_id);

drop trigger if exists professional_verification_set_updated_at
on public.professional_verification_submissions;
create trigger professional_verification_set_updated_at
before update on public.professional_verification_submissions
for each row execute function public.set_updated_at();

insert into public.professional_verification_submissions (
  professional_id, documents
)
select professional.id, professional.verification_documents
from public.professional_profiles professional
on conflict (professional_id) do update set
  documents = excluded.documents;

do $$
declare
  source_count bigint;
  destination_count bigint;
begin
  select count(*) into source_count from public.professional_profiles;
  select count(*) into destination_count
  from public.professional_verification_submissions;
  if source_count <> destination_count then
    raise exception 'La migración no preservó todas las verificaciones profesionales.';
  end if;
  if exists (
    select 1
    from public.professional_profiles professional
    join public.professional_verification_submissions submission
      on submission.professional_id = professional.id
    where submission.documents is distinct from professional.verification_documents
  ) then
    raise exception 'La migración alteró documentos de verificación.';
  end if;
end
$$;

create or replace function public.get_own_professional_verification()
returns jsonb
language sql
security invoker
set search_path = ''
stable
as $$
  select jsonb_build_object(
    'documents', submission.documents,
    'submission_metadata', submission.submission_metadata,
    'updated_at', submission.updated_at
  )
  from public.professional_verification_submissions submission
  where submission.professional_id = (select auth.uid());
$$;

create or replace function public.submit_own_professional_verification(
  p_documents jsonb,
  p_submission_metadata jsonb default '{}'::jsonb
)
returns void
language plpgsql
security invoker
set search_path = ''
as $$
begin
  if jsonb_typeof(coalesce(p_documents, '[]'::jsonb)) <> 'array' then
    raise exception 'Los documentos de verificación no son válidos.';
  end if;
  if jsonb_typeof(coalesce(p_submission_metadata, '{}'::jsonb)) <> 'object' then
    raise exception 'Los metadatos de verificación no son válidos.';
  end if;
  if not exists (
    select 1 from public.professional_profiles professional
    where professional.id = (select auth.uid())
  ) then
    raise exception 'No existe un perfil profesional para esta cuenta.';
  end if;
  insert into public.professional_verification_submissions (
    professional_id, documents, submission_metadata
  ) values (
    (select auth.uid()), coalesce(p_documents, '[]'::jsonb),
    coalesce(p_submission_metadata, '{}'::jsonb)
  )
  on conflict (professional_id) do update set
    documents = excluded.documents,
    submission_metadata = excluded.submission_metadata;
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
    'verification_documents', coalesce(submission.documents, '[]'::jsonb),
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
  left join public.professional_verification_submissions submission
    on submission.professional_id = professional.id
  where professional.id = p_professional_id;
  return result;
end;
$$;

revoke execute on function public.get_own_professional_verification()
from public, anon;
revoke execute on function public.submit_own_professional_verification(jsonb, jsonb)
from public, anon;
revoke execute on function public.get_admin_professional_detail(uuid)
from public, anon;
grant execute on function public.get_own_professional_verification(),
  public.submit_own_professional_verification(jsonb, jsonb),
  public.get_admin_professional_detail(uuid) to authenticated;

alter table public.professional_profiles
drop column verification_documents;

create index if not exists professional_verification_updated_at_idx
on public.professional_verification_submissions(updated_at desc);
