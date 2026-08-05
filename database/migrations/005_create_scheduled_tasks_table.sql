-- Migration: 005_create_scheduled_tasks_table.sql
-- Table: scheduled_tasks
-- Description: Creates scheduled_tasks table for managing platform cron jobs.

-- ==========================================
-- UP MIGRATION
-- ==========================================
BEGIN;

CREATE TABLE IF NOT EXISTS scheduled_tasks (
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

-- Triggers
CREATE TRIGGER trg_scheduled_tasks_updated_at
    BEFORE UPDATE ON scheduled_tasks
    FOR EACH ROW
    EXECUTE FUNCTION fn_set_updated_at();

-- Comments
COMMENT ON TABLE scheduled_tasks IS 'Platform cron execution scheduling matrix';
COMMENT ON COLUMN scheduled_tasks.id IS 'Primary Key UUID v4';
COMMENT ON COLUMN scheduled_tasks.task_name IS 'Unique background task name string';
COMMENT ON COLUMN scheduled_tasks.cron_expression IS 'Standard 5-field cron expression syntax';
COMMENT ON COLUMN scheduled_tasks.target_service IS 'Internal handler microservice route/name';

COMMIT;

-- ==========================================
-- DOWN MIGRATION (ROLLBACK SQL)
-- ==========================================
/*
BEGIN;
DROP TRIGGER IF EXISTS trg_scheduled_tasks_updated_at ON scheduled_tasks;
DROP TABLE IF EXISTS scheduled_tasks CASCADE;
COMMIT;
*/
