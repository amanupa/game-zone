-- Migration: 032_create_result_disputes_table.sql
-- Table: result_disputes
-- Description: Creates result_disputes table, dispute enum, FK indexes, partial index, and trigger.

-- ==========================================
-- UP MIGRATION
-- ==========================================
BEGIN;

-- Custom Enum
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'dispute_status_enum') THEN
        CREATE TYPE dispute_status_enum AS ENUM (
            'OPEN', 'IN_INVESTIGATION', 'RESOLVED_PLAYER_WIN', 'RESOLVED_DRAW', 'REJECTED'
        );
    END IF;
END $$;

COMMENT ON TYPE dispute_status_enum IS 'Match score dispute arbitration statuses';

CREATE TABLE IF NOT EXISTS result_disputes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    match_result_id UUID NOT NULL REFERENCES match_results(id) ON DELETE CASCADE ON UPDATE CASCADE,
    raised_by UUID NOT NULL REFERENCES users(id) ON DELETE RESTRICT ON UPDATE CASCADE,
    against_user_id UUID NULL REFERENCES users(id) ON DELETE SET NULL ON UPDATE CASCADE,
    reason TEXT NOT NULL,
    evidence_url TEXT NULL,
    status dispute_status_enum NOT NULL DEFAULT 'OPEN',
    admin_notes TEXT NULL,
    resolved_by UUID NULL REFERENCES users(id) ON DELETE SET NULL ON UPDATE CASCADE,
    resolved_at TIMESTAMPTZ NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Partial & FK Indexes
CREATE INDEX IF NOT EXISTS idx_result_disputes_status ON result_disputes (status) WHERE status = 'OPEN';
CREATE INDEX IF NOT EXISTS idx_result_disputes_match_result ON result_disputes (match_result_id);
CREATE INDEX IF NOT EXISTS idx_result_disputes_raised_by ON result_disputes (raised_by);
CREATE INDEX IF NOT EXISTS idx_result_disputes_against_user ON result_disputes (against_user_id) WHERE against_user_id IS NOT NULL;

-- Triggers
CREATE TRIGGER trg_result_disputes_updated_at
    BEFORE UPDATE ON result_disputes
    FOR EACH ROW
    EXECUTE FUNCTION fn_set_updated_at();

-- Comments
COMMENT ON TABLE result_disputes IS 'Dispute claims raised by players against match score calculations or anti-cheat violations';
COMMENT ON COLUMN result_disputes.id IS 'Primary Key UUID v4';
COMMENT ON COLUMN result_disputes.match_result_id IS 'Foreign Key to match_results table';
COMMENT ON COLUMN result_disputes.raised_by IS 'Foreign Key to users table (Complainant player)';
COMMENT ON COLUMN result_disputes.against_user_id IS 'Foreign Key to users table (Accused player)';
COMMENT ON COLUMN result_disputes.resolved_by IS 'Foreign Key to users table (Admin arbiter)';

COMMIT;

-- ==========================================
-- DOWN MIGRATION (ROLLBACK SQL)
-- ==========================================
/*
BEGIN;
DROP TRIGGER IF EXISTS trg_result_disputes_updated_at ON result_disputes;
DROP INDEX IF EXISTS idx_result_disputes_against_user;
DROP INDEX IF EXISTS idx_result_disputes_raised_by;
DROP INDEX IF EXISTS idx_result_disputes_match_result;
DROP INDEX IF EXISTS idx_result_disputes_status;
DROP TABLE IF EXISTS result_disputes CASCADE;
DROP TYPE IF EXISTS dispute_status_enum CASCADE;
COMMIT;
*/
