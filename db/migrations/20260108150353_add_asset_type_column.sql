-- migrate:up

-- ============================================================================
-- 1. Add asset_type column to assets table
-- ============================================================================

ALTER TABLE assets ADD COLUMN asset_type text;
UPDATE assets SET asset_type = 'Computer' WHERE asset_type IS NULL;
-- ============================================================================
-- 2. Create field_option for asset_type with default values
-- ============================================================================

INSERT INTO field_options (field_name, options, is_required)
VALUES ('asset_type', '["Computer", "Laptop"]'::jsonb, true);

-- ============================================================================
-- 3. Update trigger to include asset_type in current_data
-- ============================================================================

CREATE OR REPLACE FUNCTION asset_request_populate_current_data()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
SELECT jsonb_build_object(
      'cpu', cpu,
      'generation', generation,
      'ram', ram,
      'storage', storage,
      'serial_number', serial_number,
      'model_number', model_number,
      'asset_type', asset_type
    )
INTO NEW.current_data
FROM assets
WHERE id = NEW.asset_id;
RETURN NEW;
END;
$$;

-- migrate:down

-- Restore original trigger without asset_type
CREATE OR REPLACE FUNCTION asset_request_populate_current_data()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
SELECT jsonb_build_object(
      'cpu', cpu,
      'generation', generation,
      'ram', ram,
      'storage', storage,
      'serial_number', serial_number,
      'model_number', model_number
    )
INTO NEW.current_data
FROM assets
WHERE id = NEW.asset_id;
RETURN NEW;
END;
$$;

DELETE FROM field_options WHERE field_name = 'asset_type';

ALTER TABLE assets DROP COLUMN asset_type;
