-- Production storage for public professional portfolios and private verification files.
-- Existing JSON metadata is preserved verbatim; only new objects use owner-scoped paths.

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'professional-portfolio',
  'professional-portfolio',
  true,
  5242880,
  array['image/jpeg', 'image/png', 'image/webp']
)
on conflict (id) do update set
  public = excluded.public,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'professional-verification',
  'professional-verification',
  false,
  10485760,
  array['image/jpeg', 'image/png', 'image/webp', 'application/pdf']
)
on conflict (id) do update set
  public = excluded.public,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

drop policy if exists "Public can view professional portfolios" on storage.objects;
create policy "Public can view professional portfolios"
on storage.objects for select to public
using (bucket_id = 'professional-portfolio');

drop policy if exists "Professionals upload own portfolio" on storage.objects;
create policy "Professionals upload own portfolio"
on storage.objects for insert to authenticated
with check (
  bucket_id = 'professional-portfolio'
  and (storage.foldername(name))[1] = (select auth.uid())::text
  and exists (
    select 1 from public.professional_profiles professional
    where professional.id = (select auth.uid())
  )
);

drop policy if exists "Professionals update own portfolio" on storage.objects;
create policy "Professionals update own portfolio"
on storage.objects for update to authenticated
using (
  bucket_id = 'professional-portfolio'
  and owner_id = (select auth.uid())::text
  and (storage.foldername(name))[1] = (select auth.uid())::text
)
with check (
  bucket_id = 'professional-portfolio'
  and owner_id = (select auth.uid())::text
  and (storage.foldername(name))[1] = (select auth.uid())::text
);

drop policy if exists "Professionals delete own portfolio" on storage.objects;
create policy "Professionals delete own portfolio"
on storage.objects for delete to authenticated
using (
  bucket_id = 'professional-portfolio'
  and owner_id = (select auth.uid())::text
  and (storage.foldername(name))[1] = (select auth.uid())::text
);

drop policy if exists "Professionals read own verification files" on storage.objects;
create policy "Professionals read own verification files"
on storage.objects for select to authenticated
using (
  bucket_id = 'professional-verification'
  and owner_id = (select auth.uid())::text
  and (storage.foldername(name))[1] = (select auth.uid())::text
);

drop policy if exists "Admins read verification files" on storage.objects;
create policy "Admins read verification files"
on storage.objects for select to authenticated
using (
  bucket_id = 'professional-verification'
  and exists (
    select 1 from public.profiles profile
    where profile.id = (select auth.uid()) and profile.role = 'admin'
  )
);

drop policy if exists "Professionals upload own verification files" on storage.objects;
create policy "Professionals upload own verification files"
on storage.objects for insert to authenticated
with check (
  bucket_id = 'professional-verification'
  and (storage.foldername(name))[1] = (select auth.uid())::text
  and exists (
    select 1 from public.professional_profiles professional
    where professional.id = (select auth.uid())
      and professional.verification_status <> 'verified'
  )
);

drop policy if exists "Professionals update own verification files" on storage.objects;
create policy "Professionals update own verification files"
on storage.objects for update to authenticated
using (
  bucket_id = 'professional-verification'
  and owner_id = (select auth.uid())::text
  and (storage.foldername(name))[1] = (select auth.uid())::text
)
with check (
  bucket_id = 'professional-verification'
  and owner_id = (select auth.uid())::text
  and (storage.foldername(name))[1] = (select auth.uid())::text
  and exists (
    select 1 from public.professional_profiles professional
    where professional.id = (select auth.uid())
      and professional.verification_status <> 'verified'
  )
);

drop policy if exists "Professionals delete own verification files" on storage.objects;
create policy "Professionals delete own verification files"
on storage.objects for delete to authenticated
using (
  bucket_id = 'professional-verification'
  and owner_id = (select auth.uid())::text
  and (storage.foldername(name))[1] = (select auth.uid())::text
  and exists (
    select 1 from public.professional_profiles professional
    where professional.id = (select auth.uid())
      and professional.verification_status <> 'verified'
  )
);

create or replace function public.add_own_portfolio_object(
  p_path text,
  p_name text,
  p_mime_type text,
  p_size integer
)
returns void language plpgsql security definer set search_path = '' as $$
declare actor uuid := (select auth.uid());
begin
  if actor is null or not exists (
    select 1 from public.professional_profiles where id = actor
  ) then raise exception 'Solo un profesional autenticado puede modificar su portafolio.'; end if;
  if p_path not like actor::text || '/%' or p_path like '%..%' then
    raise exception 'La ruta del archivo no es válida.';
  end if;
  if p_mime_type not in ('image/jpeg', 'image/png', 'image/webp')
      or p_size <= 0 or p_size > 5242880 then
    raise exception 'El archivo del portafolio no es válido.';
  end if;
  update public.professional_profiles
  set portfolio = portfolio || jsonb_build_array(jsonb_build_object(
    'path', p_path, 'name', left(coalesce(p_name, 'Imagen'), 200),
    'mime_type', p_mime_type, 'size', p_size
  )), updated_at = now()
  where id = actor
    and not exists (select 1 from jsonb_array_elements(portfolio) item
      where item->>'path' = p_path)
    and jsonb_array_length(portfolio) < 20;
  if not found then raise exception 'No se pudo agregar la imagen al portafolio.'; end if;
end;
$$;

create or replace function public.remove_own_portfolio_object(p_path text)
returns void language plpgsql security definer set search_path = '' as $$
declare actor uuid := (select auth.uid());
begin
  if actor is null or p_path not like actor::text || '/%' or p_path like '%..%' then
    raise exception 'La ruta del archivo no es válida.';
  end if;
  update public.professional_profiles professional
  set portfolio = coalesce((select jsonb_agg(item)
    from jsonb_array_elements(professional.portfolio) item
    where item->>'path' is distinct from p_path), '[]'::jsonb),
    updated_at = now()
  where professional.id = actor;
  if not found then raise exception 'No existe un perfil profesional para esta cuenta.'; end if;
end;
$$;

create or replace function public.remove_own_legacy_portfolio_url(p_url text)
returns void language plpgsql security definer set search_path = '' as $$
declare actor uuid := (select auth.uid());
begin
  if actor is null or p_url !~ '^https://' then
    raise exception 'La dirección de la imagen no es válida.';
  end if;
  update public.professional_profiles professional
  set portfolio = coalesce((select jsonb_agg(item)
    from jsonb_array_elements(professional.portfolio) item
    where not (
      (jsonb_typeof(item) = 'string' and item #>> '{}' = p_url)
      or (jsonb_typeof(item) = 'object' and item->>'url' = p_url)
    )), '[]'::jsonb), updated_at = now()
  where professional.id = actor;
  if not found then raise exception 'No existe un perfil profesional para esta cuenta.'; end if;
end;
$$;

create or replace function public.add_own_verification_document(
  p_path text,
  p_name text,
  p_mime_type text,
  p_size integer
)
returns void language plpgsql security definer set search_path = '' as $$
declare actor uuid := (select auth.uid());
begin
  if actor is null or not exists (
    select 1 from public.professional_profiles
    where id = actor and verification_status <> 'verified'
  ) then raise exception 'No puedes modificar los documentos de verificación.'; end if;
  if p_path not like actor::text || '/%' or p_path like '%..%' then
    raise exception 'La ruta del documento no es válida.';
  end if;
  if p_mime_type not in ('image/jpeg', 'image/png', 'image/webp', 'application/pdf')
      or p_size <= 0 or p_size > 10485760 then
    raise exception 'El documento de verificación no es válido.';
  end if;
  insert into public.professional_verification_submissions (professional_id, documents)
  values (actor, jsonb_build_array(jsonb_build_object(
    'path', p_path, 'name', left(coalesce(p_name, 'Documento'), 200),
    'mime_type', p_mime_type, 'size', p_size
  )))
  on conflict (professional_id) do update set
    documents = case when not exists (
      select 1 from jsonb_array_elements(public.professional_verification_submissions.documents) item
      where item->>'path' = p_path
    ) and jsonb_array_length(public.professional_verification_submissions.documents) < 10
    then public.professional_verification_submissions.documents || excluded.documents
    else public.professional_verification_submissions.documents end;
end;
$$;

create or replace function public.remove_own_verification_document(p_path text)
returns void language plpgsql security definer set search_path = '' as $$
declare actor uuid := (select auth.uid());
begin
  if actor is null or p_path not like actor::text || '/%' or p_path like '%..%'
      or exists (select 1 from public.professional_profiles
        where id = actor and verification_status = 'verified') then
    raise exception 'No puedes modificar los documentos de verificación.';
  end if;
  update public.professional_verification_submissions submission
  set documents = coalesce((select jsonb_agg(item)
    from jsonb_array_elements(submission.documents) item
    where item->>'path' is distinct from p_path), '[]'::jsonb)
  where submission.professional_id = actor;
end;
$$;

revoke execute on function public.add_own_portfolio_object(text, text, text, integer),
  public.remove_own_portfolio_object(text),
  public.remove_own_legacy_portfolio_url(text),
  public.add_own_verification_document(text, text, text, integer),
  public.remove_own_verification_document(text)
from public, anon;
grant execute on function public.add_own_portfolio_object(text, text, text, integer),
  public.remove_own_portfolio_object(text),
  public.remove_own_legacy_portfolio_url(text),
  public.add_own_verification_document(text, text, text, integer),
  public.remove_own_verification_document(text)
to authenticated;
