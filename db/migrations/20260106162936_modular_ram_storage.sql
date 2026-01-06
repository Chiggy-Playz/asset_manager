-- migrate:up

-- ============================================================================
-- 1. Convert assets.ram from TEXT to JSONB array
-- ============================================================================

ALTER TABLE assets
  ALTER COLUMN ram TYPE jsonb USING
    CASE
      WHEN ram IS NOT NULL THEN jsonb_build_array(jsonb_build_object('size', ram))
      ELSE '[]'::jsonb
    END;

ALTER TABLE assets
  ALTER COLUMN ram SET DEFAULT '[]'::jsonb;

-- ============================================================================
-- 2. Convert assets.storage from TEXT to JSONB array
-- ============================================================================

ALTER TABLE assets
  ALTER COLUMN storage TYPE jsonb USING
    CASE
      WHEN storage IS NOT NULL THEN jsonb_build_array(jsonb_build_object('size', storage))
      ELSE '[]'::jsonb
    END;

ALTER TABLE assets
  ALTER COLUMN storage SET DEFAULT '[]'::jsonb;

-- ============================================================================
-- 3. Remove legacy ram/storage field_options and add new ones
-- ============================================================================

-- Remove legacy single-value ram and storage options
DELETE FROM field_options WHERE field_name IN ('ram', 'storage');

-- RAM attributes
INSERT INTO field_options (field_name, options, is_required) VALUES
  ('ram_size', '[]', false),
  ('ram_form_factor', '["Desktop", "Laptop"]', false),
  ('ram_ddr_type', '["DDR3", "DDR4", "DDR5"]', false);

-- Storage attributes
INSERT INTO field_options (field_name, options, is_required) VALUES
  ('storage_size', '[]', false),
  ('storage_type', '["NVMe", "SATA", "SAS"]', false);

-- ============================================================================
-- 4. Update asset_request_populate_current_data trigger
-- ============================================================================

CREATE OR REPLACE FUNCTION asset_request_populate_current_data()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  SELECT jsonb_build_object(
    'cpu', cpu,
    'generation', generation,
    'ram', ram,          -- Now JSONB array
    'storage', storage,  -- Now JSONB array
    'serial_number', serial_number,
    'model_number', model_number
  )
  INTO NEW.current_data
  FROM assets
  WHERE id = NEW.asset_id;
  RETURN NEW;
END;
$$;

-- ============================================================================
-- 5. Update approve_and_apply_request function to handle JSONB ram/storage
-- ============================================================================

CREATE OR REPLACE FUNCTION approve_and_apply_request(
  p_request_id uuid,
  p_notes text DEFAULT NULL
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_request record;
  v_new_asset_id uuid;
  v_tag_id text;
  v_reviewer_id uuid;
BEGIN
  -- Get current user as reviewer
  v_reviewer_id := auth.uid();

  -- Fetch the request
  SELECT * INTO v_request
  FROM asset_requests
  WHERE id = p_request_id;

  IF NOT FOUND THEN
    RETURN jsonb_build_object('success', false, 'error', 'Request not found');
  END IF;

  IF v_request.status != 'pending' THEN
    RETURN jsonb_build_object('success', false, 'error', 'Request is not pending');
  END IF;

  -- For create requests, validate tag_id one more time
  IF v_request.request_type = 'create' THEN
    v_tag_id := v_request.request_data->>'tag_id';
    IF EXISTS(SELECT 1 FROM assets WHERE tag_id = v_tag_id) THEN
      -- Auto-reject with note (race condition occurred)
      UPDATE asset_requests SET
        status = 'rejected',
        reviewed_by = v_reviewer_id,
        reviewed_at = now(),
        review_notes = COALESCE(p_notes || ' | ', '') || 'Auto-rejected: Tag ID "' || v_tag_id || '" already exists'
      WHERE id = p_request_id;

      RETURN jsonb_build_object(
        'success', false,
        'error', 'Tag ID already exists - request auto-rejected',
        'auto_rejected', true
      );
    END IF;
  END IF;

  -- Set the user context for audit logging (original requester)
  PERFORM set_config('app.requested_by', v_request.requested_by::text, true);

  -- Apply the changes based on request type
  CASE v_request.request_type
    WHEN 'create' THEN
      INSERT INTO assets (
        tag_id, cpu, generation, ram, storage,
        serial_number, model_number, current_location_id
      )
      VALUES (
        v_tag_id,
        v_request.request_data->>'cpu',
        v_request.request_data->>'generation',
        COALESCE(v_request.request_data->'ram', '[]'::jsonb),
        COALESCE(v_request.request_data->'storage', '[]'::jsonb),
        v_request.request_data->>'serial_number',
        v_request.request_data->>'model_number',
        (v_request.request_data->>'current_location_id')::uuid
      )
      RETURNING id INTO v_new_asset_id;

    WHEN 'update' THEN
      UPDATE assets SET
        cpu = COALESCE(v_request.request_data->>'cpu', cpu),
        generation = COALESCE(v_request.request_data->>'generation', generation),
        ram = COALESCE(v_request.request_data->'ram', ram),
        storage = COALESCE(v_request.request_data->'storage', storage),
        serial_number = COALESCE(v_request.request_data->>'serial_number', serial_number),
        model_number = COALESCE(v_request.request_data->>'model_number', model_number)
      WHERE id = v_request.asset_id;

    WHEN 'delete' THEN
      DELETE FROM assets WHERE id = v_request.asset_id;

    WHEN 'transfer' THEN
      UPDATE assets
      SET current_location_id = (v_request.request_data->>'current_location_id')::uuid
      WHERE id = v_request.asset_id;

  END CASE;

  -- Mark request as approved
  UPDATE asset_requests SET
    status = 'approved',
    reviewed_by = v_reviewer_id,
    reviewed_at = now(),
    review_notes = p_notes
  WHERE id = p_request_id;

  RETURN jsonb_build_object(
    'success', true,
    'asset_id', COALESCE(v_new_asset_id, v_request.asset_id)
  );
END;
$$;

-- migrate:down

-- Restore approve_and_apply_request to TEXT version
CREATE OR REPLACE FUNCTION approve_and_apply_request(
  p_request_id uuid,
  p_notes text DEFAULT NULL
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_request record;
  v_new_asset_id uuid;
  v_tag_id text;
  v_reviewer_id uuid;
BEGIN
  -- Get current user as reviewer
  v_reviewer_id := auth.uid();

  -- Fetch the requestw
  SELECT * INTO v_request
  FROM asset_requests
  WHERE id = p_request_id;

  IF NOT FOUND THEN
    RETURN jsonb_build_object('success', false, 'error', 'Request not found');
  END IF;

  IF v_request.status != 'pending' THEN
    RETURN jsonb_build_object('success', false, 'error', 'Request is not pending');
  END IF;

  -- For create requests, validate tag_id one more time
  IF v_request.request_type = 'create' THEN
    v_tag_id := v_request.request_data->>'tag_id';
    IF EXISTS(SELECT 1 FROM assets WHERE tag_id = v_tag_id) THEN
      -- Auto-reject with note (race condition occurred)
      UPDATE asset_requests SET
        status = 'rejected',
        reviewed_by = v_reviewer_id,
        reviewed_at = now(),
        review_notes = COALESCE(p_notes || ' | ', '') || 'Auto-rejected: Tag ID "' || v_tag_id || '" already exists'
      WHERE id = p_request_id;

      RETURN jsonb_build_object(
        'success', false,
        'error', 'Tag ID already exists - request auto-rejected',
        'auto_rejected', true
      );
    END IF;
  END IF;

  -- Set the user context for audit logging (original requester)
  PERFORM set_config('app.requested_by', v_request.requested_by::text, true);

  -- Apply the changes based on request type
  CASE v_request.request_type
    WHEN 'create' THEN
      INSERT INTO assets (
        tag_id, cpu, generation, ram, storage,
        serial_number, model_number, current_location_id
      )
      VALUES (
        v_tag_id,
        v_request.request_data->>'cpu',
        v_request.request_data->>'generation',
        v_request.request_data->>'ram',
        v_request.request_data->>'storage',
        v_request.request_data->>'serial_number',
        v_request.request_data->>'model_number',
        (v_request.request_data->>'current_location_id')::uuid
      )
      RETURNING id INTO v_new_asset_id;

    WHEN 'update' THEN
      UPDATE assets SET
        cpu = COALESCE(v_request.request_data->>'cpu', cpu),
        generation = COALESCE(v_request.request_data->>'generation', generation),
        ram = COALESCE(v_request.request_data->>'ram', ram),
        storage = COALESCE(v_request.request_data->>'storage', storage),
        serial_number = COALESCE(v_request.request_data->>'serial_number', serial_number),
        model_number = COALESCE(v_request.request_data->>'model_number', model_number)
      WHERE id = v_request.asset_id;

    WHEN 'delete' THEN
      DELETE FROM assets WHERE id = v_request.asset_id;

    WHEN 'transfer' THEN
      UPDATE assets
      SET current_location_id = (v_request.request_data->>'current_location_id')::uuid
      WHERE id = v_request.asset_id;

  END CASE;

  -- Mark request as approved
  UPDATE asset_requests SET
    status = 'approved',
    reviewed_by = v_reviewer_id,
    reviewed_at = now(),
    review_notes = p_notes
  WHERE id = p_request_id;

  RETURN jsonb_build_object(
    'success', true,
    'asset_id', COALESCE(v_new_asset_id, v_request.asset_id)
  );
END;
$$;

-- Restore original trigger function
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

-- Remove new field_options
DELETE FROM field_options WHERE field_name IN (
  'ram_size', 'ram_form_factor', 'ram_ddr_type',
  'storage_size', 'storage_type'
);

-- Restore legacy ram and storage field_options
INSERT INTO field_options (field_name, options, is_required) VALUES
  ('ram', '[]', false),
  ('storage', '[]', false);

-- Convert ram back to TEXT
ALTER TABLE assets
  ALTER COLUMN ram DROP DEFAULT;

ALTER TABLE assets
  ALTER COLUMN ram TYPE text USING
    CASE
      WHEN jsonb_array_length(ram) > 0 THEN ram->0->>'size'
      ELSE NULL
    END;

-- Convert storage back to TEXT
ALTER TABLE assets
  ALTER COLUMN storage DROP DEFAULT;

ALTER TABLE assets
  ALTER COLUMN storage TYPE text USING
    CASE
      WHEN jsonb_array_length(storage) > 0 THEN storage->0->>'size'
      ELSE NULL
    END;
