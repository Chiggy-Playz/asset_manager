-- migrate:up
-- Migration: Add hierarchical location support
-- Run this in your Supabase SQL editor

-- Add parent_id column for self-referential hierarchy
ALTER TABLE public.locations
ADD COLUMN parent_id uuid REFERENCES public.locations(id) ON DELETE CASCADE;

-- Create index for efficient parent lookups
CREATE INDEX idx_locations_parent_id ON public.locations(parent_id);

-- Add constraint to prevent more than 3 levels of nesting
-- This is enforced via a trigger function
CREATE OR REPLACE FUNCTION check_location_depth()
RETURNS TRIGGER AS $$
DECLARE
  depth INTEGER := 0;
  current_parent_id uuid := NEW.parent_id;
BEGIN
  -- Count depth by traversing up the tree
  WHILE current_parent_id IS NOT NULL LOOP
    depth := depth + 1;
    IF depth > 2 THEN
      RAISE EXCEPTION 'Maximum nesting depth of 3 levels exceeded';
    END IF;
    SELECT parent_id INTO current_parent_id
    FROM public.locations
    WHERE id = current_parent_id;
  END LOOP;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER enforce_location_depth
BEFORE INSERT OR UPDATE ON public.locations
FOR EACH ROW
EXECUTE FUNCTION check_location_depth();

-- Prevent circular references
CREATE OR REPLACE FUNCTION check_location_circular_ref()
RETURNS TRIGGER AS $$
DECLARE
  current_id uuid := NEW.parent_id;
BEGIN
  IF NEW.parent_id IS NULL THEN
    RETURN NEW;
  END IF;

  -- Traverse up to check if we encounter the same id
  WHILE current_id IS NOT NULL LOOP
    IF current_id = NEW.id THEN
      RAISE EXCEPTION 'Circular reference detected in location hierarchy';
    END IF;
    SELECT parent_id INTO current_id
    FROM public.locations
    WHERE id = current_id;
  END LOOP;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER prevent_location_circular_ref
BEFORE INSERT OR UPDATE ON public.locations
FOR EACH ROW
EXECUTE FUNCTION check_location_circular_ref();


-- migrate:down

-- Remove triggers and functions
DROP TRIGGER IF EXISTS prevent_location_circular_ref ON public.locations;
DROP FUNCTION IF EXISTS check_location_circular_ref();

DROP TRIGGER IF EXISTS enforce_location_depth ON public.locations;
DROP FUNCTION IF EXISTS check_location_depth();

-- Remove parent_id column and index
DROP INDEX IF EXISTS idx_locations_parent_id;

ALTER TABLE public.locations
DROP COLUMN IF EXISTS parent_id;
