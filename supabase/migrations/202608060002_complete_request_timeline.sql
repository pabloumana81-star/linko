alter table public.request_events
drop constraint if exists request_events_type_check;

alter table public.request_events
add constraint request_events_type_check check (type in (
  'request_created',
  'quotation_created',
  'quotation_accepted',
  'quotation_rejected',
  'schedule_proposed',
  'schedule_accepted',
  'work_started',
  'work_completed',
  'rating_requested',
  'rating_submitted'
));

create or replace function public.record_request_created_event()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.request_events (request_id, type, payload)
  values (new.id, 'request_created', '{}'::jsonb);
  return new;
end;
$$;

drop trigger if exists service_requests_record_created_event
on public.service_requests;
create trigger service_requests_record_created_event
after insert on public.service_requests
for each row execute function public.record_request_created_event();

create or replace function public.submit_service_rating(
  p_request_id uuid,
  p_professional_id uuid,
  p_stars integer,
  p_comment text default null
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  if p_stars not between 1 and 5 then
    raise exception 'La calificación debe estar entre 1 y 5.';
  end if;
  if not exists (
    select 1 from public.service_requests request
    where request.id = p_request_id
      and request.customer_id = (select auth.uid())
      and request.professional_id = p_professional_id
      and request.status = 'completed'
  ) then
    raise exception 'No puedes calificar esta solicitud.';
  end if;
  insert into public.ratings (
    request_id, professional_id, customer_id, stars, comment
  ) values (
    p_request_id, p_professional_id, (select auth.uid()), p_stars, p_comment
  );
  update public.service_requests set status = 'reviewed'
  where id = p_request_id and status = 'completed';
  insert into public.request_events (request_id, type, payload)
  values (
    p_request_id,
    'rating_submitted',
    jsonb_build_object('stars', p_stars)
  );
end;
$$;

revoke execute on function public.record_request_created_event()
from public, anon, authenticated;
revoke execute on function public.submit_service_rating(uuid, uuid, integer, text)
from public, anon;
grant execute on function public.submit_service_rating(uuid, uuid, integer, text)
to authenticated;
