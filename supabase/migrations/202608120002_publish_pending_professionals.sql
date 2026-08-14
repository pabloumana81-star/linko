create or replace function public.list_available_professionals()
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
  where professional.verification_status in ('pending', 'verified')
    and profile.account_status = 'active'
  order by professional.display_name;
$$;

revoke execute on function public.list_available_professionals()
from public, anon;
grant execute on function public.list_available_professionals()
to authenticated;
