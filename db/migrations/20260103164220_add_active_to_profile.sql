-- migrate:up
alter table profiles add column is_active boolean not null default true;
create index on profiles (is_active);

-- Update RLS policies to prevent users from modifying is_active
drop policy "Users update own profile" on profiles;
create policy "Users update own profile"
on profiles
for update
using ((select auth.uid()) = id)
with check (
  (select auth.uid()) = id
  and role = role        -- role cannot be changed by user
  and is_active = is_active  -- is_active cannot be changed by user
);

drop policy "Admins update profiles" on profiles;
create policy "Admins update profiles"
on profiles
for update
using (is_admin())
with check (is_active = is_active);  -- is_active cannot be changed even by admins (only via service role)

-- migrate:down
drop policy "Admins update profiles" on profiles;
drop policy "Users update own profile" on profiles;

create policy "Users update own profile"
on profiles
for update
using ((select auth.uid()) = id)
with check (
  (select auth.uid()) = id
  and role = role
);

create policy "Admins update profiles"
on profiles
for update
using (is_admin());

alter table profiles drop column is_active;

