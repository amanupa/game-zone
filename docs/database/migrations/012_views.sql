-- Game Zone PostgreSQL Migration: 012_views.sql
-- Description: Analytical and operational views for active tournaments, wallet summaries, dispute queues, and leaderboards.

BEGIN;

-- 1. Active Tournaments View
CREATE OR REPLACE VIEW v_active_tournaments AS
SELECT 
    e.id AS event_id,
    g.name AS game_name,
    gm.name AS game_mode,
    e.title,
    e.slug,
    e.entry_fee,
    e.prize_pool,
    e.max_slots,
    e.filled_slots,
    (e.max_slots - e.filled_slots) AS available_slots,
    e.format,
    e.status,
    e.registration_start_at,
    e.registration_end_at,
    e.tournament_start_at
FROM events e
JOIN games g ON e.game_id = g.id
JOIN game_modes gm ON e.game_mode_id = gm.id
WHERE e.deleted_at IS NULL 
  AND e.status IN ('PUBLISHED', 'REGISTRATION_OPEN', 'IN_PROGRESS');

-- 2. User Wallet Summary View
CREATE OR REPLACE VIEW v_user_wallet_summary AS
SELECT 
    w.id AS wallet_id,
    w.user_id,
    u.username,
    u.email,
    w.currency,
    w.available_balance,
    w.locked_balance,
    (w.available_balance + w.locked_balance) AS total_balance,
    w.total_deposited,
    w.total_withdrawn,
    w.total_won,
    w.is_frozen,
    w.updated_at AS last_updated
FROM wallets w
JOIN users u ON w.user_id = u.id
WHERE w.deleted_at IS NULL AND u.deleted_at IS NULL;

-- 3. Disputed Matches Queue View
CREATE OR REPLACE VIEW v_disputed_matches_queue AS
SELECT 
    d.id AS dispute_id,
    mr.id AS match_result_id,
    e.id AS event_id,
    e.title AS tournament_title,
    mr.room_id,
    u_raised.username AS raised_by_username,
    u_against.username AS accused_username,
    d.reason,
    d.evidence_url,
    d.status AS dispute_status,
    d.created_at AS raised_at
FROM result_disputes d
JOIN match_results mr ON d.match_result_id = mr.id
JOIN events e ON mr.event_id = e.id
JOIN users u_raised ON d.raised_by = u_raised.id
LEFT JOIN users u_against ON d.against_user_id = u_against.id
WHERE d.status IN ('OPEN', 'IN_INVESTIGATION');

-- 4. Global Player Rankings View
CREATE OR REPLACE VIEW v_global_player_rankings AS
SELECT 
    u.id AS user_id,
    u.username,
    u.avatar_url,
    g.code AS game_code,
    g.name AS game_name,
    s.total_matches,
    s.wins,
    s.kills,
    s.win_rate,
    s.kd_ratio,
    s.total_earnings,
    DENSE_RANK() OVER (PARTITION BY s.game_id ORDER BY s.total_earnings DESC, s.wins DESC) AS overall_rank
FROM player_game_stats s
JOIN users u ON s.user_id = u.id
JOIN games g ON s.game_id = g.id
WHERE u.deleted_at IS NULL AND u.is_banned = FALSE;

COMMENT ON VIEW v_active_tournaments IS 'Live active tournaments open for player registration';
COMMENT ON VIEW v_user_wallet_summary IS 'Wallet balances and total net worth summary';

COMMIT;
