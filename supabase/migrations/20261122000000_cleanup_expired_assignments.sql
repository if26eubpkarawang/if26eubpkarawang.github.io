create extension if not exists pg_cron;

create or replace function public.cleanup_expired_if26e_assignments()
returns integer
language plpgsql
security definer
set search_path = ''
as $$
declare
  deleted_count integer;
begin
  if auth.uid() is not null and not exists (
    select 1
    from public.if26e_admins
    where user_id = auth.uid()
  ) then
    raise exception 'Administrator access required' using errcode = '42501';
  end if;

  delete from storage.objects
  where bucket_id = 'if26e-tugas'
    and name in (
      select file_path
      from public.if26e_assignments
      where due_date is not null
        and due_date < current_date
    );

  delete from public.if26e_assignments
  where due_date is not null
    and due_date < current_date;

  get diagnostics deleted_count = row_count;
  return deleted_count;
end;
$$;

revoke all on function public.cleanup_expired_if26e_assignments() from public;
grant execute on function public.cleanup_expired_if26e_assignments() to authenticated;

do $$
declare
  existing_job_id bigint;
begin
  select jobid
  into existing_job_id
  from cron.job
  where jobname = 'cleanup-expired-if26e-assignments'
  limit 1;

  if existing_job_id is not null then
    perform cron.unschedule(existing_job_id);
  end;

  perform cron.schedule(
    'cleanup-expired-if26e-assignments',
    '5 0 * * *',
    'select public.cleanup_expired_if26e_assignments()'
  );
end;
$$;
