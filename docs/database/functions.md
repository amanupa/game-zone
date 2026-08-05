# Game Zone Stored Functions & Procedures Specification

This document details all PL/pgSQL stored procedures designed to execute high-concurrency ACID transactions natively in PostgreSQL.

---

## 1. Atomic User Tournament Registration Procedure

### `fn_register_user_for_event`
Atomically checks slot availability, locks entry fee in user wallet, reserves slot, creates registration record, and emits outbox event.

```sql
CREATE OR REPLACE FUNCTION fn_register_user_for_event(
    p_user_id UUID,
    p_event_id UUID,
    p_team_id UUID DEFAULT NULL
) RETURNS UUID AS $$
DECLARE
    v_entry_fee NUMERIC(15,2);
    v_max_slots INT;
    v_filled_slots INT;
    v_event_status event_status_enum;
    v_wallet_id UUID;
    v_available_balance NUMERIC(15,2);
    v_registration_id UUID;
    v_lock_id UUID;
BEGIN
    -- 1. Lock and check event state
    SELECT entry_fee, max_slots, filled_slots, status 
    INTO v_entry_fee, v_max_slots, v_filled_slots, v_event_status
    FROM events 
    WHERE id = p_event_id AND deleted_at IS NULL
    FOR UPDATE;

    IF v_event_status != 'REGISTRATION_OPEN' THEN
        RAISE EXCEPTION 'REGISTRATION_CLOSED: Tournament is not accepting registrations';
    END IF;

    IF v_filled_slots >= v_max_slots THEN
        RAISE EXCEPTION 'TOURNAMENT_FULL: No slots available';
    END IF;

    -- 2. Lock and check user wallet
    SELECT id, available_balance INTO v_wallet_id, v_available_balance
    FROM wallets
    WHERE user_id = p_user_id AND is_frozen = FALSE AND deleted_at IS NULL
    FOR UPDATE;

    IF v_wallet_id IS NULL THEN
        RAISE EXCEPTION 'WALLET_NOT_FOUND: Active wallet not found for user';
    END IF;

    IF v_entry_fee > 0.00 AND v_available_balance < v_entry_fee THEN
        RAISE EXCEPTION 'INSUFFICIENT_FUNDS: Wallet balance insufficient for entry fee';
    END IF;

    -- 3. Move fee to escrow lock if non-zero
    IF v_entry_fee > 0.00 THEN
        UPDATE wallets 
        SET available_balance = available_balance - v_entry_fee,
            locked_balance = locked_balance + v_entry_fee
        WHERE id = v_wallet_id;

        INSERT INTO wallet_locks (wallet_id, event_id, amount, reason)
        VALUES (v_wallet_id, p_event_id, v_entry_fee, 'ENTRY_FEE')
        RETURNING id INTO v_lock_id;
    END IF;

    -- 4. Update event slot count
    UPDATE events 
    SET filled_slots = filled_slots + 1 
    WHERE id = p_event_id;

    -- 5. Create registration record
    INSERT INTO event_registrations (
        event_id, user_id, team_id, registration_status, slot_number
    ) VALUES (
        p_event_id, p_user_id, p_team_id, 'CONFIRMED', v_filled_slots + 1
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
            'slot_number', v_filled_slots + 1
        ), 'PENDING'
    );

    RETURN v_registration_id;
END;
$$ LANGUAGE plpgsql;
```

---

## 2. Automated Prize Payout & Settlement Procedure

### `fn_process_prize_payout`
Distributes tournament prize pool payouts to winners within a single ACID transaction.

```sql
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
```
