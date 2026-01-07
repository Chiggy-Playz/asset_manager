-- migrate:up

-- Fix the audit log trigger for DELETE operations.
-- The issue: When an asset is deleted, the AFTER DELETE trigger tries to INSERT
-- into asset_audit_logs with asset_id = OLD.id, but the asset no longer exists,
-- causing a foreign key constraint violation.
--
-- Solution: For DELETE operations, insert with asset_id = NULL since the asset
-- is gone anyway. All asset data is preserved in old_values JSONB.

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

-- migrate:down

-- Restore the previous version that tries to use old.id (which causes the FK error)
CREATE OR REPLACE FUNCTION log_asset_changes()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_user_id uuid;
BEGIN
  v_user_id := NULLIF(current_setting('app.requested_by', true), '')::uuid;

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
