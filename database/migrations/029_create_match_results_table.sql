-- Migration: 029_create_match_results_table.sql
-- Table: match_results
-- Description: Creates match_results table, result_status_enum, and verified_by FK index.

-- ==========================================
-- UP MIGRATION
-- ==========================================
BEGIN;

-- Custom Enum
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'result_status_enum') THEN
        CREATE TYPE result_status_enum AS ENUM (
            'SUBMITTED', 'UNDER_REVIEW', 'VERIFIED', 'DISPUTED', 'REJECTED'
        );
    END IF;
END $$;

COMMENT ON TYPE result_status_enum IS 'Match result verification workflow status';

CREATE TABLE IF NOT EXISTS match_results (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    event_id UUID NOT NULL REFERENCES events(id) ON DELETE CASCADE ON UPDATE CASCADE,
    room_id UUID NOT NULL REFERENCES match_rooms(id) ON DELETE CASCADE ON UPDATE CASCADE,
    status result_status_enum NOT NULL DEFAULT 'SUBMITTED',
    verified_by UUID NULL REFERENCES users(id) ON DELETE SET NULL ON UPDATE CASCADE,
    verified_at TIMESTAMPTZ NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    -- Unique Constraints
    CONSTRAINT uq_match_results_room UNIQUE (room_id)
);

-- Composite & FK Indexes
CREATE INDEX IF NOT EXISTS idx_match_results_event ON match_results (event_id, room_id);
CREATE INDEX IF NOT EXISTS idx_match_results_verified_by ON match_results (verified_by) WHERE verified_by IS NOT NULL;

-- Triggers
CREATE TRIGGER trg_match_results_updated_at
    BEFORE UPDATE ON match_results
    FOR EACH ROW
    EXECUTE FUNCTION fn_set_updated_at();

-- Comments
COMMENT ON TABLE match_results IS 'Match score headers holding room result verification status';
COMMENT ON COLUMN match_results.id IS 'Primary Key UUID v4';
COMMENT ON COLUMN match_results.event_id IS 'Foreign Key to events table';
COMMENT ON COLUMN match_results.room_id IS 'Foreign Key to match_rooms table (One-to-One relationship)';
COMMENT ON COLUMN match_results.verified_by IS 'Foreign Key to users table (Admin who verified score)';

COMMIT;

-- ==========================================
-- DOWN MIGRATION (ROLLBACK SQL)
-- ==========================================
/*
BEGIN;
DROP TRIGGER IF EXISTS trg_match_results_updated_at ON match_results;
DROP INDEX IF EXISTS idx_match_results_verified_by;
DROP INDEX IF EXISTS idx_match_results_event;
DROP TABLE IF EXISTS match_results CASCADE;
DROP TYPE IF EXISTS result_status_enum CASCADE;
COMMIT;
*/
