-- migrate:up

-- Trigger to capitalize an asset's serial_number, model_number and tag_id before inserting or updating
CREATE OR REPLACE FUNCTION capitalize_asset_attributes()
RETURNS TRIGGER AS $$
BEGIN
    NEW.serial_number := UPPER(NEW.serial_number);
    NEW.model_number := UPPER(NEW.model_number);
    NEW.tag_id := UPPER(NEW.tag_id);
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER capitalize_asset_attributes_trigger
BEFORE INSERT OR UPDATE ON assets
FOR EACH ROW
EXECUTE FUNCTION capitalize_asset_attributes();

-- migrate:down

DROP TRIGGER IF EXISTS capitalize_asset_attributes_trigger ON assets;
DROP FUNCTION IF EXISTS capitalize_asset_attributes();