-- Profiles are owner-scoped by the existing RLS update policy. The column was
-- added after authenticated profile update privileges were narrowed, so include
-- it in that existing column-level grant without broadening row access.
grant update (onboarding_completed) on public.profiles to authenticated;
