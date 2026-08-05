-- Migration: 023_create_player_game_stats_table.sql
-- Table: player_game_stats
-- Description: Creates player_game_stats table with NUMERIC(7,2) datatypes for ratio calculations.

-- ==========================================
-- UP MIGRATION
-- ==========================================
BEGIN;

CREATE TABLE IF NOT EXISTS player_game_stats (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE ON UPDATE CASCADE,
    game_id UUID NOT NULL REFERENCES games(id) ON DELETE CASCADE ON UPDATE CASCADE,
    total_matches INTEGER NOT NULL DEFAULT 0,
    wins INTEGER NOT NULL DEFAULT 0,
    kills INTEGER NOT NULL DEFAULT 0,
    deaths INTEGER NOT NULL DEFAULT 0,
    assists INTEGER NOT NULL DEFAULT 0,
    total_earnings NUMERIC(15,2) NOT NULL DEFAULT 0.00,
    win_rate NUMERIC(7,2) NOT NULL DEFAULT 0.00,
    kd_ratio NUMERIC(7,2) NOT NULL DEFAULT 0.00,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    -- Constraints
    CONSTRAINT uq_player_game_stats_user_game UNIQUE (user_id, game_id),
    CONSTRAINT chk_stats_counters_positive CHECK (
        total_matches >= 0 AND wins >= 0 AND kills >= 0 AND deaths >= 0 AND assists >= 0 AND total_earnings >= 0.00
    ),
    CONSTRAINT chk_stats_win_rate_range CHECK (win_rate >= 0.00 AND win_rate <= 100.00)
);

-- Composite Index for Global Leaderboards
CREATE INDEX IF NOT EXISTS idx_player_game_stats_game_rank ON player_game_stats (game_id, total_earnings DESC, wins DESC);

-- Triggers
CREATE TRIGGER trg_player_game_stats_updated_at
    BEFORE UPDATE ON player_game_stats
    FOR EACH ROW
    EXECUTE FUNCTION fn_set_updated_at();

-- Comments
COMMENT ON TABLE player_game_stats IS 'Aggregated career telemetry and tournament performance statistics per player per game';
COMMENT ON COLUMN player_game_stats.id IS 'Primary Key UUID v4';
COMMENT ON COLUMN player_game_stats.user_id IS 'Foreign Key to users table';
COMMENT ON COLUMN player_game_stats.game_id IS 'Foreign Key to games table';
COMMENT ON COLUMN player_game_stats.total_earnings IS 'Lifetime cash prize winnings in game';

COMMIT;

-- ==========================================
-- DOWN MIGRATION (ROLLBACK SQL)
-- ==========================================
/*
BEGIN;
DROP TRIGGER IF EXISTS trg_player_game_stats_updated_at ON player_game_stats;
DROP INDEX IF EXISTS idx_player_game_stats_game_rank;
DROP TABLE IF EXISTS player_game_stats CASCADE;
COMMIT;
*/
