-- Migration: 034_create_stored_procedures_and_views.sql
-- Description: Creates high-concurrency stored procedures and operational/analytical database views.

-- ==========================================
-- UP MIGRATION
-- ==========================================
BEGIN;

-- ------------------------------------------
-- 1. Stored Procedures
-- ------------------------------------------

-- 1.1 Atomic High-Concurrency User Tournament Registration Procedure (Non-Blocking)
CREATE OR REPLACE FUNCTION fn_register_user_for_event(
    p_user_id UUID,
    p_event_id UUID,
    p_team_id UUID DEFAULT NULL
) RETURNS UUID AS $$
DECLARE
    v_entry_fee NUMERIC(15,2);
    v_max_slots INT;
    v_event_status event_status_enum;
    v_wallet_id UUID;
    v_available_balance NUMERIC(15,2);
    v_registration_id UUID;
    v_lock_id UUID;
    v_assigned_slot INT;
BEGIN
    -- 1. Read event details without row locking
    SELECT entry_fee, max_slots, status 
    INTO v_entry_fee, v_max_slots, v_event_status
    FROM events 
    WHERE id = p_event_id AND deleted_at IS NULL;

    IF v_event_status != 'REGISTRATION_OPEN' THEN
        RAISE EXCEPTION 'REGISTRATION_CLOSED: Tournament is not accepting registrations';
    END IF;

    -- 2. Atomic Slot Reservation (Non-blocking conditional update eliminates row lock serialization)
    UPDATE events 
    SET filled_slots = filled_slots + 1 
    WHERE id = p_event_id 
      AND status = 'REGISTRATION_OPEN' 
      AND filled_slots < max_slots 
      AND deleted_at IS NULL
    RETURNING filled_slots INTO v_assigned_slot;

    IF v_assigned_slot IS NULL THEN
        RAISE EXCEPTION 'TOURNAMENT_FULL: No slots available or event state changed';
    END IF;

    -- 3. Lock user wallet and check balance
    SELECT id, available_balance INTO v_wallet_id, v_available_balance
    FROM wallets
    WHERE user_id = p_user_id AND is_frozen = FALSE AND deleted_at IS NULL
    FOR UPDATE;

    IF v_wallet_id IS NULL THEN
        -- Revert slot increment if wallet not found
        UPDATE events SET filled_slots = filled_slots - 1 WHERE id = p_event_id;
        RAISE EXCEPTION 'WALLET_NOT_FOUND: Active wallet not found for user';
    END IF;

    IF v_entry_fee > 0.00 AND v_available_balance < v_entry_fee THEN
        -- Revert slot increment if balance is insufficient
        UPDATE events SET filled_slots = filled_slots - 1 WHERE id = p_event_id;
        RAISE EXCEPTION 'INSUFFICIENT_FUNDS: Wallet balance insufficient for entry fee';
    END IF;

    -- 4. Move fee to escrow lock if non-zero
    IF v_entry_fee > 0.00 THEN
        UPDATE wallets 
        SET available_balance = available_balance - v_entry_fee,
            locked_balance = locked_balance + v_entry_fee
        WHERE id = v_wallet_id;

        INSERT INTO wallet_locks (wallet_id, event_id, amount, reason)
        VALUES (v_wallet_id, p_event_id, v_entry_fee, 'ENTRY_FEE')
        RETURNING id INTO v_lock_id;
    END IF;

    -- 5. Create registration record
    INSERT INTO event_registrations (
        event_id, user_id, team_id, registration_status, slot_number
    ) VALUES (
        p_event_id, p_user_id, p_team_id, 'CONFIRMED', v_assigned_slot
    ) RETURNING id INTO v_registration_id;

    -- 6. Insert Outbox Event
    INSERT INTO outbox_events (
        aggregate_type, aggregate_id, event_type, payload_json, status
    ) VALUES (
        'registrations', v_registration_id, 'gamezone.registrations.confirmed',
        jsonb_build_object(
            'registration_id', v_registration_id,
            'event_id', p_event_id,
            'user_id', p_user_id,
            'slot_number', v_assigned_slot
        ), 'PENDING'
    );

    RETURN v_registration_id;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION fn_register_user_for_event(UUID, UUID, UUID) IS 'Atomic procedure for user tournament registration with non-blocking slot increments and entry fee escrow locking';

-- 1.2 Automated Prize Payout & Settlement Procedure
CREATE OR REPLACE FUNCTION fn_process_prize_payout(
    p_event_id UUID
) RETURNS INT AS $$
DECLARE
    v_rec RECORD;
    v_wallet_id UUID;
    v_payout_count INT := 0;
    v_txn_ref UUID := gen_random_uuid();
BEGIN
    -- Verify event is in RESULT_SETTLED
    IF NOT EXISTS (SELECT 1 FROM events WHERE id = p_event_id AND status = 'RESULT_SETTLED') THEN
        RAISE EXCEPTION 'INVALID_EVENT_STATE: Tournament results are not settled';
    END IF;

    FOR v_rec IN 
        SELECT user_id, prize_amount 
        FROM event_leaderboards 
        WHERE event_id = p_event_id AND prize_amount > 0.00
    LOOP
        -- Lock winner wallet
        SELECT id INTO v_wallet_id FROM wallets WHERE user_id = v_rec.user_id FOR UPDATE;

        IF v_wallet_id IS NOT NULL THEN
            -- Credit wallet balance
            UPDATE wallets 
            SET available_balance = available_balance + v_rec.prize_amount,
                total_won = total_won + v_rec.prize_amount
            WHERE id = v_wallet_id;

            -- Ledger entry
            INSERT INTO wallet_transactions (
                wallet_id, reference_id, transaction_type, account_type, amount, balance_after, description
            ) VALUES (
                v_wallet_id, v_txn_ref, 'CREDIT', 'PRIZE_POOL', v_rec.prize_amount,
                (SELECT available_balance FROM wallets WHERE id = v_wallet_id),
                CONCAT('Tournament Prize Payout Event: ', p_event_id)
            );

            v_payout_count := v_payout_count + 1;
        END IF;
    END LOOP;

    -- Update event to COMPLETED
    UPDATE events SET status = 'COMPLETED' WHERE id = p_event_id;

    -- Outbox Event
    INSERT INTO outbox_events (
        aggregate_type, aggregate_id, event_type, payload_json, status
    ) VALUES (
        'events', p_event_id, 'gamezone.events.payout.completed',
        jsonb_build_object('event_id', p_event_id, 'winners_count', v_payout_count), 'PENDING'
    );

    RETURN v_payout_count;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION fn_process_prize_payout(UUID) IS 'Atomic procedure for automated prize pool distribution to tournament winners';

-- ------------------------------------------
-- 2. Operational Views
-- ------------------------------------------

-- 2.1 Active Tournaments View
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

-- 2.2 User Wallet Summary View
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

-- 2.3 Disputed Matches Queue View
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

-- 2.4 Global Player Rankings View
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

COMMIT;

-- ==========================================
-- DOWN MIGRATION (ROLLBACK SQL)
-- ==========================================
/*
BEGIN;
DROP VIEW IF EXISTS v_global_player_rankings CASCADE;
DROP VIEW IF EXISTS v_disputed_matches_queue CASCADE;
DROP VIEW IF EXISTS v_user_wallet_summary CASCADE;
DROP VIEW IF EXISTS v_active_tournaments CASCADE;
DROP FUNCTION IF EXISTS fn_process_prize_payout(UUID);
DROP FUNCTION IF EXISTS fn_register_user_for_event(UUID, UUID, UUID);
COMMIT;
*/
