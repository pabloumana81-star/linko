create or replace function public.notify_professional_availability_change()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if new.account_status is distinct from old.account_status then
    update public.professional_profiles
    set updated_at = now()
    where id = new.id;
  end if;
  return new;
end;
$$;

drop trigger if exists profiles_notify_professional_availability
on public.profiles;
create trigger profiles_notify_professional_availability
after update of account_status on public.profiles
for each row execute function public.notify_professional_availability_change();

revoke execute on function public.notify_professional_availability_change()
from public, anon, authenticated;
