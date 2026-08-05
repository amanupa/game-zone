-- Migration: 030_create_event_leaderboards_table.sql
-- Table: event_leaderboards
-- Description: Creates event_leaderboards table with user and team FK indexes.

-- ==========================================
-- UP MIGRATION
-- ==========================================
BEGIN;

CREATE TABLE IF NOT EXISTS event_leaderboards (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    event_id UUID NOT NULL REFERENCES events(id) ON DELETE CASCADE ON UPDATE CASCADE,
    user_id UUID NULL REFERENCES users(id) ON DELETE SET NULL ON UPDATE CASCADE,
    team_id UUID NULL REFERENCES teams(id) ON DELETE SET NULL ON UPDATE CASCADE,
    rank INTEGER NOT NULL,
    kills_count INTEGER NOT NULL DEFAULT 0,
    placement_points NUMERIC(10,2) NOT NULL DEFAULT 0.00,
    total_points NUMERIC(10,2) NOT NULL DEFAULT 0.00,
    prize_amount NUMERIC(15,2) NOT NULL DEFAULT 0.00,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    -- Constraints
    CONSTRAINT chk_leaderboard_rank_positive CHECK (rank > 0)
);

-- Composite & FK Indexes
CREATE INDEX IF NOT EXISTS idx_event_leaderboards_rank ON event_leaderboards (event_id, rank ASC);
CREATE INDEX IF NOT EXISTS idx_event_leaderboards_user ON event_leaderboards (user_id) WHERE user_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_event_leaderboards_team ON event_leaderboards (team_id) WHERE team_id IS NOT NULL;

-- Triggers
CREATE TRIGGER trg_event_leaderboards_updated_at
    BEFORE UPDATE ON event_leaderboards
    FOR EACH ROW
    EXECUTE FUNCTION fn_set_updated_at();

-- Comments
COMMENT ON TABLE event_leaderboards IS 'Verified final tournament rank standings and winnings distribution breakdown';
COMMENT ON COLUMN event_leaderboards.id IS 'Primary Key UUID v4';
COMMENT ON COLUMN event_leaderboards.event_id IS 'Foreign Key to events table';
COMMENT ON COLUMN event_leaderboards.rank IS 'Final verified tournament rank placement position (CHECK > 0)';
COMMENT ON COLUMN event_leaderboards.prize_amount IS 'Awarded cash prize amount distributed to winner';

COMMIT;

-- ==========================================
-- DOWN MIGRATION (ROLLBACK SQL)
-- ==========================================
/*
BEGIN;
DROP TRIGGER IF EXISTS trg_event_leaderboards_updated_at ON event_leaderboards;
DROP INDEX IF EXISTS idx_event_leaderboards_team;
DROP INDEX IF EXISTS idx_event_leaderboards_user;
DROP INDEX IF EXISTS idx_event_leaderboards_rank;
DROP TABLE IF EXISTS event_leaderboards CASCADE;
COMMIT;
*/
