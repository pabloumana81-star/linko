alter table public.professional_profiles
add column if not exists biography text not null default '';

alter table public.professional_profiles
add column if not exists experience_description text not null default '';

drop function if exists public.list_available_professionals();
create function public.list_available_professionals()
returns table (
  id uuid,
  display_name text,
  avatar_url text,
  profession text,
  rating double precision,
  review_count integer,
  location text,
  biography text,
  services text[],
  experience_years integer,
  experience_description text,
  portfolio jsonb,
  completed_jobs_count bigint,
  reviews jsonb,
  coverage_area text,
  verification_status text
)
language sql
security definer
set search_path = ''
stable
as $$
  select
    professional.id,
    professional.display_name,
    profile.avatar_url,
    professional.profession,
    coalesce((select avg(rating.stars)::double precision
      from public.ratings rating
      where rating.professional_id = professional.id), 0),
    (select count(*)::integer from public.ratings rating
      where rating.professional_id = professional.id),
    professional.location,
    professional.biography,
    case
      when cardinality(professional.categories) > 0 then professional.categories
      when cardinality(professional.skills) > 0 then professional.skills
      else array[professional.profession]
    end,
    professional.experience_years,
    professional.experience_description,
    professional.portfolio,
    (select count(*) from public.service_requests request
      where request.professional_id = professional.id
        and request.status in ('completed', 'reviewed')),
    coalesce((select jsonb_agg(jsonb_build_object(
        'stars', rating.stars,
        'comment', rating.comment,
        'created_at', rating.created_at
      ) order by rating.created_at desc)
      from public.ratings rating
      where rating.professional_id = professional.id), '[]'::jsonb),
    professional.coverage_area,
    professional.verification_status
  from public.professional_profiles professional
  join public.profiles profile on profile.id = professional.id
  where professional.verification_status = 'verified'
    and profile.account_status = 'active'
  order by professional.display_name;
$$;

create or replace function public.get_own_professional_profile()
returns jsonb
language sql
security definer
set search_path = ''
stable
as $$
  select jsonb_build_object(
    'id', professional.id,
    'display_name', professional.display_name,
    'avatar_url', profile.avatar_url,
    'profession', professional.profession,
    'rating', coalesce((select avg(rating.stars)::double precision
      from public.ratings rating where rating.professional_id = professional.id), 0),
    'review_count', (select count(*)::integer from public.ratings rating
      where rating.professional_id = professional.id),
    'location', professional.location,
    'biography', professional.biography,
    'services', case
      when cardinality(professional.categories) > 0 then professional.categories
      when cardinality(professional.skills) > 0 then professional.skills
      else array[professional.profession] end,
    'experience_years', professional.experience_years,
    'experience_description', professional.experience_description,
    'portfolio', professional.portfolio,
    'completed_jobs_count', (select count(*) from public.service_requests request
      where request.professional_id = professional.id
        and request.status in ('completed', 'reviewed')),
    'reviews', coalesce((select jsonb_agg(jsonb_build_object(
      'stars', rating.stars, 'comment', rating.comment,
      'created_at', rating.created_at) order by rating.created_at desc)
      from public.ratings rating where rating.professional_id = professional.id), '[]'::jsonb),
    'coverage_area', professional.coverage_area,
    'verification_status', professional.verification_status
  )
  from public.professional_profiles professional
  join public.profiles profile on profile.id = professional.id
  where professional.id = (select auth.uid());
$$;

create or replace function public.update_own_professional_profile(
  p_profession text,
  p_location text,
  p_biography text,
  p_services text[],
  p_experience_years integer,
  p_experience_description text,
  p_coverage_area text
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  actor uuid := (select auth.uid());
  actor_name text;
begin
  select profile.display_name into actor_name
  from public.profiles profile
  where profile.id = actor and profile.active_mode = 'professional';
  if actor_name is null then
    raise exception 'Solo un profesional autenticado puede editar este perfil.';
  end if;
  if coalesce(length(trim(p_profession)), 0) = 0 then
    raise exception 'La profesión es obligatoria.';
  end if;
  if p_experience_years < 0 or p_experience_years > 80 then
    raise exception 'Los años de experiencia no son válidos.';
  end if;
  if cardinality(coalesce(p_services, '{}')) > 20 then
    raise exception 'Puedes registrar hasta 20 servicios.';
  end if;

  insert into public.professional_profiles (
    id, display_name, profession, location, biography, categories,
    experience_years, experience_description, coverage_area
  ) values (
    actor, actor_name, trim(p_profession), trim(coalesce(p_location, '')),
    trim(coalesce(p_biography, '')), coalesce(p_services, '{}'),
    p_experience_years, trim(coalesce(p_experience_description, '')),
    trim(coalesce(p_coverage_area, ''))
  )
  on conflict (id) do update set
    display_name = excluded.display_name,
    profession = excluded.profession,
    location = excluded.location,
    biography = excluded.biography,
    categories = excluded.categories,
    experience_years = excluded.experience_years,
    experience_description = excluded.experience_description,
    coverage_area = excluded.coverage_area,
    updated_at = now();
end;
$$;

revoke execute on function public.list_available_professionals() from public, anon;
revoke execute on function public.get_own_professional_profile() from public, anon;
revoke execute on function public.update_own_professional_profile(
  text, text, text, text[], integer, text, text
) from public, anon;
grant execute on function public.list_available_professionals(),
  public.get_own_professional_profile(),
  public.update_own_professional_profile(text, text, text, text[], integer, text, text)
to authenticated;
