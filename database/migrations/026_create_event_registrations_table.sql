-- Migration: 026_create_event_registrations_table.sql
-- Table: event_registrations
-- Description: Creates declarative range-partitioned event_registrations table, registration enum, and FK indexes.

-- ==========================================
-- UP MIGRATION
-- ==========================================
BEGIN;

-- Custom Enum
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'registration_status_enum') THEN
        CREATE TYPE registration_status_enum AS ENUM ('PENDING', 'CONFIRMED', 'CANCELLED', 'REJECTED', 'WAITLISTED');
    END IF;
END $$;

COMMENT ON TYPE registration_status_enum IS 'Tournament registration slot reservation status';

CREATE TABLE IF NOT EXISTS event_registrations (
    id UUID NOT NULL DEFAULT gen_random_uuid(),
    event_id UUID NOT NULL REFERENCES events(id) ON DELETE RESTRICT ON UPDATE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE RESTRICT ON UPDATE CASCADE,
    team_id UUID NULL REFERENCES teams(id) ON DELETE RESTRICT ON UPDATE CASCADE,
    registration_status registration_status_enum NOT NULL DEFAULT 'PENDING',
    payment_id UUID NULL REFERENCES payment_transactions(id) ON DELETE SET NULL ON UPDATE CASCADE,
    slot_number SMALLINT NULL,
    registered_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMPTZ NULL,
    PRIMARY KEY (id, registered_at)
) PARTITION BY RANGE (registered_at);

-- Create Default Partition for fallback
CREATE TABLE IF NOT EXISTS event_registrations_default 
    PARTITION OF event_registrations DEFAULT;

-- Create Monthly Partition for Current Period (2026-07)
CREATE TABLE IF NOT EXISTS event_registrations_y2026m07 
    PARTITION OF event_registrations 
    FOR VALUES FROM ('2026-07-01 00:00:00+00') TO ('2026-08-01 00:00:00+00');

-- Indexes
CREATE INDEX IF NOT EXISTS idx_event_registrations_event_user ON event_registrations (event_id, user_id) WHERE deleted_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_event_registrations_status ON event_registrations (event_id, registration_status) WHERE deleted_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_event_registrations_user ON event_registrations (user_id) WHERE deleted_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_event_registrations_team ON event_registrations (team_id) WHERE team_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_event_registrations_payment ON event_registrations (payment_id) WHERE payment_id IS NOT NULL;

-- Triggers
CREATE TRIGGER trg_event_registrations_updated_at
    BEFORE UPDATE ON event_registrations
    FOR EACH ROW
    EXECUTE FUNCTION fn_set_updated_at();

-- Comments
COMMENT ON TABLE event_registrations IS 'Tournament slot claims partitioned monthly by registered_at for 10M user scaling';
COMMENT ON COLUMN event_registrations.id IS 'Primary Key Part UUID v4';
COMMENT ON COLUMN event_registrations.event_id IS 'Foreign Key to events table';
COMMENT ON COLUMN event_registrations.user_id IS 'Foreign Key to users table';
COMMENT ON COLUMN event_registrations.team_id IS 'Foreign Key to teams table';
COMMENT ON COLUMN event_registrations.slot_number IS 'Assigned lobby team/player slot number as SMALLINT';

COMMIT;

-- ==========================================
-- DOWN MIGRATION (ROLLBACK SQL)
-- ==========================================
/*
BEGIN;
DROP TRIGGER IF EXISTS trg_event_registrations_updated_at ON event_registrations;
DROP INDEX IF EXISTS idx_event_registrations_payment;
DROP INDEX IF EXISTS idx_event_registrations_team;
DROP INDEX IF EXISTS idx_event_registrations_user;
DROP INDEX IF EXISTS idx_event_registrations_status;
DROP INDEX IF EXISTS idx_event_registrations_event_user;
DROP TABLE IF EXISTS event_registrations CASCADE;
DROP TYPE IF EXISTS registration_status_enum CASCADE;
COMMIT;
*/
