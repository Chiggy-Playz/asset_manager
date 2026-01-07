-- migrate:up
-- Add request_id column to asset_audit_logs table
-- This allows linking audit log entries to the request that triggered the change

ALTER TABLE asset_audit_logs
ADD COLUMN request_id uuid REFERENCES asset_requests(id) ON DELETE SET NULL;

-- Create index for efficient lookups
CREATE INDEX asset_audit_logs_request_id_idx ON asset_audit_logs(request_id);

-- Update the approve_and_apply_request function to pass request_id to the trigger
CREATE OR REPLACE FUNCTION public.approve_and_apply_request(p_request_id uuid, p_notes text DEFAULT NULL::text) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
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

  -- Set context variables for the trigger
  PERFORM set_config('app.requested_by', v_request.requested_by::text, true);
  PERFORM set_config('app.request_id', p_request_id::text, true);

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

-- Update the log_asset_changes trigger to capture request_id
CREATE OR REPLACE FUNCTION public.log_asset_changes() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE
  v_user_id uuid;
  v_request_id uuid;
BEGIN
  -- Check for override user (set by approve_and_apply_request)
  v_user_id := NULLIF(current_setting('app.requested_by', true), '')::uuid;

  -- Check for request_id (set by approve_and_apply_request)
  v_request_id := NULLIF(current_setting('app.request_id', true), '')::uuid;

  -- Fall back to current auth user
  IF v_user_id IS NULL THEN
    v_user_id := auth.uid();
  END IF;

  IF tg_op = 'INSERT' THEN
    INSERT INTO asset_audit_logs (asset_id, user_id, action, new_values, request_id)
    VALUES (new.id, v_user_id, 'created', to_jsonb(new), v_request_id);
    RETURN new;
  ELSIF tg_op = 'UPDATE' THEN
    IF old.current_location_id IS DISTINCT FROM new.current_location_id THEN
      INSERT INTO asset_audit_logs (asset_id, user_id, action, old_values, new_values, request_id)
      VALUES (new.id, v_user_id, 'transferred', to_jsonb(old), to_jsonb(new), v_request_id);
    ELSE
      INSERT INTO asset_audit_logs (asset_id, user_id, action, old_values, new_values, request_id)
      VALUES (new.id, v_user_id, 'updated', to_jsonb(old), to_jsonb(new), v_request_id);
    END IF;
    RETURN new;
  ELSIF tg_op = 'DELETE' THEN
    -- Use NULL for asset_id since the asset is being deleted.
    -- The original asset ID and all data is preserved in old_values.
    INSERT INTO asset_audit_logs (asset_id, user_id, action, old_values, request_id)
    VALUES (NULL, v_user_id, 'deleted', to_jsonb(old), v_request_id);
    RETURN old;
  END IF;
  RETURN null;
END;
$$;


-- migrate:down

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
    -- Use NULL for asset_id since the asset is being deleted.
    -- The original asset ID and all data is preserved in old_values.
    INSERT INTO asset_audit_logs (asset_id, user_id, action, old_values)
    VALUES (NULL, v_user_id, 'deleted', to_jsonb(old));
    RETURN old;
  END IF;
  RETURN null;
END;
$$;


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

DROP INDEX IF EXISTS asset_audit_logs_request_id_idx;

ALTER TABLE asset_audit_logs
DROP COLUMN IF EXISTS request_id;