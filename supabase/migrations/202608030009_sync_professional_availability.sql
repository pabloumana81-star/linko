create or replace function public.list_available_professionals()
returns table (
  id uuid,
  display_name text,
  profession text,
  rating numeric,
  review_count integer,
  location text
)
language sql
security definer
set search_path = ''
stable
as $$
  select
    professional.id,
    professional.display_name,
    professional.profession,
    professional.rating,
    professional.review_count,
    professional.location
  from public.professional_profiles professional
  join public.profiles profile on profile.id = professional.id
  where professional.verification_status = 'verified'
    and profile.account_status = 'active'
  order by professional.display_name;
$$;

revoke execute on function public.list_available_professionals()
from public, anon;
grant execute on function public.list_available_professionals()
to authenticated;

do $$
begin
  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public'
      and tablename = 'profiles'
  ) then
    alter publication supabase_realtime add table public.profiles;
  end if;
  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public'
      and tablename = 'professional_profiles'
  ) then
    alter publication supabase_realtime add table public.professional_profiles;
  end if;
end
$$;
