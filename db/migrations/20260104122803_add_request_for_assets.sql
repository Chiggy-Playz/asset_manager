-- migrate:up

-- ============================================================================
-- 1. Modify assets table: Change tag_id from auto-generated int to user-input string
-- ============================================================================

-- Drop the existing tag_id column and recreate as text
ALTER TABLE assets DROP COLUMN tag_id;
ALTER TABLE assets ADD COLUMN tag_id text NOT NULL UNIQUE;

-- ============================================================================
-- 2. Create field_options table for admin-configurable field values
-- ============================================================================

CREATE TABLE field_options (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  field_name text NOT NULL UNIQUE,  -- 'cpu', 'generation', 'ram', 'storage', 'model'
  options jsonb NOT NULL DEFAULT '[]',  -- e.g., ['4GB', '8GB', '16GB']
  is_required boolean NOT NULL DEFAULT false,
  display_order int NOT NULL DEFAULT 0,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

ALTER TABLE field_options ENABLE ROW LEVEL SECURITY;

-- Everyone can read field options
CREATE POLICY "Anyone can read field_options"
ON field_options FOR SELECT
USING (true);

-- Only admins can modify field options
CREATE POLICY "Admins can insert field_options"
ON field_options FOR INSERT
WITH CHECK (is_admin());

CREATE POLICY "Admins can update field_options"
ON field_options FOR UPDATE
USING (is_admin());

CREATE POLICY "Admins can delete field_options"
ON field_options FOR DELETE
USING (is_admin());

-- Seed default field options (empty arrays, admin will populate later)
INSERT INTO field_options (field_name, display_order) VALUES
  ('cpu', 1),
  ('generation', 2),
  ('ram', 3),
  ('storage', 4),
  ('model', 5);

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_field_options_updated_at()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$;

-- Trigger to update updated_at
CREATE TRIGGER field_options_updated_at
  BEFORE UPDATE ON field_options
  FOR EACH ROW
  EXECUTE FUNCTION update_field_options_updated_at();

-- ============================================================================
-- 3. Create asset_requests table for user modification requests
-- ============================================================================

CREATE TABLE asset_requests (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  asset_id uuid REFERENCES assets(id) ON DELETE CASCADE,  -- null for create requests
  request_type text NOT NULL CHECK (request_type IN ('create', 'update', 'delete', 'transfer')),
  request_data jsonb NOT NULL,  -- proposed changes
  requested_by uuid REFERENCES profiles(id) ON DELETE SET NULL,
  requested_at timestamptz DEFAULT now(),
  status text NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected')),
  reviewed_by uuid REFERENCES profiles(id) ON DELETE SET NULL,
  reviewed_at timestamptz,
  review_notes text
);

CREATE INDEX ON asset_requests (requested_by);
CREATE INDEX ON asset_requests (status);
CREATE INDEX ON asset_requests (requested_at);

ALTER TABLE asset_requests ENABLE ROW LEVEL SECURITY;

-- Users can see their own requests, admins can see all
CREATE POLICY "Users can read own requests"
ON asset_requests FOR SELECT
USING (
  (select auth.uid()) = requested_by
  OR is_admin()
);

-- Authenticated users can create requests
CREATE POLICY "Users can create requests"
ON asset_requests FOR INSERT
WITH CHECK ((select auth.uid()) IS NOT NULL AND (select auth.uid()) = requested_by);

-- Only admins can update requests (approve/reject)
CREATE POLICY "Admins can update requests"
ON asset_requests FOR UPDATE
USING (is_admin());

-- Users can't delete requests, admins can
CREATE POLICY "Admins can delete requests"
ON asset_requests FOR DELETE
USING (is_admin());

-- ============================================================================
-- 4. Update RLS Policies on assets: Only admins can directly modify
-- ============================================================================

-- Drop existing user modification policies
DROP POLICY "Authenticated users can insert assets" ON assets;
DROP POLICY "Authenticated users can update assets" ON assets;
DROP POLICY "Authenticated users can delete assets" ON assets;

-- Create admin-only modification policies
CREATE POLICY "Admins can insert assets"
ON assets FOR INSERT
WITH CHECK (is_admin());

CREATE POLICY "Admins can update assets"
ON assets FOR UPDATE
USING (is_admin());

CREATE POLICY "Admins can delete assets"
ON assets FOR DELETE
USING (is_admin());

-- ============================================================================
-- 5. Trigger for auto-applying approved requests
-- ============================================================================

CREATE OR REPLACE FUNCTION apply_approved_request()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_tag_id text;
  v_cpu text;
  v_generation text;
  v_ram text;
  v_storage text;
  v_serial_number text;
  v_model_number text;
  v_current_location_id uuid;
BEGIN
  -- Only process when status changes from 'pending' to 'approved'
  IF NEW.status = 'approved' AND OLD.status = 'pending' THEN
    -- Set reviewed_at timestamp
    NEW.reviewed_at = now();

    CASE NEW.request_type
      WHEN 'create' THEN
        -- Extract values from request_data
        v_tag_id := NEW.request_data->>'tag_id';
        v_cpu := NEW.request_data->>'cpu';
        v_generation := NEW.request_data->>'generation';
        v_ram := NEW.request_data->>'ram';
        v_storage := NEW.request_data->>'storage';
        v_serial_number := NEW.request_data->>'serial_number';
        v_model_number := NEW.request_data->>'model_number';
        v_current_location_id := (NEW.request_data->>'current_location_id')::uuid;

        INSERT INTO assets (tag_id, cpu, generation, ram, storage, serial_number, model_number, current_location_id)
        VALUES (v_tag_id, v_cpu, v_generation, v_ram, v_storage, v_serial_number, v_model_number, v_current_location_id);

      WHEN 'update' THEN
        UPDATE assets SET
          cpu = COALESCE(NEW.request_data->>'cpu', cpu),
          generation = COALESCE(NEW.request_data->>'generation', generation),
          ram = COALESCE(NEW.request_data->>'ram', ram),
          storage = COALESCE(NEW.request_data->>'storage', storage),
          serial_number = COALESCE(NEW.request_data->>'serial_number', serial_number),
          model_number = COALESCE(NEW.request_data->>'model_number', model_number)
        WHERE id = NEW.asset_id;

      WHEN 'delete' THEN
        DELETE FROM assets WHERE id = NEW.asset_id;

      WHEN 'transfer' THEN
        v_current_location_id := (NEW.request_data->>'current_location_id')::uuid;
        UPDATE assets SET current_location_id = v_current_location_id
        WHERE id = NEW.asset_id;

    END CASE;
  END IF;

  -- Also set reviewed_at when rejecting
  IF NEW.status = 'rejected' AND OLD.status = 'pending' THEN
    NEW.reviewed_at = now();
  END IF;

  RETURN NEW;
END;
$$;

CREATE TRIGGER on_request_status_change
  BEFORE UPDATE ON asset_requests
  FOR EACH ROW
  EXECUTE FUNCTION apply_approved_request();

-- migrate:down

DROP TRIGGER on_request_status_change ON asset_requests;
DROP FUNCTION apply_approved_request();

DROP POLICY "Admins can delete requests" ON asset_requests;
DROP POLICY "Admins can update requests" ON asset_requests;
DROP POLICY "Users can create requests" ON asset_requests;
DROP POLICY "Users can read own requests" ON asset_requests;
DROP TABLE asset_requests;

DROP TRIGGER field_options_updated_at ON field_options;
DROP POLICY "Admins can delete field_options" ON field_options;
DROP POLICY "Admins can update field_options" ON field_options;
DROP POLICY "Admins can insert field_options" ON field_options;
DROP POLICY "Anyone can read field_options" ON field_options;
DROP TABLE field_options;

DROP POLICY "Admins can delete assets" ON assets;
DROP POLICY "Admins can update assets" ON assets;
DROP POLICY "Admins can insert assets" ON assets;

-- Restore original user policies
CREATE POLICY "Authenticated users can insert assets"
ON assets FOR INSERT
WITH CHECK (auth.uid() IS NOT NULL);

CREATE POLICY "Authenticated users can update assets"
ON assets FOR UPDATE
USING (auth.uid() IS NOT NULL);

CREATE POLICY "Authenticated users can delete assets"
ON assets FOR DELETE
USING (auth.uid() IS NOT NULL);

-- Restore tag_id as auto-generated int
ALTER TABLE assets DROP COLUMN tag_id;
ALTER TABLE assets ADD COLUMN tag_id int GENERATED ALWAYS AS IDENTITY UNIQUE;
