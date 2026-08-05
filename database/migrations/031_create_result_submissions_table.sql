-- Migration: 031_create_result_submissions_table.sql
-- Table: result_submissions
-- Description: Creates result_submissions table with SMALLINT rank datatypes and team_id FK index.

-- ==========================================
-- UP MIGRATION
-- ==========================================
BEGIN;

CREATE TABLE IF NOT EXISTS result_submissions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    match_result_id UUID NOT NULL REFERENCES match_results(id) ON DELETE CASCADE ON UPDATE CASCADE,
    submitted_by UUID NOT NULL REFERENCES users(id) ON DELETE RESTRICT ON UPDATE CASCADE,
    team_id UUID NULL REFERENCES teams(id) ON DELETE SET NULL ON UPDATE CASCADE,
    rank_achieved SMALLINT NOT NULL,
    kills_count INTEGER NOT NULL DEFAULT 0,
    score_points NUMERIC(10,2) NOT NULL DEFAULT 0.00,
    proof_screenshot_url TEXT NULL,
    metadata_json JSONB NULL DEFAULT '{}',
    submitted_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    -- Constraints
    CONSTRAINT chk_submissions_rank_positive CHECK (rank_achieved > 0),
    CONSTRAINT chk_submissions_kills_positive CHECK (kills_count >= 0),
    CONSTRAINT chk_submissions_score_positive CHECK (score_points >= 0.00)
);

-- Composite & FK Indexes
CREATE INDEX IF NOT EXISTS idx_result_submissions_result ON result_submissions (match_result_id, rank_achieved);
CREATE INDEX IF NOT EXISTS idx_result_submissions_user ON result_submissions (submitted_by);
CREATE INDEX IF NOT EXISTS idx_result_submissions_team ON result_submissions (team_id) WHERE team_id IS NOT NULL;

-- Comments
COMMENT ON TABLE result_submissions IS 'Individual player/squad match score claims and screenshot proof uploads';
COMMENT ON COLUMN result_submissions.id IS 'Primary Key UUID v4';
COMMENT ON COLUMN result_submissions.match_result_id IS 'Foreign Key to match_results table';
COMMENT ON COLUMN result_submissions.submitted_by IS 'Foreign Key to users table (Submitting player)';
COMMENT ON COLUMN result_submissions.rank_achieved IS 'Placement position as SMALLINT';
COMMENT ON COLUMN result_submissions.proof_screenshot_url IS 'Encrypted S3 image URL of endgame scoreboard screenshot';

COMMIT;

-- ==========================================
-- DOWN MIGRATION (ROLLBACK SQL)
-- ==========================================
/*
BEGIN;
DROP INDEX IF EXISTS idx_result_submissions_team;
DROP INDEX IF EXISTS idx_result_submissions_user;
DROP INDEX IF EXISTS idx_result_submissions_result;
DROP TABLE IF EXISTS result_submissions CASCADE;
COMMIT;
*/
