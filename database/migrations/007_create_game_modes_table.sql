-- Migration: 007_create_game_modes_table.sql
-- Table: game_modes
-- Description: Creates game_modes table with optimized SMALLINT datatypes for lobby formats per game.

-- ==========================================
-- UP MIGRATION
-- ==========================================
BEGIN;

CREATE TABLE IF NOT EXISTS game_modes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    game_id UUID NOT NULL REFERENCES games(id) ON DELETE CASCADE ON UPDATE CASCADE,
    name VARCHAR(50) NOT NULL,
    max_players_per_team SMALLINT NOT NULL DEFAULT 1,
    max_teams SMALLINT NOT NULL DEFAULT 25,
    description TEXT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    -- Constraints
    CONSTRAINT uq_game_modes_name UNIQUE (game_id, name),
    CONSTRAINT chk_game_modes_players CHECK (max_players_per_team > 0),
    CONSTRAINT chk_game_modes_teams CHECK (max_teams > 0)
);

-- Index for FK lookups
CREATE INDEX IF NOT EXISTS idx_game_modes_game_id ON game_modes (game_id);

-- Triggers
CREATE TRIGGER trg_game_modes_updated_at
    BEFORE UPDATE ON game_modes
    FOR EACH ROW
    EXECUTE FUNCTION fn_set_updated_at();

-- Comments
COMMENT ON TABLE game_modes IS 'Game lobby formats and roster constraints (Solo, Duo, Squad, TDM)';
COMMENT ON COLUMN game_modes.id IS 'Primary Key UUID v4';
COMMENT ON COLUMN game_modes.game_id IS 'Foreign Key to games table';
COMMENT ON COLUMN game_modes.name IS 'Mode title string';
COMMENT ON COLUMN game_modes.max_players_per_team IS 'Team size limit as SMALLINT (1 for Solo, 2 for Duo, 4 for Squad)';
COMMENT ON COLUMN game_modes.max_teams IS 'Maximum capacity of teams allowed in single match lobby as SMALLINT';

COMMIT;

-- ==========================================
-- DOWN MIGRATION (ROLLBACK SQL)
-- ==========================================
/*
BEGIN;
DROP TRIGGER IF EXISTS trg_game_modes_updated_at ON game_modes;
DROP INDEX IF EXISTS idx_game_modes_game_id;
DROP TABLE IF EXISTS game_modes CASCADE;
COMMIT;
*/
