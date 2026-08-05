-- Migration: 024_create_audit_logs_table.sql
-- Table: audit_logs
-- Description: Creates declarative monthly range-partitioned audit_logs table and composite indexes.

-- ==========================================
-- UP MIGRATION
-- ==========================================
BEGIN;

CREATE TABLE IF NOT EXISTS audit_logs (
    id UUID NOT NULL DEFAULT gen_random_uuid(),
    actor_id UUID NULL REFERENCES users(id) ON DELETE SET NULL ON UPDATE CASCADE,
    ip_address INET NULL,
    user_agent TEXT NULL,
    action VARCHAR(100) NOT NULL,
    resource_type VARCHAR(100) NOT NULL,
    resource_id UUID NULL,
    old_values_json JSONB NULL,
    new_values_json JSONB NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id, created_at)
) PARTITION BY RANGE (created_at);

-- Create Default Partition for fallback
CREATE TABLE IF NOT EXISTS audit_logs_default 
    PARTITION OF audit_logs DEFAULT;

-- Create Monthly Partition for Current Period (2026-07)
CREATE TABLE IF NOT EXISTS audit_logs_y2026m07 
    PARTITION OF audit_logs 
    FOR VALUES FROM ('2026-07-01 00:00:00+00') TO ('2026-08-01 00:00:00+00');

-- Composite Indexes
CREATE INDEX IF NOT EXISTS idx_audit_logs_actor ON audit_logs (actor_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_audit_logs_resource ON audit_logs (resource_type, resource_id);

-- Comments
COMMENT ON TABLE audit_logs IS 'Immutable security audit trail partitioned monthly by created_at';
COMMENT ON COLUMN audit_logs.id IS 'Primary Key Part UUID v4';
COMMENT ON COLUMN audit_logs.actor_id IS 'Foreign Key to users table (Admin or User triggering action)';
COMMENT ON COLUMN audit_logs.action IS 'Security/Administrative action key string (e.g. USER_BAN, PRIZE_PAYOUT)';
COMMENT ON COLUMN audit_logs.resource_type IS 'Target entity table/resource identifier';
COMMENT ON COLUMN audit_logs.resource_id IS 'Target entity Primary Key UUID';

COMMIT;

-- ==========================================
-- DOWN MIGRATION (ROLLBACK SQL)
-- ==========================================
/*
BEGIN;
DROP INDEX IF EXISTS idx_audit_logs_resource;
DROP INDEX IF EXISTS idx_audit_logs_actor;
DROP TABLE IF EXISTS audit_logs CASCADE;
COMMIT;
*/
