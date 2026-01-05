-- migrate:up

ALTER TABLE asset_requests ADD COLUMN request_notes TEXT;

-- migrate:down

ALTER TABLE asset_requests DROP COLUMN request_notes;