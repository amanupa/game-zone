-- Migration: 028_create_wallet_transactions_table.sql
-- Table: wallet_transactions
-- Description: Creates declarative range-partitioned double-entry financial ledger and transaction enums.

-- ==========================================
-- UP MIGRATION
-- ==========================================
BEGIN;

-- Custom Enums
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'transaction_type_enum') THEN
        CREATE TYPE transaction_type_enum AS ENUM ('CREDIT', 'DEBIT');
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'ledger_account_type_enum') THEN
        CREATE TYPE ledger_account_type_enum AS ENUM (
            'USER_WALLET', 'SYSTEM_ESCROW', 'GATEWAY_SETTLEMENT', 'PLATFORM_FEE', 'PRIZE_POOL'
        );
    END IF;
END $$;

COMMENT ON TYPE transaction_type_enum IS 'Ledger entry direction type (CREDIT, DEBIT)';
COMMENT ON TYPE ledger_account_type_enum IS 'Double-entry accounting ledger account classification';

CREATE TABLE IF NOT EXISTS wallet_transactions (
    id UUID NOT NULL DEFAULT gen_random_uuid(),
    wallet_id UUID NOT NULL REFERENCES wallets(id) ON DELETE RESTRICT ON UPDATE CASCADE,
    reference_id UUID NOT NULL,
    transaction_type transaction_type_enum NOT NULL,
    account_type ledger_account_type_enum NOT NULL,
    amount NUMERIC(15,2) NOT NULL,
    balance_after NUMERIC(15,2) NOT NULL,
    description TEXT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id, created_at),

    -- Constraints
    CONSTRAINT chk_wallet_transactions_amount_positive CHECK (amount > 0.00),
    CONSTRAINT chk_wallet_transactions_balance_after CHECK (balance_after >= 0.00)
) PARTITION BY RANGE (created_at);

-- Create Default Partition for fallback
CREATE TABLE IF NOT EXISTS wallet_transactions_default 
    PARTITION OF wallet_transactions DEFAULT;

-- Create Monthly Partition for Current Period (2026-07)
CREATE TABLE IF NOT EXISTS wallet_transactions_y2026m07 
    PARTITION OF wallet_transactions 
    FOR VALUES FROM ('2026-07-01 00:00:00+00') TO ('2026-08-01 00:00:00+00');

-- Composite & B-Tree Indexes
CREATE INDEX IF NOT EXISTS idx_wallet_transactions_wallet_created ON wallet_transactions (wallet_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_wallet_transactions_reference ON wallet_transactions (reference_id);

-- Comments
COMMENT ON TABLE wallet_transactions IS 'Immutable double-entry financial ledger partitioned monthly by created_at';
COMMENT ON COLUMN wallet_transactions.id IS 'Primary Key Part UUID v4';
COMMENT ON COLUMN wallet_transactions.wallet_id IS 'Foreign Key to wallets table';
COMMENT ON COLUMN wallet_transactions.reference_id IS 'Group transaction correlation UUID for balancing debits/credits';
COMMENT ON COLUMN wallet_transactions.amount IS 'Monetary mutation amount (CHECK > 0)';
COMMENT ON COLUMN wallet_transactions.balance_after IS 'Snapshot of wallet available balance after transaction execution';

COMMIT;

-- ==========================================
-- DOWN MIGRATION (ROLLBACK SQL)
-- ==========================================
/*
BEGIN;
DROP INDEX IF EXISTS idx_wallet_transactions_reference;
DROP INDEX IF EXISTS idx_wallet_transactions_wallet_created;
DROP TABLE IF EXISTS wallet_transactions CASCADE;
DROP TYPE IF EXISTS ledger_account_type_enum CASCADE;
DROP TYPE IF EXISTS transaction_type_enum CASCADE;
COMMIT;
*/
