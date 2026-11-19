insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'if26e-admin-avatars',
  'if26e-admin-avatars',
  true,
  2097152,
  array['image/jpeg', 'image/png', 'image/webp']
)
on conflict (id) do update
set public = excluded.public,
    file_size_limit = excluded.file_size_limit,
    allowed_mime_types = excluded.allowed_mime_types;

drop policy if exists if26e_admin_avatars_select_own on storage.objects;
create policy if26e_admin_avatars_select_own
  on storage.objects
  for select
  to authenticated
  using (
    bucket_id = 'if26e-admin-avatars'
    and name = (auth.uid()::text || '/avatar')
    and exists (
      select 1
      from public.if26e_admins
      where user_id = auth.uid()
    )
  );

drop policy if exists if26e_admin_avatars_insert_own on storage.objects;
create policy if26e_admin_avatars_insert_own
  on storage.objects
  for insert
  to authenticated
  with check (
    bucket_id = 'if26e-admin-avatars'
    and name = (auth.uid()::text || '/avatar')
    and exists (
      select 1
      from public.if26e_admins
      where user_id = auth.uid()
    )
  );

drop policy if exists if26e_admin_avatars_update_own on storage.objects;
create policy if26e_admin_avatars_update_own
  on storage.objects
  for update
  to authenticated
  using (
    bucket_id = 'if26e-admin-avatars'
    and name = (auth.uid()::text || '/avatar')
    and exists (
      select 1
      from public.if26e_admins
      where user_id = auth.uid()
    )
  )
  with check (
    bucket_id = 'if26e-admin-avatars'
    and name = (auth.uid()::text || '/avatar')
    and exists (
      select 1
      from public.if26e_admins
      where user_id = auth.uid()
    )
  );
