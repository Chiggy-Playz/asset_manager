-- migrate:up

create table profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  name text not null,
  role text not null check (role in ('user', 'admin')) default 'user',
  created_at timestamptz default now()
);

create index on profiles (role);

alter table profiles enable row level security;

create policy "Users read own profile"
on profiles
for select
using (auth.uid() = id);

create policy "Admins read all profiles"
on profiles
for select
using (
  exists (
    select 1 from profiles
    where id = auth.uid() and role = 'admin'
  )
);

create policy "Users insert own profile"
on profiles
for insert
with check (auth.uid() = id);

create policy "Users update own profile"
on profiles
for update
using (auth.uid() = id)
with check (
  auth.uid() = id 
  and role=role  -- role cannot be changed by user
);

create policy "Admins update profiles"
on profiles
for update
using (
  exists (
    select 1 from profiles
    where id = auth.uid() and role = 'admin'
  )
);

-- migrate:down

drop policy "Admins update profiles" on profiles;
drop policy "Users update own profile" on profiles;
drop policy "Users insert own profile" on profiles;
drop policy "Admins read all profiles" on profiles;
drop policy "Users read own profile" on profiles;
drop table profiles;
