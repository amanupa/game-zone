-- Migration: 021_create_payment_transactions_table.sql
-- Table: payment_transactions
-- Description: Creates payment_transactions table, payment enums, outbox trigger, and partial indexes.

-- ==========================================
-- UP MIGRATION
-- ==========================================
BEGIN;

-- Custom Enums
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'payment_gateway_enum') THEN
        CREATE TYPE payment_gateway_enum AS ENUM ('RAZORPAY', 'STRIPE', 'PAYPAL');
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'payment_type_enum') THEN
        CREATE TYPE payment_type_enum AS ENUM ('DEPOSIT', 'WITHDRAWAL', 'ENTRY_FEE', 'PRIZE_PAYOUT', 'REFUND');
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'payment_status_enum') THEN
        CREATE TYPE payment_status_enum AS ENUM ('PENDING', 'PROCESSING', 'COMPLETED', 'FAILED', 'REFUNDED');
    END IF;
END $$;

COMMENT ON TYPE payment_gateway_enum IS 'Supported external payment gateway providers';
COMMENT ON TYPE payment_type_enum IS 'Payment flow classification types';
COMMENT ON TYPE payment_status_enum IS 'Payment order state machine status';

CREATE TABLE IF NOT EXISTS payment_transactions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE RESTRICT ON UPDATE CASCADE,
    wallet_id UUID NOT NULL REFERENCES wallets(id) ON DELETE RESTRICT ON UPDATE CASCADE,
    gateway payment_gateway_enum NOT NULL,
    payment_type payment_type_enum NOT NULL,
    gateway_order_id VARCHAR(255) NULL,
    gateway_payment_id VARCHAR(255) NULL,
    gateway_signature VARCHAR(255) NULL,
    amount NUMERIC(15,2) NOT NULL,
    fee_amount NUMERIC(15,2) NOT NULL DEFAULT 0.00,
    tax_amount NUMERIC(15,2) NOT NULL DEFAULT 0.00,
    currency VARCHAR(3) NOT NULL DEFAULT 'INR',
    status payment_status_enum NOT NULL DEFAULT 'PENDING',
    metadata_json JSONB NULL DEFAULT '{}',
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    -- Constraints
    CONSTRAINT chk_payments_amount_positive CHECK (amount > 0.00),
    CONSTRAINT chk_payments_fee_positive CHECK (fee_amount >= 0.00 AND tax_amount >= 0.00)
);

-- Composite & Partial Indexes
CREATE INDEX IF NOT EXISTS idx_payment_transactions_user ON payment_transactions (user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_payment_transactions_gateway_order ON payment_transactions (gateway, gateway_order_id);
CREATE INDEX IF NOT EXISTS idx_payment_transactions_status ON payment_transactions (status) WHERE status = 'PENDING';

-- Triggers
CREATE TRIGGER trg_payment_transactions_updated_at
    BEFORE UPDATE ON payment_transactions
    FOR EACH ROW
    EXECUTE FUNCTION fn_set_updated_at();

-- Outbox Deposit Completed Trigger Function & Trigger
CREATE OR REPLACE FUNCTION fn_trg_outbox_payment_completed()
RETURNS TRIGGER AS $$
BEGIN
    IF (OLD.status != 'COMPLETED' AND NEW.status = 'COMPLETED') THEN
        INSERT INTO outbox_events (
            aggregate_type, aggregate_id, event_type, payload_json, status
        ) VALUES (
            'payments', NEW.id, 'gamezone.payments.deposit.completed',
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

-- Comments
COMMENT ON TABLE payment_transactions IS 'Payment gateway integration logs for deposits, entry fees, and payouts';
COMMENT ON COLUMN payment_transactions.id IS 'Primary Key UUID v4';
COMMENT ON COLUMN payment_transactions.user_id IS 'Foreign Key to users table';
COMMENT ON COLUMN payment_transactions.wallet_id IS 'Foreign Key to wallets table';
COMMENT ON COLUMN payment_transactions.gateway_order_id IS 'Gateway order ID string';
COMMENT ON COLUMN payment_transactions.gateway_payment_id IS 'Gateway transaction ID string';

COMMIT;

-- ==========================================
-- DOWN MIGRATION (ROLLBACK SQL)
-- ==========================================
/*
BEGIN;
DROP TRIGGER IF EXISTS trg_payments_outbox_completed ON payment_transactions;
DROP FUNCTION IF EXISTS fn_trg_outbox_payment_completed();
DROP TRIGGER IF EXISTS trg_payment_transactions_updated_at ON payment_transactions;
DROP INDEX IF EXISTS idx_payment_transactions_status;
DROP INDEX IF EXISTS idx_payment_transactions_gateway_order;
DROP INDEX IF EXISTS idx_payment_transactions_user;
DROP TABLE IF EXISTS payment_transactions CASCADE;
DROP TYPE IF EXISTS payment_status_enum CASCADE;
DROP TYPE IF EXISTS payment_type_enum CASCADE;
DROP TYPE IF EXISTS payment_gateway_enum CASCADE;
COMMIT;
*/
