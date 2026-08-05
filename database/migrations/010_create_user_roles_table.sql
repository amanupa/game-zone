-- Migration: 010_create_user_roles_table.sql
-- Table: user_roles
-- Description: Creates junction table mapping users to assigned RBAC roles.

-- ==========================================
-- UP MIGRATION
-- ==========================================
BEGIN;

CREATE TABLE IF NOT EXISTS user_roles (
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE ON UPDATE CASCADE,
    role_id UUID NOT NULL REFERENCES roles(id) ON DELETE CASCADE ON UPDATE CASCADE,
    assigned_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    assigned_by UUID NULL REFERENCES users(id) ON DELETE SET NULL ON UPDATE CASCADE,
    PRIMARY KEY (user_id, role_id)
);

-- Index for FK reverse lookups
CREATE INDEX IF NOT EXISTS idx_user_roles_role_id ON user_roles (role_id);

-- Comments
COMMENT ON TABLE user_roles IS 'Junction mapping table between users and assigned system roles';
COMMENT ON COLUMN user_roles.user_id IS 'Foreign Key to users table';
COMMENT ON COLUMN user_roles.role_id IS 'Foreign Key to roles table';
COMMENT ON COLUMN user_roles.assigned_by IS 'Administrator ID who assigned the role';

COMMIT;

-- ==========================================
-- DOWN MIGRATION (ROLLBACK SQL)
-- ==========================================
/*
BEGIN;
DROP INDEX IF EXISTS idx_user_roles_role_id;
DROP TABLE IF EXISTS user_roles CASCADE;
COMMIT;
*/
