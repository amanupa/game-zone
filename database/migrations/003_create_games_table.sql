-- Migration: 003_create_games_table.sql
-- Table: games
-- Description: Creates the games table and platform enum for supported games catalog.

-- ==========================================
-- UP MIGRATION
-- ==========================================
BEGIN;

-- Custom Enum
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'game_platform_enum') THEN
        CREATE TYPE game_platform_enum AS ENUM ('MOBILE', 'PC', 'CONSOLE', 'CROSS_PLATFORM');
    END IF;
END $$;

COMMENT ON TYPE game_platform_enum IS 'Supported gaming device platform classifications';

CREATE TABLE IF NOT EXISTS games (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    code VARCHAR(50) NOT NULL,
    name VARCHAR(100) NOT NULL,
    publisher VARCHAR(100) NOT NULL,
    platform game_platform_enum NOT NULL DEFAULT 'MOBILE',
    icon_url TEXT NULL,
    banner_url TEXT NULL,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMPTZ NULL,
    CONSTRAINT uq_games_code UNIQUE (code)
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_games_active ON games (is_active) WHERE deleted_at IS NULL;

-- Triggers
CREATE TRIGGER trg_games_updated_at
    BEFORE UPDATE ON games
    FOR EACH ROW
    EXECUTE FUNCTION fn_set_updated_at();

-- Comments
COMMENT ON TABLE games IS 'Supported game catalog for tournaments and player identities';
COMMENT ON COLUMN games.id IS 'Primary Key UUID v4';
COMMENT ON COLUMN games.code IS 'Unique game identifier code (e.g. BGMI, FREE_FIRE, COD)';
COMMENT ON COLUMN games.name IS 'Full official game title';
COMMENT ON COLUMN games.publisher IS 'Publisher organization name';
COMMENT ON COLUMN games.platform IS 'Platform category enum';
COMMENT ON COLUMN games.is_active IS 'System activity status flag';

COMMIT;

-- ==========================================
-- DOWN MIGRATION (ROLLBACK SQL)
-- ==========================================
/*
BEGIN;
DROP TRIGGER IF EXISTS trg_games_updated_at ON games;
DROP INDEX IF EXISTS idx_games_active;
DROP TABLE IF EXISTS games CASCADE;
DROP TYPE IF EXISTS game_platform_enum CASCADE;
COMMIT;
*/
