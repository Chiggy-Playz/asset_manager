-- migrate:up
revoke all on table public.schema_migrations from anon;
revoke all on table public.schema_migrations from authenticated;

-- migrate:down

grant select on table public.schema_migrations to anon;
grant select on table public.schema_migrations to authenticated;

