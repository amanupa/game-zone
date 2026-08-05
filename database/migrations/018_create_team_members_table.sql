-- Migration: 018_create_team_members_table.sql
-- Table: team_members
-- Description: Creates junction table mapping users to esports team rosters.

-- ==========================================
-- UP MIGRATION
-- ==========================================
BEGIN;

CREATE TABLE IF NOT EXISTS team_members (
    team_id UUID NOT NULL REFERENCES teams(id) ON DELETE CASCADE ON UPDATE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE ON UPDATE CASCADE,
    role VARCHAR(20) NOT NULL DEFAULT 'MEMBER',
    joined_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (team_id, user_id),

    -- Constraints
    CONSTRAINT chk_team_members_role CHECK (role IN ('CAPTAIN', 'MEMBER', 'SUBSTITUTE'))
);

-- Index for FK reverse lookups
CREATE INDEX IF NOT EXISTS idx_team_members_user_id ON team_members (user_id);

-- Comments
COMMENT ON TABLE team_members IS 'Team roster membership mapping table';
COMMENT ON COLUMN team_members.team_id IS 'Foreign Key to teams table';
COMMENT ON COLUMN team_members.user_id IS 'Foreign Key to users table';
COMMENT ON COLUMN team_members.role IS 'Roster role assignment (CAPTAIN, MEMBER, SUBSTITUTE)';

COMMIT;

-- ==========================================
-- DOWN MIGRATION (ROLLBACK SQL)
-- ==========================================
/*
BEGIN;
DROP INDEX IF EXISTS idx_team_members_user_id;
DROP TABLE IF EXISTS team_members CASCADE;
COMMIT;
*/
