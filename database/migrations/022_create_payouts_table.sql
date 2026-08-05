-- Migration: 022_create_payouts_table.sql
-- Table: payouts
-- Description: Creates payouts table for player withdrawal requests, TDS tax deductions, and wallet FK index.

-- ==========================================
-- UP MIGRATION
-- ==========================================
BEGIN;

CREATE TABLE IF NOT EXISTS payouts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE RESTRICT ON UPDATE CASCADE,
    wallet_id UUID NOT NULL REFERENCES wallets(id) ON DELETE RESTRICT ON UPDATE CASCADE,
    amount NUMERIC(15,2) NOT NULL,
    tax_deducted_tds NUMERIC(15,2) NOT NULL DEFAULT 0.00,
    net_amount NUMERIC(15,2) NOT NULL,
    bank_account_hash VARCHAR(255) NULL,
    upi_id_hash VARCHAR(255) NULL,
    status payment_status_enum NOT NULL DEFAULT 'PENDING',
    reference_number VARCHAR(100) NULL,
    processed_at TIMESTAMPTZ NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    -- Constraints
    CONSTRAINT chk_payouts_amount_positive CHECK (amount > 0.00),
    CONSTRAINT chk_payouts_tax_positive CHECK (tax_deducted_tds >= 0.00),
    CONSTRAINT chk_payouts_net_calculation CHECK (net_amount = (amount - tax_deducted_tds))
);

-- Composite & FK Indexes
CREATE INDEX IF NOT EXISTS idx_payouts_user_status ON payouts (user_id, status);
CREATE INDEX IF NOT EXISTS idx_payouts_wallet_id ON payouts (wallet_id);

-- Triggers
CREATE TRIGGER trg_payouts_updated_at
    BEFORE UPDATE ON payouts
    FOR EACH ROW
    EXECUTE FUNCTION fn_set_updated_at();

-- Comments
COMMENT ON TABLE payouts IS 'Player cash withdrawal processing and 30% TDS tax deduction log';
COMMENT ON COLUMN payouts.id IS 'Primary Key UUID v4';
COMMENT ON COLUMN payouts.user_id IS 'Foreign Key to users table';
COMMENT ON COLUMN payouts.wallet_id IS 'Foreign Key to wallets table';
COMMENT ON COLUMN payouts.amount IS 'Requested gross withdrawal amount (CHECK > 0)';
COMMENT ON COLUMN payouts.tax_deducted_tds IS 'TDS tax deduction amount (CHECK >= 0)';
COMMENT ON COLUMN payouts.net_amount IS 'Net payable amount after TDS deduction (CHECK net = amount - tax)';

COMMIT;

-- ==========================================
-- DOWN MIGRATION (ROLLBACK SQL)
-- ==========================================
/*
BEGIN;
DROP TRIGGER IF EXISTS trg_payouts_updated_at ON payouts;
DROP INDEX IF EXISTS idx_payouts_wallet_id;
DROP INDEX IF EXISTS idx_payouts_user_status;
DROP TABLE IF EXISTS payouts CASCADE;
COMMIT;
*/
