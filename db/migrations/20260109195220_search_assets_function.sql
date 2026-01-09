-- migrate:up

-- ============================================================================
-- Helper function: Parse size string to GB (e.g., "8GB" -> 8, "1TB" -> 1024)
-- ============================================================================
CREATE OR REPLACE FUNCTION parse_size_to_gb(size_str TEXT)
RETURNS INT AS $$
DECLARE
  cleaned_str TEXT;
  num_part TEXT;
  unit_part TEXT;
  size_val INT;
BEGIN
  IF size_str IS NULL OR size_str = '' THEN
    RETURN 0;
  END IF;

  -- Strip spaces from the input
  cleaned_str := regexp_replace(size_str, '\s', '', 'g');

  -- Extract numeric part and unit part
  num_part := regexp_replace(cleaned_str, '[^0-9.]', '', 'g');
  unit_part := upper(regexp_replace(cleaned_str, '[0-9.]', '', 'g'));

  IF num_part = '' THEN
    RETURN 0;
  END IF;

  size_val := num_part::INT;

  -- Convert to GB based on unit
  CASE unit_part
    WHEN 'TB' THEN RETURN size_val * 1024;
    WHEN 'GB' THEN RETURN size_val;
    WHEN 'MB' THEN RETURN size_val / 1024;
    ELSE RETURN size_val; -- Assume GB if no unit
  END CASE;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- ============================================================================
-- Helper function: Calculate total RAM from JSONB array
-- ============================================================================
CREATE OR REPLACE FUNCTION calculate_total_ram(ram_jsonb JSONB)
RETURNS INT AS $$
DECLARE
  total INT := 0;
  module JSONB;
BEGIN
  IF ram_jsonb IS NULL OR jsonb_array_length(ram_jsonb) = 0 THEN
    RETURN 0;
  END IF;

  FOR module IN SELECT * FROM jsonb_array_elements(ram_jsonb)
  LOOP
    total := total + parse_size_to_gb(module->>'size');
  END LOOP;

  RETURN total;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- ============================================================================
-- Helper function: Calculate total storage from JSONB array
-- ============================================================================
CREATE OR REPLACE FUNCTION calculate_total_storage(storage_jsonb JSONB)
RETURNS INT AS $$
DECLARE
  total INT := 0;
  device JSONB;
BEGIN
  IF storage_jsonb IS NULL OR jsonb_array_length(storage_jsonb) = 0 THEN
    RETURN 0;
  END IF;

  FOR device IN SELECT * FROM jsonb_array_elements(storage_jsonb)
  LOOP
    total := total + parse_size_to_gb(device->>'size');
  END LOOP;

  RETURN total;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- ============================================================================
-- Helper function: Check if RAM contains any of the specified DDR types
-- ============================================================================
CREATE OR REPLACE FUNCTION ram_has_ddr_type(ram_jsonb JSONB, ddr_types TEXT[])
RETURNS BOOLEAN AS $$
DECLARE
  module JSONB;
BEGIN
  IF ram_jsonb IS NULL OR jsonb_array_length(ram_jsonb) = 0 THEN
    RETURN FALSE;
  END IF;

  IF ddr_types IS NULL OR array_length(ddr_types, 1) IS NULL THEN
    RETURN TRUE;
  END IF;

  FOR module IN SELECT * FROM jsonb_array_elements(ram_jsonb)
  LOOP
    IF module->>'ddrType' = ANY(ddr_types) THEN
      RETURN TRUE;
    END IF;
  END LOOP;

  RETURN FALSE;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- ============================================================================
-- Helper function: Check if RAM contains any of the specified form factors
-- ============================================================================
CREATE OR REPLACE FUNCTION ram_has_form_factor(ram_jsonb JSONB, form_factors TEXT[])
RETURNS BOOLEAN AS $$
DECLARE
  module JSONB;
BEGIN
  IF ram_jsonb IS NULL OR jsonb_array_length(ram_jsonb) = 0 THEN
    RETURN FALSE;
  END IF;

  IF form_factors IS NULL OR array_length(form_factors, 1) IS NULL THEN
    RETURN TRUE;
  END IF;

  FOR module IN SELECT * FROM jsonb_array_elements(ram_jsonb)
  LOOP
    IF module->>'formFactor' = ANY(form_factors) THEN
      RETURN TRUE;
    END IF;
  END LOOP;

  RETURN FALSE;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- ============================================================================
-- Helper function: Check if storage contains any of the specified types
-- ============================================================================
CREATE OR REPLACE FUNCTION storage_has_type(storage_jsonb JSONB, storage_types TEXT[])
RETURNS BOOLEAN AS $$
DECLARE
  device JSONB;
BEGIN
  IF storage_jsonb IS NULL OR jsonb_array_length(storage_jsonb) = 0 THEN
    RETURN FALSE;
  END IF;

  IF storage_types IS NULL OR array_length(storage_types, 1) IS NULL THEN
    RETURN TRUE;
  END IF;

  FOR device IN SELECT * FROM jsonb_array_elements(storage_jsonb)
  LOOP
    IF device->>'type' = ANY(storage_types) THEN
      RETURN TRUE;
    END IF;
  END LOOP;

  RETURN FALSE;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- ============================================================================
-- Helper function: Get all descendant location IDs (including self)
-- ============================================================================
CREATE OR REPLACE FUNCTION get_location_with_descendants(location_ids UUID[])
RETURNS UUID[] AS $$
DECLARE
  result UUID[];
BEGIN
  IF location_ids IS NULL OR array_length(location_ids, 1) IS NULL THEN
    RETURN NULL;
  END IF;

  WITH RECURSIVE location_tree AS (
    -- Base case: selected locations
    SELECT id FROM locations WHERE id = ANY(location_ids)
    UNION ALL
    -- Recursive case: children
    SELECT l.id
    FROM locations l
    INNER JOIN location_tree lt ON l.parent_id = lt.id
  )
  SELECT array_agg(id) INTO result FROM location_tree;

  RETURN result;
END;
$$ LANGUAGE plpgsql STABLE;

-- ============================================================================
-- Main search function
-- ============================================================================
CREATE OR REPLACE FUNCTION search_assets(
  p_filters JSONB,
  p_page_size INT DEFAULT 25,
  p_page_offset INT DEFAULT 0,
  p_count_only BOOLEAN DEFAULT FALSE
)
RETURNS TABLE (
  id UUID,
  tag_id TEXT,
  serial_number TEXT,
  model_number TEXT,
  asset_type TEXT,
  cpu TEXT,
  generation TEXT,
  ram JSONB,
  storage JSONB,
  current_location_id UUID,
  created_at TIMESTAMPTZ,
  updated_at TIMESTAMPTZ,
  location_name TEXT,
  total_count BIGINT
) AS $$
DECLARE
  -- Text filters
  v_tag_id TEXT;
  v_serial_number TEXT;
  v_model_number TEXT;

  -- Multi-select filters
  v_asset_types TEXT[];
  v_cpus TEXT[];
  v_generations TEXT[];

  -- RAM filters
  v_ram_size INT;
  v_ram_operator TEXT;
  v_ram_types TEXT[];
  v_ram_form_factors TEXT[];

  -- Storage filters
  v_storage_size INT;
  v_storage_operator TEXT;
  v_storage_types TEXT[];

  -- Location filter
  v_location_ids UUID[];
  v_expanded_location_ids UUID[];

  -- Count
  v_total_count BIGINT;
BEGIN
  -- ============================================================================
  -- SECURITY CHECK: Require authentication
  -- ============================================================================
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Authentication required';
  END IF;

  -- Parse text filters
  v_tag_id := p_filters->>'tag_id';
  v_serial_number := p_filters->>'serial_number';
  v_model_number := p_filters->>'model_number';

  -- Parse multi-select filters (convert JSONB arrays to TEXT arrays)
  IF p_filters->'asset_types' IS NOT NULL AND jsonb_array_length(p_filters->'asset_types') > 0 THEN
    SELECT array_agg(elem::TEXT) INTO v_asset_types
    FROM jsonb_array_elements_text(p_filters->'asset_types') AS elem;
  END IF;

  IF p_filters->'cpus' IS NOT NULL AND jsonb_array_length(p_filters->'cpus') > 0 THEN
    SELECT array_agg(elem::TEXT) INTO v_cpus
    FROM jsonb_array_elements_text(p_filters->'cpus') AS elem;
  END IF;

  IF p_filters->'generations' IS NOT NULL AND jsonb_array_length(p_filters->'generations') > 0 THEN
    SELECT array_agg(elem::TEXT) INTO v_generations
    FROM jsonb_array_elements_text(p_filters->'generations') AS elem;
  END IF;

  -- Parse RAM filters
  IF p_filters->>'ram_size' IS NOT NULL AND p_filters->>'ram_size' != '' THEN
    v_ram_size := (p_filters->>'ram_size')::INT;
  END IF;
  v_ram_operator := p_filters->>'ram_operator';

  IF p_filters->'ram_types' IS NOT NULL AND jsonb_array_length(p_filters->'ram_types') > 0 THEN
    SELECT array_agg(elem::TEXT) INTO v_ram_types
    FROM jsonb_array_elements_text(p_filters->'ram_types') AS elem;
  END IF;

  IF p_filters->'ram_form_factors' IS NOT NULL AND jsonb_array_length(p_filters->'ram_form_factors') > 0 THEN
    SELECT array_agg(elem::TEXT) INTO v_ram_form_factors
    FROM jsonb_array_elements_text(p_filters->'ram_form_factors') AS elem;
  END IF;

  -- Parse storage filters
  IF p_filters->>'storage_size' IS NOT NULL AND p_filters->>'storage_size' != '' THEN
    v_storage_size := (p_filters->>'storage_size')::INT;
  END IF;
  v_storage_operator := p_filters->>'storage_operator';

  IF p_filters->'storage_types' IS NOT NULL AND jsonb_array_length(p_filters->'storage_types') > 0 THEN
    SELECT array_agg(elem::TEXT) INTO v_storage_types
    FROM jsonb_array_elements_text(p_filters->'storage_types') AS elem;
  END IF;

  -- Parse location filter and expand to include descendants
  IF p_filters->'location_ids' IS NOT NULL AND jsonb_array_length(p_filters->'location_ids') > 0 THEN
    SELECT array_agg(elem::UUID) INTO v_location_ids
    FROM jsonb_array_elements_text(p_filters->'location_ids') AS elem;
    v_expanded_location_ids := get_location_with_descendants(v_location_ids);
  END IF;

  -- Get total count first
  SELECT COUNT(*) INTO v_total_count
  FROM assets a
  LEFT JOIN locations l ON a.current_location_id = l.id
  WHERE
    -- Text filters (partial match)
    (v_tag_id IS NULL OR a.tag_id::TEXT ILIKE '%' || v_tag_id || '%')
    AND (v_serial_number IS NULL OR a.serial_number ILIKE '%' || v_serial_number || '%')
    AND (v_model_number IS NULL OR a.model_number ILIKE '%' || v_model_number || '%')

    -- Multi-select filters
    AND (v_asset_types IS NULL OR a.asset_type = ANY(v_asset_types))
    AND (v_cpus IS NULL OR a.cpu = ANY(v_cpus))
    AND (v_generations IS NULL OR a.generation = ANY(v_generations))

    -- RAM size filter
    AND (
      v_ram_size IS NULL
      OR (
        CASE v_ram_operator
          WHEN '>' THEN calculate_total_ram(a.ram) > v_ram_size
          WHEN '<' THEN calculate_total_ram(a.ram) < v_ram_size
          WHEN '>=' THEN calculate_total_ram(a.ram) >= v_ram_size
          WHEN '<=' THEN calculate_total_ram(a.ram) <= v_ram_size
          WHEN '=' THEN calculate_total_ram(a.ram) = v_ram_size
          ELSE TRUE
        END
      )
    )

    -- RAM type filter
    AND (v_ram_types IS NULL OR ram_has_ddr_type(a.ram, v_ram_types))

    -- RAM form factor filter
    AND (v_ram_form_factors IS NULL OR ram_has_form_factor(a.ram, v_ram_form_factors))

    -- Storage size filter
    AND (
      v_storage_size IS NULL
      OR (
        CASE v_storage_operator
          WHEN '>' THEN calculate_total_storage(a.storage) > v_storage_size
          WHEN '<' THEN calculate_total_storage(a.storage) < v_storage_size
          WHEN '>=' THEN calculate_total_storage(a.storage) >= v_storage_size
          WHEN '<=' THEN calculate_total_storage(a.storage) <= v_storage_size
          WHEN '=' THEN calculate_total_storage(a.storage) = v_storage_size
          ELSE TRUE
        END
      )
    )

    -- Storage type filter
    AND (v_storage_types IS NULL OR storage_has_type(a.storage, v_storage_types))

    -- Location filter (includes descendants)
    AND (v_expanded_location_ids IS NULL OR a.current_location_id = ANY(v_expanded_location_ids));

  -- If count only, return just the count
  IF p_count_only THEN
    RETURN QUERY SELECT
      NULL::UUID,
      NULL::TEXT,
      NULL::TEXT,
      NULL::TEXT,
      NULL::TEXT,
      NULL::TEXT,
      NULL::TEXT,
      NULL::JSONB,
      NULL::JSONB,
      NULL::UUID,
      NULL::TIMESTAMPTZ,
      NULL::TIMESTAMPTZ,
      NULL::TEXT,
      v_total_count;
    RETURN;
  END IF;

  -- Return paginated results with total count
  RETURN QUERY
  SELECT
    a.id,
    a.tag_id,
    a.serial_number,
    a.model_number,
    a.asset_type,
    a.cpu,
    a.generation,
    a.ram,
    a.storage,
    a.current_location_id,
    a.created_at,
    a.updated_at,
    l.name AS location_name,
    v_total_count
  FROM assets a
  LEFT JOIN locations l ON a.current_location_id = l.id
  WHERE
    -- Text filters (partial match)
    (v_tag_id IS NULL OR a.tag_id::TEXT ILIKE '%' || v_tag_id || '%')
    AND (v_serial_number IS NULL OR a.serial_number ILIKE '%' || v_serial_number || '%')
    AND (v_model_number IS NULL OR a.model_number ILIKE '%' || v_model_number || '%')

    -- Multi-select filters
    AND (v_asset_types IS NULL OR a.asset_type = ANY(v_asset_types))
    AND (v_cpus IS NULL OR a.cpu = ANY(v_cpus))
    AND (v_generations IS NULL OR a.generation = ANY(v_generations))

    -- RAM size filter
    AND (
      v_ram_size IS NULL
      OR (
        CASE v_ram_operator
          WHEN '>' THEN calculate_total_ram(a.ram) > v_ram_size
          WHEN '<' THEN calculate_total_ram(a.ram) < v_ram_size
          WHEN '>=' THEN calculate_total_ram(a.ram) >= v_ram_size
          WHEN '<=' THEN calculate_total_ram(a.ram) <= v_ram_size
          WHEN '=' THEN calculate_total_ram(a.ram) = v_ram_size
          ELSE TRUE
        END
      )
    )

    -- RAM type filter
    AND (v_ram_types IS NULL OR ram_has_ddr_type(a.ram, v_ram_types))

    -- RAM form factor filter
    AND (v_ram_form_factors IS NULL OR ram_has_form_factor(a.ram, v_ram_form_factors))

    -- Storage size filter
    AND (
      v_storage_size IS NULL
      OR (
        CASE v_storage_operator
          WHEN '>' THEN calculate_total_storage(a.storage) > v_storage_size
          WHEN '<' THEN calculate_total_storage(a.storage) < v_storage_size
          WHEN '>=' THEN calculate_total_storage(a.storage) >= v_storage_size
          WHEN '<=' THEN calculate_total_storage(a.storage) <= v_storage_size
          WHEN '=' THEN calculate_total_storage(a.storage) = v_storage_size
          ELSE TRUE
        END
      )
    )

    -- Storage type filter
    AND (v_storage_types IS NULL OR storage_has_type(a.storage, v_storage_types))

    -- Location filter (includes descendants)
    AND (v_expanded_location_ids IS NULL OR a.current_location_id = ANY(v_expanded_location_ids))
  ORDER BY a.tag_id ASC
  LIMIT p_page_size
  OFFSET p_page_offset;
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER;

-- ============================================================================
-- SECURITY: Revoke from public/anon and grant only to authenticated users
-- ============================================================================

-- Revoke default public access
REVOKE ALL ON FUNCTION search_assets(JSONB, INT, INT, BOOLEAN) FROM PUBLIC;
REVOKE ALL ON FUNCTION parse_size_to_gb(TEXT) FROM PUBLIC;
REVOKE ALL ON FUNCTION calculate_total_ram(JSONB) FROM PUBLIC;
REVOKE ALL ON FUNCTION calculate_total_storage(JSONB) FROM PUBLIC;
REVOKE ALL ON FUNCTION ram_has_ddr_type(JSONB, TEXT[]) FROM PUBLIC;
REVOKE ALL ON FUNCTION ram_has_form_factor(JSONB, TEXT[]) FROM PUBLIC;
REVOKE ALL ON FUNCTION storage_has_type(JSONB, TEXT[]) FROM PUBLIC;
REVOKE ALL ON FUNCTION get_location_with_descendants(UUID[]) FROM PUBLIC;

-- Explicitly revoke from anon role
REVOKE ALL ON FUNCTION search_assets(JSONB, INT, INT, BOOLEAN) FROM anon;
REVOKE ALL ON FUNCTION parse_size_to_gb(TEXT) FROM anon;
REVOKE ALL ON FUNCTION calculate_total_ram(JSONB) FROM anon;
REVOKE ALL ON FUNCTION calculate_total_storage(JSONB) FROM anon;
REVOKE ALL ON FUNCTION ram_has_ddr_type(JSONB, TEXT[]) FROM anon;
REVOKE ALL ON FUNCTION ram_has_form_factor(JSONB, TEXT[]) FROM anon;
REVOKE ALL ON FUNCTION storage_has_type(JSONB, TEXT[]) FROM anon;
REVOKE ALL ON FUNCTION get_location_with_descendants(UUID[]) FROM anon;

-- Grant only to authenticated users
GRANT EXECUTE ON FUNCTION search_assets(JSONB, INT, INT, BOOLEAN) TO authenticated;
GRANT EXECUTE ON FUNCTION parse_size_to_gb(TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION calculate_total_ram(JSONB) TO authenticated;
GRANT EXECUTE ON FUNCTION calculate_total_storage(JSONB) TO authenticated;
GRANT EXECUTE ON FUNCTION ram_has_ddr_type(JSONB, TEXT[]) TO authenticated;
GRANT EXECUTE ON FUNCTION ram_has_form_factor(JSONB, TEXT[]) TO authenticated;
GRANT EXECUTE ON FUNCTION storage_has_type(JSONB, TEXT[]) TO authenticated;
GRANT EXECUTE ON FUNCTION get_location_with_descendants(UUID[]) TO authenticated;


-- migrate:down

-- Revoke all grants before dropping functions
REVOKE ALL ON FUNCTION search_assets(JSONB, INT, INT, BOOLEAN) FROM authenticated;
REVOKE ALL ON FUNCTION parse_size_to_gb(TEXT) FROM authenticated;
REVOKE ALL ON FUNCTION calculate_total_ram(JSONB) FROM authenticated;
REVOKE ALL ON FUNCTION calculate_total_storage(JSONB) FROM authenticated;
REVOKE ALL ON FUNCTION ram_has_ddr_type(JSONB, TEXT[]) FROM authenticated;
REVOKE ALL ON FUNCTION ram_has_form_factor(JSONB, TEXT[]) FROM authenticated;
REVOKE ALL ON FUNCTION storage_has_type(JSONB, TEXT[]) FROM authenticated;
REVOKE ALL ON FUNCTION get_location_with_descendants(UUID[]) FROM authenticated;

-- Drop functions
DROP FUNCTION IF EXISTS search_assets(JSONB, INT, INT, BOOLEAN);
DROP FUNCTION IF EXISTS get_location_with_descendants(UUID[]);
DROP FUNCTION IF EXISTS storage_has_type(JSONB, TEXT[]);
DROP FUNCTION IF EXISTS ram_has_form_factor(JSONB, TEXT[]);
DROP FUNCTION IF EXISTS ram_has_ddr_type(JSONB, TEXT[]);
DROP FUNCTION IF EXISTS calculate_total_storage(JSONB);
DROP FUNCTION IF EXISTS calculate_total_ram(JSONB);
DROP FUNCTION IF EXISTS parse_size_to_gb(TEXT);
