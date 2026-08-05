-- Migration: 025_create_notification_logs_table.sql
-- Table: notification_logs
-- Description: Creates declarative range-partitioned notification_logs table and delivery status enum.

-- ==========================================
-- UP MIGRATION
-- ==========================================
BEGIN;

-- Custom Enum
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'notification_status_enum') THEN
        CREATE TYPE notification_status_enum AS ENUM ('QUEUED', 'SENT', 'DELIVERED', 'FAILED');
    END IF;
END $$;

COMMENT ON TYPE notification_status_enum IS 'Outbound notification delivery pipeline states';

CREATE TABLE IF NOT EXISTS notification_logs (
    id UUID NOT NULL DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE ON UPDATE CASCADE,
    template_id UUID NULL REFERENCES notification_templates(id) ON DELETE SET NULL ON UPDATE CASCADE,
    channel notification_channel_enum NOT NULL,
    recipient VARCHAR(255) NOT NULL,
    payload_json JSONB NULL DEFAULT '{}',
    status notification_status_enum NOT NULL DEFAULT 'QUEUED',
    sent_at TIMESTAMPTZ NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id, created_at)
) PARTITION BY RANGE (created_at);

-- Create Default Partition for fallback
CREATE TABLE IF NOT EXISTS notification_logs_default 
    PARTITION OF notification_logs DEFAULT;

-- Create Monthly Partition for Current Period (2026-07)
CREATE TABLE IF NOT EXISTS notification_logs_y2026m07 
    PARTITION OF notification_logs 
    FOR VALUES FROM ('2026-07-01 00:00:00+00') TO ('2026-08-01 00:00:00+00');

-- Composite Index
CREATE INDEX IF NOT EXISTS idx_notification_logs_recipient ON notification_logs (user_id, status);

-- Comments
COMMENT ON TABLE notification_logs IS 'Outbound multi-channel notification audit log partitioned monthly';
COMMENT ON COLUMN notification_logs.id IS 'Primary Key Part UUID v4';
COMMENT ON COLUMN notification_logs.user_id IS 'Foreign Key to users table (Recipient User)';
COMMENT ON COLUMN notification_logs.template_id IS 'Foreign Key to notification_templates table';
COMMENT ON COLUMN notification_logs.recipient IS 'Phone number / Email address / Push token target string';

COMMIT;

-- ==========================================
-- DOWN MIGRATION (ROLLBACK SQL)
-- ==========================================
/*
BEGIN;
DROP INDEX IF EXISTS idx_notification_logs_recipient;
DROP TABLE IF EXISTS notification_logs CASCADE;
DROP TYPE IF EXISTS notification_status_enum CASCADE;
COMMIT;
*/
