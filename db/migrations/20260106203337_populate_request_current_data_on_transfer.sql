-- migrate:up

DROP TRIGGER asset_request_before_insert ON asset_requests;
DROP FUNCTION asset_request_populate_current_data;

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
      'current_location_id', current_location_id
    )
INTO NEW.current_data
FROM assets
WHERE id = NEW.asset_id;
RETURN NEW;
END;
$$;

CREATE TRIGGER asset_request_before_insert
  BEFORE INSERT ON asset_requests
  FOR EACH ROW
  WHEN (NEW.request_type = 'update' OR NEW.request_type = 'transfer')
  EXECUTE FUNCTION asset_request_populate_current_data();

-- migrate:down

DROP TRIGGER asset_request_before_insert ON asset_requests;
DROP FUNCTION asset_request_populate_current_data;

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

CREATE TRIGGER asset_request_before_insert
  BEFORE INSERT ON asset_requests
  FOR EACH ROW
  WHEN (NEW.request_type = 'update')
  EXECUTE FUNCTION asset_request_populate_current_data();

