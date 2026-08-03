create table if not exists public.conversations (
  id uuid primary key default gen_random_uuid(),
  service_request_id uuid not null unique
    references public.service_requests(id) on delete cascade,
  customer_id uuid not null references public.profiles(id) on delete cascade,
  professional_id uuid not null references public.profiles(id) on delete cascade,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.messages (
  id uuid primary key default gen_random_uuid(),
  conversation_id uuid not null
    references public.conversations(id) on delete cascade,
  sender_id uuid references public.profiles(id) on delete set null,
  type text not null check (type in ('text', 'system', 'actionCard')),
  body text,
  metadata jsonb,
  created_at timestamptz not null default now()
);

create index if not exists messages_conversation_created_idx
on public.messages (conversation_id, created_at, id);

alter table public.conversations enable row level security;
alter table public.messages enable row level security;

create policy "Request participants can read conversations"
on public.conversations for select to authenticated
using (
  (select auth.uid()) in (customer_id, professional_id)
  and exists (
    select 1 from public.service_requests request
    where request.id = service_request_id
      and request.customer_id = customer_id
      and request.professional_id = professional_id
      and (select auth.uid()) in (request.customer_id, request.professional_id)
  )
);

create policy "Request participants can create conversations"
on public.conversations for insert to authenticated
with check (
  (select auth.uid()) in (customer_id, professional_id)
  and exists (
    select 1 from public.service_requests request
    where request.id = service_request_id
      and request.customer_id = customer_id
      and request.professional_id = professional_id
      and (select auth.uid()) in (request.customer_id, request.professional_id)
  )
);

create policy "Request participants can read messages"
on public.messages for select to authenticated
using (exists (
  select 1 from public.conversations conversation
  where conversation.id = conversation_id
    and (select auth.uid()) in (
      conversation.customer_id,
      conversation.professional_id
    )
));

create policy "Request participants can insert messages"
on public.messages for insert to authenticated
with check (exists (
  select 1 from public.conversations conversation
  where conversation.id = conversation_id
    and (select auth.uid()) in (
      conversation.customer_id,
      conversation.professional_id
    )
    and (
      sender_id = (select auth.uid())
      or (sender_id is null and type = 'system')
    )
));

drop trigger if exists conversations_set_updated_at on public.conversations;
create trigger conversations_set_updated_at
before update on public.conversations
for each row execute function public.set_updated_at();

create or replace function public.touch_conversation_after_message()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  update public.conversations
  set updated_at = now()
  where id = new.conversation_id;
  return new;
end;
$$;

revoke execute on function public.touch_conversation_after_message()
from public, anon, authenticated;

drop trigger if exists messages_touch_conversation on public.messages;
create trigger messages_touch_conversation
after insert on public.messages
for each row execute function public.touch_conversation_after_message();

do $$
begin
  if not exists (
    select 1
    from pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public'
      and tablename = 'messages'
  ) then
    alter publication supabase_realtime add table public.messages;
  end if;
end;
$$;
