create table if not exists public.if26e_admin_contacts (
  user_id uuid primary key references public.if26e_admins (user_id) on delete cascade,
  whatsapp_number text not null
    check (whatsapp_number ~ '^[1-9][0-9]{7,14}$')
);

alter table public.if26e_admin_contacts enable row level security;

drop policy if exists if26e_admin_contacts_public_read on public.if26e_admin_contacts;
create policy if26e_admin_contacts_public_read
  on public.if26e_admin_contacts
  for select
  to anon, authenticated
  using (true);

drop policy if exists if26e_admin_contacts_admin_insert_own on public.if26e_admin_contacts;
create policy if26e_admin_contacts_admin_insert_own
  on public.if26e_admin_contacts
  for insert
  to authenticated
  with check (
    user_id = auth.uid()
    and exists (
      select 1
      from public.if26e_admins
      where user_id = auth.uid()
    )
  );

drop policy if exists if26e_admin_contacts_admin_update_own on public.if26e_admin_contacts;
create policy if26e_admin_contacts_admin_update_own
  on public.if26e_admin_contacts
  for update
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

drop policy if exists if26e_admin_contacts_admin_delete_own on public.if26e_admin_contacts;
create policy if26e_admin_contacts_admin_delete_own
  on public.if26e_admin_contacts
  for delete
  to authenticated
  using (
    user_id = auth.uid()
    and exists (
      select 1
      from public.if26e_admins
      where user_id = auth.uid()
    )
  );

revoke all on public.if26e_admin_contacts from public, anon, authenticated;
grant select on public.if26e_admin_contacts to anon, authenticated;
grant insert (user_id, whatsapp_number) on public.if26e_admin_contacts to authenticated;
grant update (user_id, whatsapp_number) on public.if26e_admin_contacts to authenticated;
grant delete on public.if26e_admin_contacts to authenticated;
