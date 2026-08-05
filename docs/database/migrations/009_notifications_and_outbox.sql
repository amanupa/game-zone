-- Game Zone PostgreSQL Migration: 009_notifications_and_outbox.sql
-- Description: Transactional outbox pattern for Apache Kafka and multi-channel notification logs.

BEGIN;

-- 1. Outbox Events Table (Partitioned by created_at)
CREATE TABLE outbox_events (
    id UUID DEFAULT gen_random_uuid(),
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

-- Initial Partitions
CREATE TABLE outbox_events_y2026m07 PARTITION OF outbox_events
    FOR VALUES FROM ('2026-07-01 00:00:00+00') TO ('2026-08-01 00:00:00+00');

CREATE TABLE outbox_events_y2026m08 PARTITION OF outbox_events
    FOR VALUES FROM ('2026-08-01 00:00:00+00') TO ('2026-09-01 00:00:00+00');

CREATE TABLE outbox_events_default PARTITION OF outbox_events DEFAULT;

-- 2. Notification Templates Table
CREATE TABLE notification_templates (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    code VARCHAR(100) NOT NULL,
    channel notification_channel_enum NOT NULL,
    subject_template TEXT NULL,
    body_template TEXT NOT NULL,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_notification_templates_code UNIQUE (code)
);

-- 3. Notification Logs Table (Partitioned by created_at)
CREATE TABLE notification_logs (
    id UUID DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL,
    template_id UUID NULL,
    channel notification_channel_enum NOT NULL,
    recipient VARCHAR(255) NOT NULL,
    payload_json JSONB NULL DEFAULT '{}',
    status notification_status_enum NOT NULL DEFAULT 'QUEUED',
    sent_at TIMESTAMPTZ NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id, created_at),
    CONSTRAINT fk_notification_logs_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_notification_logs_template FOREIGN KEY (template_id) REFERENCES notification_templates(id) ON DELETE SET NULL ON UPDATE CASCADE
) PARTITION BY RANGE (created_at);

-- Initial Partitions
CREATE TABLE notification_logs_y2026m07 PARTITION OF notification_logs
    FOR VALUES FROM ('2026-07-01 00:00:00+00') TO ('2026-08-01 00:00:00+00');

CREATE TABLE notification_logs_y2026m08 PARTITION OF notification_logs
    FOR VALUES FROM ('2026-08-01 00:00:00+00') TO ('2026-09-01 00:00:00+00');

CREATE TABLE notification_logs_default PARTITION OF notification_logs DEFAULT;

-- Indexes
CREATE INDEX idx_outbox_events_pending ON outbox_events (created_at ASC) WHERE status = 'PENDING';
CREATE INDEX idx_notification_logs_recipient ON notification_logs (user_id, status);

COMMENT ON TABLE outbox_events IS 'Transactional outbox for reliable Apache Kafka event publishing';
COMMENT ON TABLE notification_logs IS 'Partitioned log of dispatched In-App, Push, Email, and SMS notifications';

COMMIT;
