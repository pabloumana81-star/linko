alter table public.service_requests
add column if not exists location text;

create or replace function public.protect_service_request_fields()
returns trigger
language plpgsql
security invoker
set search_path = ''
as $$
begin
  if new.id <> old.id
    or new.customer_id <> old.customer_id
    or new.professional_id <> old.professional_id
    or new.service_category <> old.service_category
    or new.title <> old.title
    or new.description <> old.description
    or new.location is distinct from old.location then
    raise exception 'Solo se pueden actualizar el estado y la programación.';
  end if;
  new.created_at = old.created_at;
  new.updated_at = now();
  return new;
end;
$$;
