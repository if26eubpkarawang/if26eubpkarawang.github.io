drop policy if exists if26e_assignments_admin_delete on public.if26e_assignments;
create policy if26e_assignments_admin_delete
  on public.if26e_assignments
  for delete
  to authenticated
  using (
    uploaded_by = auth.uid()
    and exists (
      select 1
      from public.if26e_admins
      where user_id = auth.uid()
    )
  );

drop policy if exists if26e_announcements_admin_delete on public.if26e_announcements;
create policy if26e_announcements_admin_delete
  on public.if26e_announcements
  for delete
  to authenticated
  using (
    uploaded_by = auth.uid()
    and exists (
      select 1
      from public.if26e_admins
      where user_id = auth.uid()
    )
  );
