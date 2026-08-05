-- Migration: 008_create_role_permissions_table.sql
-- Table: role_permissions
-- Description: Creates junction table mapping roles to permissions.

-- ==========================================
-- UP MIGRATION
-- ==========================================
BEGIN;

CREATE TABLE IF NOT EXISTS role_permissions (
    role_id UUID NOT NULL REFERENCES roles(id) ON DELETE CASCADE ON UPDATE CASCADE,
    permission_id UUID NOT NULL REFERENCES permissions(id) ON DELETE CASCADE ON UPDATE CASCADE,
    PRIMARY KEY (role_id, permission_id)
);

-- Index for FK reverse lookups
CREATE INDEX IF NOT EXISTS idx_role_permissions_perm_id ON role_permissions (permission_id);

-- Comments
COMMENT ON TABLE role_permissions IS 'Junction mapping table between roles and granular system permissions';
COMMENT ON COLUMN role_permissions.role_id IS 'Foreign Key to roles table';
COMMENT ON COLUMN role_permissions.permission_id IS 'Foreign Key to permissions table';

COMMIT;

-- ==========================================
-- DOWN MIGRATION (ROLLBACK SQL)
-- ==========================================
/*
BEGIN;
DROP INDEX IF EXISTS idx_role_permissions_perm_id;
DROP TABLE IF EXISTS role_permissions CASCADE;
COMMIT;
*/
