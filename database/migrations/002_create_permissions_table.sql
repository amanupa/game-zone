-- Migration: 002_create_permissions_table.sql
-- Table: permissions
-- Description: Creates the permissions table for system granular permissions.

-- ==========================================
-- UP MIGRATION
-- ==========================================
BEGIN;

CREATE TABLE IF NOT EXISTS permissions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(100) NOT NULL,
    module VARCHAR(50) NOT NULL,
    description TEXT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_permissions_name UNIQUE (name)
);

-- Triggers
CREATE TRIGGER trg_permissions_updated_at
    BEFORE UPDATE ON permissions
    FOR EACH ROW
    EXECUTE FUNCTION fn_set_updated_at();

-- Comments
COMMENT ON TABLE permissions IS 'Granular system permissions for authorization enforcement';
COMMENT ON COLUMN permissions.id IS 'Primary Key UUID v4';
COMMENT ON COLUMN permissions.name IS 'Unique permission key (e.g. events:create)';
COMMENT ON COLUMN permissions.module IS 'System module group tag';
COMMENT ON COLUMN permissions.description IS 'Detailed description of what permission permits';
COMMENT ON COLUMN permissions.created_at IS 'Record creation timestamp';
COMMENT ON COLUMN permissions.updated_at IS 'Last update timestamp';

COMMIT;

-- ==========================================
-- DOWN MIGRATION (ROLLBACK SQL)
-- ==========================================
/*
BEGIN;
DROP TRIGGER IF EXISTS trg_permissions_updated_at ON permissions;
DROP TABLE IF EXISTS permissions CASCADE;
COMMIT;
*/
