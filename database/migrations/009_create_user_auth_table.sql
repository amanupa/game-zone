-- Migration: 009_create_user_auth_table.sql
-- Table: user_auth
-- Description: Creates user_auth table and auth_provider_enum for local & OAuth authentication credentials.

-- ==========================================
-- UP MIGRATION
-- ==========================================
BEGIN;

-- Custom Enum
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'auth_provider_enum') THEN
        CREATE TYPE auth_provider_enum AS ENUM ('LOCAL', 'GOOGLE', 'APPLE', 'DISCORD');
    END IF;
END $$;

COMMENT ON TYPE auth_provider_enum IS 'Supported login authentication provider types';

CREATE TABLE IF NOT EXISTS user_auth (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE ON UPDATE CASCADE,
    provider auth_provider_enum NOT NULL DEFAULT 'LOCAL',
    provider_user_id VARCHAR(255) NULL,
    refresh_token_hash VARCHAR(255) NULL,
    mfa_enabled BOOLEAN NOT NULL DEFAULT FALSE,
    mfa_secret VARCHAR(255) NULL,
    last_login_at TIMESTAMPTZ NULL,
    last_login_ip INET NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_user_auth_user_id ON user_auth (user_id);
CREATE INDEX IF NOT EXISTS idx_user_auth_provider ON user_auth (provider, provider_user_id);

-- Triggers
CREATE TRIGGER trg_user_auth_updated_at
    BEFORE UPDATE ON user_auth
    FOR EACH ROW
    EXECUTE FUNCTION fn_set_updated_at();

-- Comments
COMMENT ON TABLE user_auth IS 'Authentication credentials and OAuth identity provider linkage';
COMMENT ON COLUMN user_auth.id IS 'Primary Key UUID v4';
COMMENT ON COLUMN user_auth.user_id IS 'Foreign Key to users table';
COMMENT ON COLUMN user_auth.provider IS 'Authentication identity provider enum';
COMMENT ON COLUMN user_auth.provider_user_id IS 'External OAuth provider unique subject ID';
COMMENT ON COLUMN user_auth.mfa_enabled IS 'TOTP Multi-factor authentication flag';

COMMIT;

-- ==========================================
-- DOWN MIGRATION (ROLLBACK SQL)
-- ==========================================
/*
BEGIN;
DROP TRIGGER IF EXISTS trg_user_auth_updated_at ON user_auth;
DROP INDEX IF EXISTS idx_user_auth_provider;
DROP INDEX IF EXISTS idx_user_auth_user_id;
DROP TABLE IF EXISTS user_auth CASCADE;
DROP TYPE IF EXISTS auth_provider_enum CASCADE;
COMMIT;
*/
