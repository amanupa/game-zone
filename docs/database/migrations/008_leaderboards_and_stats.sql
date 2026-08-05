-- Game Zone PostgreSQL Migration: 008_leaderboards_and_stats.sql
-- Description: Aggregated player career statistics and verified event leaderboards.

BEGIN;

-- 1. Player Game Stats Table
CREATE TABLE player_game_stats (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL,
    game_id UUID NOT NULL,
    total_matches INTEGER NOT NULL DEFAULT 0,
    wins INTEGER NOT NULL DEFAULT 0,
    kills INTEGER NOT NULL DEFAULT 0,
    deaths INTEGER NOT NULL DEFAULT 0,
    assists INTEGER NOT NULL DEFAULT 0,
    total_earnings NUMERIC(15,2) NOT NULL DEFAULT 0.00,
    win_rate NUMERIC(5,2) NOT NULL DEFAULT 0.00,
    kd_ratio NUMERIC(5,2) NOT NULL DEFAULT 0.00,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_player_game_stats UNIQUE (user_id, game_id),
    CONSTRAINT fk_stats_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_stats_game FOREIGN KEY (game_id) REFERENCES games(id) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT chk_stats_counters CHECK (total_matches >= 0 AND wins >= 0 AND kills >= 0 AND deaths >= 0 AND assists >= 0 AND total_earnings >= 0.00),
    CONSTRAINT chk_stats_win_rate CHECK (win_rate >= 0.00 AND win_rate <= 100.00)
);

-- 2. Event Leaderboards Table
CREATE TABLE event_leaderboards (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    event_id UUID NOT NULL,
    user_id UUID NULL,
    team_id UUID NULL,
    rank INTEGER NOT NULL,
    kills_count INTEGER NOT NULL DEFAULT 0,
    placement_points NUMERIC(10,2) NOT NULL DEFAULT 0.00,
    total_points NUMERIC(10,2) NOT NULL DEFAULT 0.00,
    prize_amount NUMERIC(15,2) NOT NULL DEFAULT 0.00,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_event_leaderboard_rank UNIQUE (event_id, rank),
    CONSTRAINT fk_leaderboard_event FOREIGN KEY (event_id) REFERENCES events(id) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_leaderboard_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL ON UPDATE CASCADE,
    CONSTRAINT fk_leaderboard_team FOREIGN KEY (team_id) REFERENCES teams(id) ON DELETE SET NULL ON UPDATE CASCADE,
    CONSTRAINT chk_leaderboard_rank CHECK (rank > 0)
);

-- Indexes
CREATE INDEX idx_player_game_stats_game_rank ON player_game_stats (game_id, total_earnings DESC, wins DESC);
CREATE INDEX idx_event_leaderboards_rank ON event_leaderboards (event_id, rank ASC);

COMMENT ON TABLE player_game_stats IS 'Aggregated lifetime player statistics per game';
COMMENT ON TABLE event_leaderboards IS 'Verified final tournament leaderboard standings and prize payouts';

COMMIT;
