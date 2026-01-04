-- migrate:up

-- ============================================================================
-- 1. Modify Audit Trigger to Support User Override
-- ============================================================================

CREATE OR REPLACE FUNCTION log_asset_changes()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_user_id uuid;
BEGIN
  -- Check for override user (set by approve_and_apply_request)
  v_user_id := NULLIF(current_setting('app.requested_by', true), '')::uuid;

  -- Fall back to current auth user
  IF v_user_id IS NULL THEN
    v_user_id := auth.uid();
  END IF;

  IF tg_op = 'INSERT' THEN
    INSERT INTO asset_audit_logs (asset_id, user_id, action, new_values)
    VALUES (new.id, v_user_id, 'created', to_jsonb(new));
    RETURN new;
  ELSIF tg_op = 'UPDATE' THEN
    IF old.current_location_id IS DISTINCT FROM new.current_location_id THEN
      INSERT INTO asset_audit_logs (asset_id, user_id, action, old_values, new_values)
      VALUES (new.id, v_user_id, 'transferred', to_jsonb(old), to_jsonb(new));
    ELSE
      INSERT INTO asset_audit_logs (asset_id, user_id, action, old_values, new_values)
      VALUES (new.id, v_user_id, 'updated', to_jsonb(old), to_jsonb(new));
    END IF;
    RETURN new;
  ELSIF tg_op = 'DELETE' THEN
    INSERT INTO asset_audit_logs (asset_id, user_id, action, old_values)
    VALUES (old.id, v_user_id, 'deleted', to_jsonb(old));
    RETURN old;
  END IF;
  RETURN null;
END;
$$;

-- ============================================================================
-- 2. Create Validation RPC for Tag ID Uniqueness
-- ============================================================================

CREATE OR REPLACE FUNCTION validate_tag_id(p_tag_id text, p_exclude_asset_id uuid DEFAULT NULL)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_exists_in_assets boolean;
  v_exists_in_requests boolean;
BEGIN
  -- Check if tag_id exists in assets table
  SELECT EXISTS(
    SELECT 1 FROM assets
    WHERE tag_id = p_tag_id
    AND (p_exclude_asset_id IS NULL OR id != p_exclude_asset_id)
  ) INTO v_exists_in_assets;

  -- Check if tag_id exists in pending create requests
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

-- ============================================================================
-- 3. Create Combined Approve & Apply RPC
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

-- ============================================================================
-- 4. Create Reject RPC
-- ============================================================================

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

-- migrate:down

DROP FUNCTION IF EXISTS reject_request(uuid, text);
DROP FUNCTION IF EXISTS approve_and_apply_request(uuid, text);
DROP FUNCTION IF EXISTS validate_tag_id(text, uuid);

-- Restore original log_asset_changes function (without user override)
CREATE OR REPLACE FUNCTION log_asset_changes()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  IF tg_op = 'INSERT' THEN
    INSERT INTO asset_audit_logs (asset_id, user_id, action, new_values)
    VALUES (new.id, auth.uid(), 'created', to_jsonb(new));
    RETURN new;
  ELSIF tg_op = 'UPDATE' THEN
    IF old.current_location_id IS DISTINCT FROM new.current_location_id THEN
      INSERT INTO asset_audit_logs (asset_id, user_id, action, old_values, new_values)
      VALUES (new.id, auth.uid(), 'transferred', to_jsonb(old), to_jsonb(new));
    ELSE
      INSERT INTO asset_audit_logs (asset_id, user_id, action, old_values, new_values)
      VALUES (new.id, auth.uid(), 'updated', to_jsonb(old), to_jsonb(new));
    END IF;
    RETURN new;
  END IF;
  RETURN null;
END;
$$;
