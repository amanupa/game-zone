-- Game Zone PostgreSQL Migration: 010_scheduler_and_audit.sql
-- Description: Cron task scheduler execution matrix, system configurations, and partitioned audit logs.

BEGIN;

-- 1. Scheduled Tasks Table
CREATE TABLE scheduled_tasks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    task_name VARCHAR(100) NOT NULL,
    cron_expression VARCHAR(50) NOT NULL,
    target_service VARCHAR(100) NOT NULL,
    payload_json JSONB NULL DEFAULT '{}',
    is_enabled BOOLEAN NOT NULL DEFAULT TRUE,
    last_run_at TIMESTAMPTZ NULL,
    next_run_at TIMESTAMPTZ NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_scheduled_tasks_name UNIQUE (task_name)
);

-- 2. Audit Logs Table (Partitioned by created_at)
CREATE TABLE audit_logs (
    id UUID DEFAULT gen_random_uuid(),
    actor_id UUID NULL,
    ip_address INET NULL,
    user_agent TEXT NULL,
    action VARCHAR(100) NOT NULL,
    resource_type VARCHAR(100) NOT NULL,
    resource_id UUID NULL,
    old_values_json JSONB NULL,
    new_values_json JSONB NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id, created_at),
    CONSTRAINT fk_audit_logs_actor FOREIGN KEY (actor_id) REFERENCES users(id) ON DELETE SET NULL ON UPDATE CASCADE
) PARTITION BY RANGE (created_at);

-- Initial Partitions
CREATE TABLE audit_logs_y2026m07 PARTITION OF audit_logs
    FOR VALUES FROM ('2026-07-01 00:00:00+00') TO ('2026-08-01 00:00:00+00');

CREATE TABLE audit_logs_y2026m08 PARTITION OF audit_logs
    FOR VALUES FROM ('2026-08-01 00:00:00+00') TO ('2026-09-01 00:00:00+00');

CREATE TABLE audit_logs_default PARTITION OF audit_logs DEFAULT;

-- 3. System Configurations Table
CREATE TABLE system_configurations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    config_key VARCHAR(100) NOT NULL,
    config_value JSONB NOT NULL,
    description TEXT NULL,
    updated_by UUID NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_system_config_key UNIQUE (config_key),
    CONSTRAINT fk_system_config_editor FOREIGN KEY (updated_by) REFERENCES users(id) ON DELETE SET NULL ON UPDATE CASCADE
);

-- Indexes
CREATE INDEX idx_audit_logs_actor ON audit_logs (actor_id, created_at DESC);
CREATE INDEX idx_audit_logs_resource ON audit_logs (resource_type, resource_id);

COMMENT ON TABLE scheduled_tasks IS 'Platform cron execution timers';
COMMENT ON TABLE audit_logs IS 'Immutable partitioned administrative and security audit trail';

COMMIT;
