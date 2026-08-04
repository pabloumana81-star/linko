alter table public.profiles
add column if not exists role text not null default 'user'
check (role in ('user', 'admin'));

revoke update on public.profiles from authenticated;
grant update (display_name, avatar_url, active_mode) on public.profiles
to authenticated;
