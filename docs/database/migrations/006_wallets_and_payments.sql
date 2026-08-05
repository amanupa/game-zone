-- Game Zone PostgreSQL Migration: 006_wallets_and_payments.sql
-- Description: Financial double-entry ledger, user wallets, escrow locks, payment gateways, and TDS payouts.

BEGIN;

-- 1. Wallets Table
CREATE TABLE wallets (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL,
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
    CONSTRAINT uq_wallets_user UNIQUE (user_id),
    CONSTRAINT fk_wallets_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT chk_wallets_available_balance CHECK (available_balance >= 0.00),
    CONSTRAINT chk_wallets_locked_balance CHECK (locked_balance >= 0.00),
    CONSTRAINT chk_wallets_totals CHECK (total_deposited >= 0.00 AND total_withdrawn >= 0.00 AND total_won >= 0.00)
);

-- 2. Wallet Locks Table
CREATE TABLE wallet_locks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    wallet_id UUID NOT NULL,
    event_id UUID NOT NULL,
    amount NUMERIC(15,2) NOT NULL,
    reason VARCHAR(100) NOT NULL DEFAULT 'ENTRY_FEE',
    is_released BOOLEAN NOT NULL DEFAULT FALSE,
    released_at TIMESTAMPTZ NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_wallet_locks_wallet FOREIGN KEY (wallet_id) REFERENCES wallets(id) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_wallet_locks_event FOREIGN KEY (event_id) REFERENCES events(id) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT chk_wallet_locks_amount CHECK (amount > 0.00)
);

-- 3. Wallet Transactions Table (Partitioned by created_at)
CREATE TABLE wallet_transactions (
    id UUID DEFAULT gen_random_uuid(),
    wallet_id UUID NOT NULL,
    reference_id UUID NOT NULL,
    transaction_type transaction_type_enum NOT NULL,
    account_type ledger_account_type_enum NOT NULL,
    amount NUMERIC(15,2) NOT NULL,
    balance_after NUMERIC(15,2) NOT NULL,
    description TEXT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id, created_at),
    CONSTRAINT fk_wallet_transactions_wallet FOREIGN KEY (wallet_id) REFERENCES wallets(id) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT chk_wallet_transactions_amount CHECK (amount > 0.00),
    CONSTRAINT chk_wallet_transactions_balance CHECK (balance_after >= 0.00)
) PARTITION BY RANGE (created_at);

-- Initial Partitions
CREATE TABLE wallet_transactions_y2026m07 PARTITION OF wallet_transactions
    FOR VALUES FROM ('2026-07-01 00:00:00+00') TO ('2026-08-01 00:00:00+00');

CREATE TABLE wallet_transactions_y2026m08 PARTITION OF wallet_transactions
    FOR VALUES FROM ('2026-08-01 00:00:00+00') TO ('2026-09-01 00:00:00+00');

CREATE TABLE wallet_transactions_default PARTITION OF wallet_transactions DEFAULT;

-- 4. Payment Transactions Table
CREATE TABLE payment_transactions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL,
    wallet_id UUID NOT NULL,
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
    CONSTRAINT fk_payments_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_payments_wallet FOREIGN KEY (wallet_id) REFERENCES wallets(id) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT chk_payments_amount CHECK (amount > 0.00),
    CONSTRAINT chk_payments_fee CHECK (fee_amount >= 0.00 AND tax_amount >= 0.00)
);

-- Foreign Key binding from event_registrations to payment_transactions
ALTER TABLE event_registrations ADD CONSTRAINT fk_event_reg_payment FOREIGN KEY (payment_id) REFERENCES payment_transactions(id) ON DELETE SET NULL ON UPDATE CASCADE;

-- 5. Payouts Table
CREATE TABLE payouts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL,
    wallet_id UUID NOT NULL,
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
    CONSTRAINT fk_payouts_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_payouts_wallet FOREIGN KEY (wallet_id) REFERENCES wallets(id) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT chk_payouts_amount CHECK (amount > 0.00),
    CONSTRAINT chk_payouts_tax CHECK (tax_deducted_tds >= 0.00),
    CONSTRAINT chk_payouts_net CHECK (net_amount = (amount - tax_deducted_tds))
);

-- Indexes
CREATE INDEX idx_wallets_user ON wallets (user_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_wallet_locks_active ON wallet_locks (wallet_id, event_id) WHERE is_released = FALSE;
CREATE INDEX idx_wallet_transactions_wallet_created ON wallet_transactions (wallet_id, created_at DESC);
CREATE INDEX idx_wallet_transactions_reference ON wallet_transactions (reference_id);
CREATE INDEX idx_payment_transactions_user ON payment_transactions (user_id, created_at DESC);
CREATE INDEX idx_payment_transactions_gateway_order ON payment_transactions (gateway, gateway_order_id);
CREATE INDEX idx_payment_transactions_status ON payment_transactions (status) WHERE status = 'PENDING';
CREATE INDEX idx_payouts_user_status ON payouts (user_id, status);

COMMENT ON TABLE wallets IS 'User monetary balances and double-entry account ledger link';
COMMENT ON TABLE wallet_transactions IS 'Partitioned immutable double-entry ledger entries';

COMMIT;
