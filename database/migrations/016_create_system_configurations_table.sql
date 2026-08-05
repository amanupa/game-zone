-- Migration: 016_create_system_configurations_table.sql
-- Table: system_configurations
-- Description: Creates system_configurations table with updated_by FK index.

-- ==========================================
-- UP MIGRATION
-- ==========================================
BEGIN;

CREATE TABLE IF NOT EXISTS system_configurations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    config_key VARCHAR(100) NOT NULL,
    config_value JSONB NOT NULL,
    description TEXT NULL,
    updated_by UUID NULL REFERENCES users(id) ON DELETE SET NULL ON UPDATE CASCADE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    -- Constraints
    CONSTRAINT uq_system_config_key UNIQUE (config_key)
);

-- Index for FK lookups
CREATE INDEX IF NOT EXISTS idx_system_configurations_updated_by ON system_configurations (updated_by);

-- Triggers
CREATE TRIGGER trg_system_configurations_updated_at
    BEFORE UPDATE ON system_configurations
    FOR EACH ROW
    EXECUTE FUNCTION fn_set_updated_at();

-- Comments
COMMENT ON TABLE system_configurations IS 'Global key-value dynamic feature toggles and platform settings';
COMMENT ON COLUMN system_configurations.id IS 'Primary Key UUID v4';
COMMENT ON COLUMN system_configurations.config_key IS 'Unique configuration string key';
COMMENT ON COLUMN system_configurations.config_value IS 'JSONB value object representing configuration structure';
COMMENT ON COLUMN system_configurations.updated_by IS 'Foreign Key to users table (Admin who edited configuration)';

COMMIT;

-- ==========================================
-- DOWN MIGRATION (ROLLBACK SQL)
-- ==========================================
/*
BEGIN;
DROP TRIGGER IF EXISTS trg_system_configurations_updated_at ON system_configurations;
DROP INDEX IF EXISTS idx_system_configurations_updated_by;
DROP TABLE IF EXISTS system_configurations CASCADE;
COMMIT;
*/
