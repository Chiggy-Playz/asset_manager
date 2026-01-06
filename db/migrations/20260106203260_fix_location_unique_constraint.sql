-- migrate:up

-- Remove the simple unique constraint on name
ALTER TABLE locations DROP CONSTRAINT IF EXISTS locations_name_key;

-- Add composite unique constraint: name must be unique within the same parent
-- For root locations (parent_id IS NULL), use a partial unique index
CREATE UNIQUE INDEX locations_name_parent_unique
ON locations (name, parent_id)
WHERE parent_id IS NOT NULL;

-- For root locations (no parent), name must still be unique among roots
CREATE UNIQUE INDEX locations_name_root_unique
ON locations (name)
WHERE parent_id IS NULL;

-- migrate:down

-- Remove the new indexes
DROP INDEX IF EXISTS locations_name_root_unique;
DROP INDEX IF EXISTS locations_name_parent_unique;

-- Restore the simple unique constraint (may fail if duplicates exist)
ALTER TABLE locations ADD CONSTRAINT locations_name_key UNIQUE (name);
