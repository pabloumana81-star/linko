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

revoke execute on function public.update_own_professional_profile(
  text, text, text, text[], integer, text, text
) from public, anon;
grant execute on function public.update_own_professional_profile(
  text, text, text, text[], integer, text, text
) to authenticated;
