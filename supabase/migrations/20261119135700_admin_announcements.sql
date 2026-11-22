create table if not exists public.if26e_announcements (
  id uuid primary key default gen_random_uuid(),
  title text not null check (char_length(btrim(title)) between 1 and 120),
  content text not null check (char_length(btrim(content)) between 1 and 5000),
  uploaded_by uuid references auth.users (id) on delete set null default auth.uid(),
  uploaded_by_name text not null default 'Nama belum tercatat',
  created_at timestamptz not null default now()
);

drop trigger if exists if26e_announcements_set_uploader on public.if26e_announcements;
create trigger if26e_announcements_set_uploader
  before insert on public.if26e_announcements
  for each row
  execute function public.set_if26e_assignment_uploader();

alter table public.if26e_announcements enable row level security;

drop policy if exists if26e_announcements_public_read on public.if26e_announcements;
create policy if26e_announcements_public_read
  on public.if26e_announcements
  for select
  to anon, authenticated
  using (true);

drop policy if exists if26e_announcements_admin_insert on public.if26e_announcements;
create policy if26e_announcements_admin_insert
  on public.if26e_announcements
  for insert
  to authenticated
  with check (
    exists (
      select 1
      from public.if26e_admins
      where user_id = auth.uid()
    )
    and uploaded_by = auth.uid()
  );

drop policy if exists if26e_announcements_admin_delete on public.if26e_announcements;
create policy if26e_announcements_admin_delete
  on public.if26e_announcements
  for delete
  to authenticated
  using (
    exists (
      select 1
      from public.if26e_admins
      where user_id = auth.uid()
    )
    and uploaded_by = auth.uid()
  );

grant select on public.if26e_announcements to anon, authenticated;
grant insert, delete on public.if26e_announcements to authenticated;
