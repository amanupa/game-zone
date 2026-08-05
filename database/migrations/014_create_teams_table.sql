-- Migration: 014_create_teams_table.sql
-- Table: teams
-- Description: Creates teams table with partial unique tag index for player esports squads.

-- ==========================================
-- UP MIGRATION
-- ==========================================
BEGIN;

CREATE TABLE IF NOT EXISTS teams (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(100) NOT NULL,
    tag VARCHAR(10) NOT NULL,
    captain_id UUID NOT NULL REFERENCES users(id) ON DELETE RESTRICT ON UPDATE CASCADE,
    logo_url TEXT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMPTZ NULL
);

-- DBA Optimization: Partial Unique Index on tag (WHERE deleted_at IS NULL)
CREATE UNIQUE INDEX IF NOT EXISTS uq_teams_tag ON teams (tag) WHERE deleted_at IS NULL;

-- Partial Indexes
CREATE INDEX IF NOT EXISTS idx_teams_captain ON teams (captain_id) WHERE deleted_at IS NULL;

-- Triggers
CREATE TRIGGER trg_teams_updated_at
    BEFORE UPDATE ON teams
    FOR EACH ROW
    EXECUTE FUNCTION fn_set_updated_at();

-- Comments
COMMENT ON TABLE teams IS 'Player esports teams and squad profiles';
COMMENT ON COLUMN teams.id IS 'Primary Key UUID v4';
COMMENT ON COLUMN teams.name IS 'Team display name string';
COMMENT ON COLUMN teams.tag IS 'Unique team abbreviation tag (e.g. TSM, FNT) (enforced for active teams)';
COMMENT ON COLUMN teams.captain_id IS 'Foreign Key to users table (Team Captain)';

COMMIT;

-- ==========================================
-- DOWN MIGRATION (ROLLBACK SQL)
-- ==========================================
/*
BEGIN;
DROP TRIGGER IF EXISTS trg_teams_updated_at ON teams;
DROP INDEX IF EXISTS idx_teams_captain;
DROP INDEX IF EXISTS uq_teams_tag;
DROP TABLE IF EXISTS teams CASCADE;
COMMIT;
*/
