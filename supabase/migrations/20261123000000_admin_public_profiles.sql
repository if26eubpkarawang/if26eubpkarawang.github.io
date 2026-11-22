create table if not exists public.if26e_admin_profiles (
  user_id uuid primary key references public.if26e_admins (user_id) on delete cascade,
  display_name text not null default 'Pengurus IF26E',
  bio text not null default '',
  updated_at timestamptz not null default now()
);

alter table public.if26e_admin_profiles enable row level security;

drop policy if exists if26e_admin_profiles_public_read on public.if26e_admin_profiles;
create policy if26e_admin_profiles_public_read
  on public.if26e_admin_profiles
  for select
  to anon, authenticated
  using (true);

drop policy if exists if26e_admin_profiles_admin_upsert_own on public.if26e_admin_profiles;
create policy if26e_admin_profiles_admin_upsert_own
  on public.if26e_admin_profiles
  for all
  to authenticated
  using (
    user_id = auth.uid()
    and exists (
      select 1
      from public.if26e_admins
      where user_id = auth.uid()
    )
  )
  with check (
    user_id = auth.uid()
    and exists (
      select 1
      from public.if26e_admins
      where user_id = auth.uid()
    )
  );

revoke all on public.if26e_admin_profiles from public, anon, authenticated;
grant select on public.if26e_admin_profiles to anon, authenticated;
grant insert (user_id, display_name, bio, updated_at) on public.if26e_admin_profiles to authenticated;
grant update (display_name, bio, updated_at) on public.if26e_admin_profiles to authenticated;
