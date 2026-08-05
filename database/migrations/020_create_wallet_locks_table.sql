-- Migration: 020_create_wallet_locks_table.sql
-- Table: wallet_locks
-- Description: Creates wallet_locks table for tournament entry fee escrow holds.

-- ==========================================
-- UP MIGRATION
-- ==========================================
BEGIN;

CREATE TABLE IF NOT EXISTS wallet_locks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    wallet_id UUID NOT NULL REFERENCES wallets(id) ON DELETE RESTRICT ON UPDATE CASCADE,
    event_id UUID NOT NULL REFERENCES events(id) ON DELETE RESTRICT ON UPDATE CASCADE,
    amount NUMERIC(15,2) NOT NULL,
    reason VARCHAR(100) NOT NULL DEFAULT 'ENTRY_FEE',
    is_released BOOLEAN NOT NULL DEFAULT FALSE,
    released_at TIMESTAMPTZ NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    -- Constraints
    CONSTRAINT chk_wallet_locks_amount_positive CHECK (amount > 0.00)
);

-- Partial Composite Index for active escrow locks
CREATE INDEX IF NOT EXISTS idx_wallet_locks_active ON wallet_locks (wallet_id, event_id) WHERE is_released = FALSE;

-- Comments
COMMENT ON TABLE wallet_locks IS 'Escrow holds locking user funds during active tournament participation';
COMMENT ON COLUMN wallet_locks.id IS 'Primary Key UUID v4';
COMMENT ON COLUMN wallet_locks.wallet_id IS 'Foreign Key to wallets table';
COMMENT ON COLUMN wallet_locks.event_id IS 'Foreign Key to events table';
COMMENT ON COLUMN wallet_locks.amount IS 'Monetary amount locked in escrow (CHECK > 0)';
COMMENT ON COLUMN wallet_locks.is_released IS 'Whether escrow lock has been settled or released';

COMMIT;

-- ==========================================
-- DOWN MIGRATION (ROLLBACK SQL)
-- ==========================================
/*
BEGIN;
DROP INDEX IF EXISTS idx_wallet_locks_active;
DROP TABLE IF EXISTS wallet_locks CASCADE;
COMMIT;
*/
