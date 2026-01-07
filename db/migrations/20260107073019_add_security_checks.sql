-- migrate:up

-- ============================================================================
-- SECURITY FIX: Add authentication checks to SECURITY DEFINER functions
-- Prevent anonymous users from calling these functions
-- ============================================================================

-- Fix validate_tag_id: Add auth check
CREATE OR REPLACE FUNCTION validate_tag_id(p_tag_id text, p_exclude_asset_id uuid DEFAULT NULL)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_exists_in_assets boolean;
  v_exists_in_requests boolean;
BEGIN
  -- Require authentication
  IF auth.uid() IS NULL THEN
    RETURN jsonb_build_object('success', false, 'error', 'Authentication required');
  END IF;

  SELECT EXISTS(
    SELECT 1 FROM assets
    WHERE tag_id = p_tag_id
    AND (p_exclude_asset_id IS NULL OR id != p_exclude_asset_id)
  ) INTO v_exists_in_assets;

  SELECT EXISTS(
    SELECT 1 FROM asset_requests
    WHERE request_type = 'create'
    AND status = 'pending'
    AND request_data->>'tag_id' = p_tag_id
  ) INTO v_exists_in_requests;

  RETURN jsonb_build_object(
    'valid', NOT (v_exists_in_assets OR v_exists_in_requests),
    'exists_in_assets', v_exists_in_assets,
    'exists_in_pending_requests', v_exists_in_requests
  );
END;
$$;

-- Fix approve_and_apply_request: Add auth check
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
  -- Require authentication
  IF auth.uid() IS NULL THEN
    RETURN jsonb_build_object('success', false, 'error', 'Authentication required');
  END IF;

  v_reviewer_id := auth.uid();

  SELECT * INTO v_request
  FROM asset_requests
  WHERE id = p_request_id;

  IF NOT FOUND THEN
    RETURN jsonb_build_object('success', false, 'error', 'Request not found');
  END IF;

  IF v_request.status != 'pending' THEN
    RETURN jsonb_build_object('success', false, 'error', 'Request is not pending');
  END IF;

  IF v_request.request_type = 'create' THEN
    v_tag_id := v_request.request_data->>'tag_id';
    IF EXISTS(SELECT 1 FROM assets WHERE tag_id = v_tag_id) THEN
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

  PERFORM set_config('app.requested_by', v_request.requested_by::text, true);

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

-- Fix reject_request: Add auth check
CREATE OR REPLACE FUNCTION reject_request(
  p_request_id uuid,
  p_notes text DEFAULT NULL
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_reviewer_id uuid;
BEGIN
  -- Require authentication
  IF auth.uid() IS NULL THEN
    RETURN jsonb_build_object('success', false, 'error', 'Authentication required');
  END IF;

  v_reviewer_id := auth.uid();

  UPDATE asset_requests SET
    status = 'rejected',
    reviewed_by = v_reviewer_id,
    reviewed_at = now(),
    review_notes = p_notes
  WHERE id = p_request_id AND status = 'pending';

  IF NOT FOUND THEN
    RETURN jsonb_build_object('success', false, 'error', 'Request not found or not pending');
  END IF;

  RETURN jsonb_build_object('success', true);
END;
$$;

-- migrate:down

-- Restore validate_tag_id without auth check
CREATE OR REPLACE FUNCTION validate_tag_id(p_tag_id text, p_exclude_asset_id uuid DEFAULT NULL)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_exists_in_assets boolean;
  v_exists_in_requests boolean;
BEGIN
  SELECT EXISTS(
    SELECT 1 FROM assets
    WHERE tag_id = p_tag_id
    AND (p_exclude_asset_id IS NULL OR id != p_exclude_asset_id)
  ) INTO v_exists_in_assets;

  SELECT EXISTS(
    SELECT 1 FROM asset_requests
    WHERE request_type = 'create'
    AND status = 'pending'
    AND request_data->>'tag_id' = p_tag_id
  ) INTO v_exists_in_requests;

  RETURN jsonb_build_object(
    'valid', NOT (v_exists_in_assets OR v_exists_in_requests),
    'exists_in_assets', v_exists_in_assets,
    'exists_in_pending_requests', v_exists_in_requests
  );
END;
$$;

-- Restore approve_and_apply_request without auth check
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
  v_reviewer_id := auth.uid();

  SELECT * INTO v_request
  FROM asset_requests
  WHERE id = p_request_id;

  IF NOT FOUND THEN
    RETURN jsonb_build_object('success', false, 'error', 'Request not found');
  END IF;

  IF v_request.status != 'pending' THEN
    RETURN jsonb_build_object('success', false, 'error', 'Request is not pending');
  END IF;

  IF v_request.request_type = 'create' THEN
    v_tag_id := v_request.request_data->>'tag_id';
    IF EXISTS(SELECT 1 FROM assets WHERE tag_id = v_tag_id) THEN
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

  PERFORM set_config('app.requested_by', v_request.requested_by::text, true);

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

-- Restore reject_request without auth check
CREATE OR REPLACE FUNCTION reject_request(
  p_request_id uuid,
  p_notes text DEFAULT NULL
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_reviewer_id uuid;
BEGIN
  v_reviewer_id := auth.uid();

  UPDATE asset_requests SET
    status = 'rejected',
    reviewed_by = v_reviewer_id,
    reviewed_at = now(),
    review_notes = p_notes
  WHERE id = p_request_id AND status = 'pending';

  IF NOT FOUND THEN
    RETURN jsonb_build_object('success', false, 'error', 'Request not found or not pending');
  END IF;

  RETURN jsonb_build_object('success', true);
END;
$$;
