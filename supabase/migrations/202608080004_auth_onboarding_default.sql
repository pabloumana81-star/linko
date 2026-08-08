-- Existing accounts keep their current onboarding state. Only profiles created
-- after this migration must select a LinkO mode before entering the product.
alter table public.profiles
alter column onboarding_completed set default false;
