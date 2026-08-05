-- Migration: 004_create_notification_templates_table.sql
-- Table: notification_templates
-- Description: Creates notification_templates table and channel enum for outbound messaging templates.

-- ==========================================
-- UP MIGRATION
-- ==========================================
BEGIN;

-- Custom Enum
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'notification_channel_enum') THEN
        CREATE TYPE notification_channel_enum AS ENUM ('IN_APP', 'PUSH', 'EMAIL', 'SMS');
    END IF;
END $$;

COMMENT ON TYPE notification_channel_enum IS 'Multi-channel outbound delivery options';

CREATE TABLE IF NOT EXISTS notification_templates (
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

-- Triggers
CREATE TRIGGER trg_notification_templates_updated_at
    BEFORE UPDATE ON notification_templates
    FOR EACH ROW
    EXECUTE FUNCTION fn_set_updated_at();

-- Comments
COMMENT ON TABLE notification_templates IS 'Multi-channel message template strings with mustache placeholders';
COMMENT ON COLUMN notification_templates.id IS 'Primary Key UUID v4';
COMMENT ON COLUMN notification_templates.code IS 'Unique template identifier key string';
COMMENT ON COLUMN notification_templates.channel IS 'Delivery channel enum';
COMMENT ON COLUMN notification_templates.subject_template IS 'Optional template string for email subjects';
COMMENT ON COLUMN notification_templates.body_template IS 'Message body text with placeholder parameters';

COMMIT;

-- ==========================================
-- DOWN MIGRATION (ROLLBACK SQL)
-- ==========================================
/*
BEGIN;
DROP TRIGGER IF EXISTS trg_notification_templates_updated_at ON notification_templates;
DROP TABLE IF EXISTS notification_templates CASCADE;
DROP TYPE IF EXISTS notification_channel_enum CASCADE;
COMMIT;
*/
