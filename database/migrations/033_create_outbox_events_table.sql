-- Migration: 033_create_outbox_events_table.sql
-- Table: outbox_events
-- Description: Creates declarative range-partitioned transactional outbox table for Apache Kafka event messaging.

-- ==========================================
-- UP MIGRATION
-- ==========================================
BEGIN;

-- Custom Enum
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'outbox_status_enum') THEN
        CREATE TYPE outbox_status_enum AS ENUM ('PENDING', 'PROCESSING', 'PUBLISHED', 'FAILED');
    END IF;
END $$;

COMMENT ON TYPE outbox_status_enum IS 'Transactional outbox event dispatch lifecycle states';

CREATE TABLE IF NOT EXISTS outbox_events (
    id UUID NOT NULL DEFAULT gen_random_uuid(),
    aggregate_type VARCHAR(100) NOT NULL,
    aggregate_id UUID NOT NULL,
    event_type VARCHAR(100) NOT NULL,
    payload_json JSONB NOT NULL,
    status outbox_status_enum NOT NULL DEFAULT 'PENDING',
    error_message TEXT NULL,
    retry_count INTEGER NOT NULL DEFAULT 0,
    processed_at TIMESTAMPTZ NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id, created_at)
) PARTITION BY RANGE (created_at);

-- Create Default Partition for fallback
CREATE TABLE IF NOT EXISTS outbox_events_default 
    PARTITION OF outbox_events DEFAULT;

-- Create Monthly Partition for Current Period (2026-07)
CREATE TABLE IF NOT EXISTS outbox_events_y2026m07 
    PARTITION OF outbox_events 
    FOR VALUES FROM ('2026-07-01 00:00:00+00') TO ('2026-08-01 00:00:00+00');

-- Partial Index for High-Frequency Worker Polling with SKIP LOCKED
CREATE INDEX IF NOT EXISTS idx_outbox_events_pending ON outbox_events (created_at ASC) WHERE status = 'PENDING';

-- Comments
COMMENT ON TABLE outbox_events IS 'Partitioned transactional outbox table guaranteeing eventual consistency for Apache Kafka event streaming';
COMMENT ON COLUMN outbox_events.id IS 'Primary Key Part UUID v4';
COMMENT ON COLUMN outbox_events.aggregate_type IS 'Domain entity aggregate name (e.g. events, payments, registrations)';
COMMENT ON COLUMN outbox_events.aggregate_id IS 'Target entity Primary Key UUID';
COMMENT ON COLUMN outbox_events.event_type IS 'Kafka topic key string (e.g. gamezone.events.status_changed)';
COMMENT ON COLUMN outbox_events.payload_json IS 'Complete JSONB event data payload';
COMMENT ON COLUMN outbox_events.status IS 'Event publishing state machine status';

COMMIT;

-- ==========================================
-- DOWN MIGRATION (ROLLBACK SQL)
-- ==========================================
/*
BEGIN;
DROP INDEX IF EXISTS idx_outbox_events_pending;
DROP TABLE IF EXISTS outbox_events CASCADE;
DROP TYPE IF EXISTS outbox_status_enum CASCADE;
COMMIT;
*/
