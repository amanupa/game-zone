-- Migration: 015_create_wallets_table.sql
-- Table: wallets
-- Description: Creates wallets table, balance integrity guard trigger, constraints, and partial unique user index.

-- ==========================================
-- UP MIGRATION
-- ==========================================
BEGIN;

CREATE TABLE IF NOT EXISTS wallets (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE RESTRICT ON UPDATE CASCADE,
    currency VARCHAR(3) NOT NULL DEFAULT 'INR',
    available_balance NUMERIC(15,2) NOT NULL DEFAULT 0.00,
    locked_balance NUMERIC(15,2) NOT NULL DEFAULT 0.00,
    total_deposited NUMERIC(15,2) NOT NULL DEFAULT 0.00,
    total_withdrawn NUMERIC(15,2) NOT NULL DEFAULT 0.00,
    total_won NUMERIC(15,2) NOT NULL DEFAULT 0.00,
    is_frozen BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMPTZ NULL,

    -- Constraints
    CONSTRAINT chk_wallets_available_balance_positive CHECK (available_balance >= 0.00),
    CONSTRAINT chk_wallets_locked_balance_positive CHECK (locked_balance >= 0.00),
    CONSTRAINT chk_wallets_totals_positive CHECK (total_deposited >= 0.00 AND total_withdrawn >= 0.00 AND total_won >= 0.00)
);

-- DBA Optimization: Partial Unique Index on user_id (WHERE deleted_at IS NULL)
CREATE UNIQUE INDEX IF NOT EXISTS uq_wallets_user ON wallets (user_id) WHERE deleted_at IS NULL;

-- Triggers
CREATE TRIGGER trg_wallets_updated_at
    BEFORE UPDATE ON wallets
    FOR EACH ROW
    EXECUTE FUNCTION fn_set_updated_at();

-- Wallet Balance Guard Trigger Function & Trigger
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

-- Comments
COMMENT ON TABLE wallets IS 'User monetary account balances and escrow lock status';
COMMENT ON COLUMN wallets.id IS 'Primary Key UUID v4';
COMMENT ON COLUMN wallets.user_id IS 'Foreign Key to users table (One-to-One relationship for active users)';
COMMENT ON COLUMN wallets.currency IS 'ISO 4217 Currency Code (default INR)';
COMMENT ON COLUMN wallets.available_balance IS 'Unlocked spendable balance for withdrawals and entry fees';
COMMENT ON COLUMN wallets.locked_balance IS 'Escrow locked balance for active tournament registrations';
COMMENT ON COLUMN wallets.is_frozen IS 'Administrative freeze flag prohibiting all wallet mutations';

COMMIT;

-- ==========================================
-- DOWN MIGRATION (ROLLBACK SQL)
-- ==========================================
/*
BEGIN;
DROP TRIGGER IF EXISTS trg_wallets_balance_guard ON wallets;
DROP FUNCTION IF EXISTS fn_trg_validate_wallet_balances();
DROP TRIGGER IF EXISTS trg_wallets_updated_at ON wallets;
DROP INDEX IF EXISTS uq_wallets_user;
DROP TABLE IF EXISTS wallets CASCADE;
COMMIT;
*/
