-- Migration: 011_create_user_game_identities_table.sql
-- Table: user_game_identities
-- Description: Creates user_game_identities table with partial unique indexes for active game UIDs.

-- ==========================================
-- UP MIGRATION
-- ==========================================
BEGIN;

CREATE TABLE IF NOT EXISTS user_game_identities (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE ON UPDATE CASCADE,
    game_id UUID NOT NULL REFERENCES games(id) ON DELETE RESTRICT ON UPDATE CASCADE,
    in_game_id VARCHAR(100) NOT NULL,
    in_game_name VARCHAR(100) NOT NULL,
    rank_tier VARCHAR(50) NULL,
    is_verified BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMPTZ NULL
);

-- DBA Optimization: Partial Unique Indexes (WHERE deleted_at IS NULL)
CREATE UNIQUE INDEX IF NOT EXISTS uq_user_game_identity ON user_game_identities (game_id, in_game_id) WHERE deleted_at IS NULL;
CREATE UNIQUE INDEX IF NOT EXISTS uq_user_game_user ON user_game_identities (user_id, game_id) WHERE deleted_at IS NULL;

-- Additional Lookup Index
CREATE INDEX IF NOT EXISTS idx_user_game_identities_user ON user_game_identities (user_id, game_id) WHERE deleted_at IS NULL;

-- Triggers
CREATE TRIGGER trg_user_game_identities_updated_at
    BEFORE UPDATE ON user_game_identities
    FOR EACH ROW
    EXECUTE FUNCTION fn_set_updated_at();

-- Comments
COMMENT ON TABLE user_game_identities IS 'Player numeric UIDs and handles per game (e.g. BGMI Character ID, Free Fire UID)';
COMMENT ON COLUMN user_game_identities.id IS 'Primary Key UUID v4';
COMMENT ON COLUMN user_game_identities.user_id IS 'Foreign Key to users table';
COMMENT ON COLUMN user_game_identities.game_id IS 'Foreign Key to games table';
COMMENT ON COLUMN user_game_identities.in_game_id IS 'Game-specific numeric/alphanumeric player ID string';
COMMENT ON COLUMN user_game_identities.in_game_name IS 'Game-specific player In-Game Name (IGN)';
COMMENT ON COLUMN user_game_identities.is_verified IS 'Whether game identity has been anti-cheat verified';

COMMIT;

-- ==========================================
-- DOWN MIGRATION (ROLLBACK SQL)
-- ==========================================
/*
BEGIN;
DROP TRIGGER IF EXISTS trg_user_game_identities_updated_at ON user_game_identities;
DROP INDEX IF EXISTS idx_user_game_identities_user;
DROP INDEX IF EXISTS uq_user_game_user;
DROP INDEX IF EXISTS uq_user_game_identity;
DROP TABLE IF EXISTS user_game_identities CASCADE;
COMMIT;
*/
