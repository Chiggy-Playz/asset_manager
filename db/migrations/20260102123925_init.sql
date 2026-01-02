-- migrate:up

create table profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  name text not null,
  role text not null check (role in ('user', 'admin')) default 'user',
  created_at timestamptz default now()
);

create index on profiles (role);

alter table profiles enable row level security;

create or replace function is_admin()
returns boolean
language sql
security definer
stable
as $$
  select exists (
    select 1
    from profiles
    where id = (select auth.uid())
      and role = 'admin'
  );
$$;

create policy "Users read own profile"
on profiles
for select
using ((select auth.uid()) = id);

create policy "Admins read all profiles"
on profiles
for select
using (is_admin());

create policy "Users insert own profile"
on profiles
for insert
with check ((select auth.uid()) = id and role = 'user');

create policy "Users update own profile"
on profiles
for update
using ((select auth.uid()) = id)
with check (
  (select auth.uid()) = id 
  and role=role  -- role cannot be changed by user
);

create policy "Admins update profiles"
on profiles
for update
using (is_admin());

-- migrate:down

drop policy "Admins update profiles" on profiles;
drop policy "Users update own profile" on profiles;
drop policy "Users insert own profile" on profiles;
drop policy "Admins read all profiles" on profiles;
drop policy "Users read own profile" on profiles;
drop function is_admin();
drop table profiles;
