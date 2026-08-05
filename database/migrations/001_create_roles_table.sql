-- Migration: 001_create_roles_table.sql
-- Table: roles
-- Description: Creates the roles table for Role-Based Access Control (RBAC).

-- ==========================================
-- UP MIGRATION
-- ==========================================
BEGIN;

CREATE TABLE IF NOT EXISTS roles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(50) NOT NULL,
    description TEXT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_roles_name UNIQUE (name)
);

-- Triggers
CREATE TRIGGER trg_roles_updated_at
    BEFORE UPDATE ON roles
    FOR EACH ROW
    EXECUTE FUNCTION fn_set_updated_at();

-- Comments
COMMENT ON TABLE roles IS 'Role definitions for Role-Based Access Control (RBAC)';
COMMENT ON COLUMN roles.id IS 'Primary Key UUID v4';
COMMENT ON COLUMN roles.name IS 'Unique role identifier name (e.g. ADMIN, PLAYER)';
COMMENT ON COLUMN roles.description IS 'Description of role duties and privileges';
COMMENT ON COLUMN roles.created_at IS 'Record creation timestamp';
COMMENT ON COLUMN roles.updated_at IS 'Last update timestamp';

COMMIT;

-- ==========================================
-- DOWN MIGRATION (ROLLBACK SQL)
-- ==========================================
/*
BEGIN;
DROP TRIGGER IF EXISTS trg_roles_updated_at ON roles;
DROP TABLE IF EXISTS roles CASCADE;
COMMIT;
*/
