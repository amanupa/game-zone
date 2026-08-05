-- Migration: 006_create_users_table.sql
-- Table: users
-- Description: Creates master users table, kyc_status_enum, user_role_enum, constraints, and partial unique indexes.

-- ==========================================
-- UP MIGRATION
-- ==========================================
BEGIN;

-- Custom Enums
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'kyc_status_enum') THEN
        CREATE TYPE kyc_status_enum AS ENUM ('UNVERIFIED', 'PENDING', 'VERIFIED', 'REJECTED');
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'user_role_enum') THEN
        CREATE TYPE user_role_enum AS ENUM ('PLAYER', 'ORGANIZER', 'MODERATOR', 'ADMIN', 'SUPER_ADMIN');
    END IF;
END $$;

COMMENT ON TYPE kyc_status_enum IS 'Government identity verification status levels';
COMMENT ON TYPE user_role_enum IS 'System role level classification for RBAC';

CREATE TABLE IF NOT EXISTS users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    username VARCHAR(50) NOT NULL,
    email VARCHAR(255) NOT NULL,
    phone VARCHAR(20) NULL,
    password_hash VARCHAR(255) NULL,
    first_name VARCHAR(50) NULL,
    last_name VARCHAR(50) NULL,
    avatar_url TEXT NULL,
    bio TEXT NULL,
    kyc_status kyc_status_enum NOT NULL DEFAULT 'UNVERIFIED',
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    is_banned BOOLEAN NOT NULL DEFAULT FALSE,
    ban_reason TEXT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMPTZ NULL,
    created_by UUID NULL REFERENCES users(id) ON DELETE SET NULL ON UPDATE CASCADE,
    updated_by UUID NULL REFERENCES users(id) ON DELETE SET NULL ON UPDATE CASCADE,

    -- Format Validation CHECK Constraints
    CONSTRAINT chk_users_email_format CHECK (email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$'),
    CONSTRAINT chk_users_phone_format CHECK (phone IS NULL OR phone ~* '^\+?[1-9]\d{1,14}$')
);

-- DBA Optimization: Partial Unique Indexes (Prevents duplicate index overhead and allows soft-deleted handle recovery)
CREATE UNIQUE INDEX IF NOT EXISTS uq_users_username ON users (username) WHERE deleted_at IS NULL;
CREATE UNIQUE INDEX IF NOT EXISTS uq_users_email ON users (email) WHERE deleted_at IS NULL;
CREATE UNIQUE INDEX IF NOT EXISTS uq_users_phone ON users (phone) WHERE deleted_at IS NULL AND phone IS NOT NULL;

-- Additional Search Indexes
CREATE INDEX IF NOT EXISTS idx_users_kyc_status ON users (kyc_status) WHERE deleted_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_users_created_by ON users (created_by);
CREATE INDEX IF NOT EXISTS idx_users_updated_by ON users (updated_by);

-- Triggers
CREATE TRIGGER trg_users_updated_at
    BEFORE UPDATE ON users
    FOR EACH ROW
    EXECUTE FUNCTION fn_set_updated_at();

-- Comments
COMMENT ON TABLE users IS 'Master table containing player and administrative user account records';
COMMENT ON COLUMN users.id IS 'Primary Key UUID v4 generated via gen_random_uuid()';
COMMENT ON COLUMN users.username IS 'Unique player handle / username (enforced for active users)';
COMMENT ON COLUMN users.email IS 'Unique user email address (enforced for active users)';
COMMENT ON COLUMN users.phone IS 'Unique E.164 phone number string for SMS alerts';
COMMENT ON COLUMN users.password_hash IS 'Argon2id cryptographic hash (NULL for social OAuth users)';
COMMENT ON COLUMN users.kyc_status IS 'Identity compliance verification status';
COMMENT ON COLUMN users.is_banned IS 'Administrative security block status';
COMMENT ON COLUMN users.deleted_at IS 'Soft delete timestamp for GDPR compliance';

COMMIT;

-- ==========================================
-- DOWN MIGRATION (ROLLBACK SQL)
-- ==========================================
/*
BEGIN;
DROP TRIGGER IF EXISTS trg_users_updated_at ON users;
DROP INDEX IF EXISTS idx_users_updated_by;
DROP INDEX IF EXISTS idx_users_created_by;
DROP INDEX IF EXISTS idx_users_kyc_status;
DROP INDEX IF EXISTS uq_users_phone;
DROP INDEX IF EXISTS uq_users_email;
DROP INDEX IF EXISTS uq_users_username;
DROP TABLE IF EXISTS users CASCADE;
DROP TYPE IF EXISTS user_role_enum CASCADE;
DROP TYPE IF EXISTS kyc_status_enum CASCADE;
COMMIT;
*/
