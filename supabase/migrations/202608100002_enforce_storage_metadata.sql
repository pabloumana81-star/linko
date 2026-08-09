-- Prevent authenticated clients from fabricating Storage metadata through legacy
-- direct-table or bulk-RPC paths. Existing legacy values remain valid and unchanged.

create or replace function public.validate_professional_portfolio_storage()
returns trigger language plpgsql security definer set search_path = '' as $$
declare
  previous jsonb := case when tg_op = 'INSERT' then '[]'::jsonb else old.portfolio end;
  item jsonb;
  object_path text;
begin
  if new.portfolio is not distinct from previous then return new; end if;
  if jsonb_typeof(new.portfolio) <> 'array' then
    raise exception 'El portafolio no es válido.';
  end if;

  for item in select value from jsonb_array_elements(new.portfolio) loop
    if previous @> jsonb_build_array(item) then continue; end if;
    object_path := item->>'path';
    if jsonb_typeof(item) <> 'object' or object_path is null
        or object_path not like new.id::text || '/%'
        or not exists (
          select 1 from storage.objects object
          where object.bucket_id = 'professional-portfolio'
            and object.name = object_path
            and object.owner_id = new.id::text
        ) then
      raise exception 'La imagen debe existir en el almacenamiento de LinkO.';
    end if;
  end loop;

  for item in select value from jsonb_array_elements(previous) loop
    object_path := item->>'path';
    if object_path is not null
        and not (new.portfolio @> jsonb_build_array(item))
        and exists (
          select 1 from storage.objects object
          where object.bucket_id = 'professional-portfolio'
            and object.name = object_path
        ) then
      raise exception 'Elimina primero el archivo del almacenamiento.';
    end if;
  end loop;
  return new;
end;
$$;

drop trigger if exists validate_professional_portfolio_storage
on public.professional_profiles;
create trigger validate_professional_portfolio_storage
before insert or update of portfolio on public.professional_profiles
for each row execute function public.validate_professional_portfolio_storage();

create or replace function public.validate_professional_verification_storage()
returns trigger language plpgsql security definer set search_path = '' as $$
declare
  previous jsonb := case when tg_op = 'INSERT' then '[]'::jsonb else old.documents end;
  item jsonb;
  object_path text;
begin
  if new.documents is not distinct from previous then return new; end if;
  if jsonb_typeof(new.documents) <> 'array' then
    raise exception 'Los documentos de verificación no son válidos.';
  end if;
  if exists (
    select 1 from public.professional_profiles professional
    where professional.id = new.professional_id
      and professional.verification_status = 'verified'
  ) then
    raise exception 'Una verificación aprobada no puede modificarse.';
  end if;

  for item in select value from jsonb_array_elements(new.documents) loop
    if previous @> jsonb_build_array(item) then continue; end if;
    object_path := item->>'path';
    if jsonb_typeof(item) <> 'object' or object_path is null
        or object_path not like new.professional_id::text || '/%'
        or not exists (
          select 1 from storage.objects object
          where object.bucket_id = 'professional-verification'
            and object.name = object_path
            and object.owner_id = new.professional_id::text
        ) then
      raise exception 'El documento debe existir en el almacenamiento privado de LinkO.';
    end if;
  end loop;

  for item in select value from jsonb_array_elements(previous) loop
    object_path := item->>'path';
    if object_path is not null
        and not (new.documents @> jsonb_build_array(item))
        and exists (
          select 1 from storage.objects object
          where object.bucket_id = 'professional-verification'
            and object.name = object_path
        ) then
      raise exception 'Elimina primero el archivo del almacenamiento privado.';
    end if;
  end loop;
  return new;
end;
$$;

drop trigger if exists validate_professional_verification_storage
on public.professional_verification_submissions;
create trigger validate_professional_verification_storage
before insert or update of documents
on public.professional_verification_submissions
for each row execute function public.validate_professional_verification_storage();

revoke execute on function public.validate_professional_portfolio_storage(),
  public.validate_professional_verification_storage()
from public, anon, authenticated;
