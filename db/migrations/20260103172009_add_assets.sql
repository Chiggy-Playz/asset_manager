-- migrate:up

-- Locations table
create table locations (
  id uuid primary key default gen_random_uuid(),
  name text not null unique,
  description text,
  created_at timestamptz default now()
);

alter table locations enable row level security;

-- Everyone can read locations
create policy "Anyone can read locations"
on locations for select
using (true);

-- Only admins can modify locations
create policy "Admins can insert locations"
on locations for insert
with check (is_admin());

create policy "Admins can update locations"
on locations for update
using (is_admin());

create policy "Admins can delete locations"
on locations for delete
using (is_admin());

-- Seed default location
insert into locations (name, description) values
  ('Office', 'Default office location');

-- Assets table
create table assets (
  id uuid primary key default gen_random_uuid(),
  tag_id int generated always as identity unique,
  cpu text,
  generation text,
  ram text,
  storage text,
  serial_number text unique,
  model_number text,
  current_location_id uuid references locations(id) on delete restrict,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

create index on assets (current_location_id);

alter table assets enable row level security;

-- Everyone can read assets
create policy "Anyone can read assets"
on assets for select
using (auth.uid() is not null);

-- All authenticated users can modify assets
create policy "Authenticated users can insert assets"
on assets for insert
with check (auth.uid() is not null);

create policy "Authenticated users can update assets"
on assets for update
using (auth.uid() is not null);

create policy "Authenticated users can delete assets"
on assets for delete
using (auth.uid() is not null);

-- Asset audit logs table
create table asset_audit_logs (
  id uuid primary key default gen_random_uuid(),
  asset_id uuid references assets(id) on delete set null,
  user_id uuid references profiles(id) on delete set null,
  action text not null check (action in ('created', 'updated', 'deleted', 'transferred')),
  old_values jsonb,
  new_values jsonb,
  created_at timestamptz default now()
);

create index on asset_audit_logs (asset_id);
create index on asset_audit_logs (user_id);
create index on asset_audit_logs (created_at);

alter table asset_audit_logs enable row level security;

-- Everyone can read audit logs
create policy "Anyone can read asset_audit_logs"
on asset_audit_logs for select
using (true);

-- Allow inserts from triggers (using service role) and admins
create policy "System and admins can insert asset_audit_logs"
on asset_audit_logs for insert
with check (true);

-- Trigger function to auto-update updated_at on assets
create or replace function update_assets_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create trigger assets_updated_at
  before update on assets
  for each row
  execute function update_assets_updated_at();

-- Trigger function to log asset changes
create or replace function log_asset_changes()
returns trigger
language plpgsql
security definer
as $$
begin
  if tg_op = 'INSERT' then
    insert into asset_audit_logs (asset_id, user_id, action, new_values)
    values (new.id, auth.uid(), 'created', to_jsonb(new));
    return new;
  elsif tg_op = 'UPDATE' then
    -- Check if location changed
    if old.current_location_id is distinct from new.current_location_id then
      insert into asset_audit_logs (asset_id, user_id, action, old_values, new_values)
      values (new.id, auth.uid(), 'transferred', to_jsonb(old), to_jsonb(new));
    else
      insert into asset_audit_logs (asset_id, user_id, action, old_values, new_values)
      values (new.id, auth.uid(), 'updated', to_jsonb(old), to_jsonb(new));
    end if;
    return new;
  elsif tg_op = 'DELETE' then
    insert into asset_audit_logs (asset_id, user_id, action, old_values)
    values (old.id, auth.uid(), 'deleted', to_jsonb(old));
    return old;
  end if;
  return null;
end;
$$;

create trigger asset_audit_trigger
  after insert or update or delete on assets
  for each row
  execute function log_asset_changes();

-- migrate:down

drop trigger asset_audit_trigger on assets;
drop function log_asset_changes();
drop trigger assets_updated_at on assets;
drop function update_assets_updated_at();

drop policy "System and admins can insert asset_audit_logs" on asset_audit_logs;
drop policy "Anyone can read asset_audit_logs" on asset_audit_logs;
drop table asset_audit_logs;

drop policy "Authenticated users can delete assets" on assets;
drop policy "Authenticated users can update assets" on assets;
drop policy "Authenticated users can insert assets" on assets;
drop policy "Anyone can read assets" on assets;
drop table assets;

drop policy "Admins can delete locations" on locations;
drop policy "Admins can update locations" on locations;
drop policy "Admins can insert locations" on locations;
drop policy "Anyone can read locations" on locations;
drop table locations;
