-- Public marketplace discovery is intentionally exposed only through this
-- narrow SECURITY DEFINER function. Base-table RLS remains unchanged.
revoke execute on function public.list_available_professionals() from public;
grant execute on function public.list_available_professionals()
to anon, authenticated;
