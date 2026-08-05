# Game Zone Automated Database Triggers Specification

This document details all database triggers created to enforce automatic timestamps, outbox event generation, and transactional ledger constraints.

---

## 1. Automatic Timestamp Update Trigger

### `trg_set_updated_at`
Reusable trigger attached to all stateful tables (`users`, `events`, `wallets`, `teams`, etc.).

```sql
CREATE OR REPLACE FUNCTION fn_set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;
```

**Attached Tables**: `users`, `user_auth`, `roles`, `permissions`, `user_game_identities`, `kyc_verifications`, `games`, `game_modes`, `events`, `event_prize_structures`, `teams`, `event_registrations`, `match_rooms`, `wallets`, `payment_transactions`, `payouts`, `match_results`, `result_disputes`, `player_game_stats`, `event_leaderboards`, `notification_templates`, `scheduled_tasks`, `system_configurations`.

---

## 2. Transactional Outbox Event Triggers

### 2.1 `trg_outbox_event_published`
Automatically writes a Kafka outbox event whenever an event status transitions.

```sql
CREATE OR REPLACE FUNCTION fn_trg_outbox_event_status()
RETURNS TRIGGER AS $$
BEGIN
    IF (OLD.status IS DISTINCT FROM NEW.status) THEN
        INSERT INTO outbox_events (
            aggregate_type,
            aggregate_id,
            event_type,
            payload_json,
            status
        ) VALUES (
            'events',
            NEW.id,
            'gamezone.events.status_changed',
            jsonb_build_object(
                'event_id', NEW.id,
                'old_status', OLD.status,
                'new_status', NEW.status,
                'game_id', NEW.game_id,
                'timestamp', CURRENT_TIMESTAMP
            ),
            'PENDING'
        );
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_events_outbox_status
AFTER UPDATE ON events
FOR EACH ROW
EXECUTE FUNCTION fn_trg_outbox_event_status();
```

### 2.2 `trg_outbox_deposit_completed`
Writes outbox event when a payment moves to `COMPLETED`.

```sql
CREATE OR REPLACE FUNCTION fn_trg_outbox_payment_completed()
RETURNS TRIGGER AS $$
BEGIN
    IF (OLD.status != 'COMPLETED' AND NEW.status = 'COMPLETED') THEN
        INSERT INTO outbox_events (
            aggregate_type,
            aggregate_id,
            event_type,
            payload_json,
            status
        ) VALUES (
            'payments',
            NEW.id,
            'gamezone.payments.deposit.completed',
            jsonb_build_object(
                'payment_id', NEW.id,
                'user_id', NEW.user_id,
                'wallet_id', NEW.wallet_id,
                'amount', NEW.amount,
                'gateway', NEW.gateway,
                'timestamp', CURRENT_TIMESTAMP
            ),
            'PENDING'
        );
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_payments_outbox_completed
AFTER UPDATE ON payment_transactions
FOR EACH ROW
EXECUTE FUNCTION fn_trg_outbox_payment_completed();
```

---

## 3. Financial Integrity & Balance Validation Triggers

### 3.1 `trg_validate_wallet_mutation`
Enforces that `available_balance` and `locked_balance` can never become negative under concurrent updates.

```sql
CREATE OR REPLACE FUNCTION fn_trg_validate_wallet_balances()
RETURNS TRIGGER AS $$
BEGIN
    IF (NEW.available_balance < 0.00) THEN
        RAISE EXCEPTION 'INSUFFICIENT_FUNDS: Available balance cannot be negative (user_id: %)', NEW.user_id;
    END IF;
    IF (NEW.locked_balance < 0.00) THEN
        RAISE EXCEPTION 'INVALID_ESCROW: Locked balance cannot be negative (user_id: %)', NEW.user_id;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_wallets_balance_guard
BEFORE UPDATE ON wallets
FOR EACH ROW
EXECUTE FUNCTION fn_trg_validate_wallet_balances();
```
