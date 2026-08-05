-- Migration: 019_create_match_rooms_table.sql
-- Table: match_rooms
-- Description: Creates match_rooms table and room_status_enum for game lobby room credentials.

-- ==========================================
-- UP MIGRATION
-- ==========================================
BEGIN;

-- Custom Enum
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'room_status_enum') THEN
        CREATE TYPE room_status_enum AS ENUM (
            'CREATED', 'CREDENTIALS_DISTRIBUTED', 'MATCH_STARTED', 'MATCH_ENDED', 'ABORTED'
        );
    END IF;
END $$;

COMMENT ON TYPE room_status_enum IS 'Lifecycle states for custom game lobbies';

CREATE TABLE IF NOT EXISTS match_rooms (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    event_id UUID NOT NULL REFERENCES events(id) ON DELETE CASCADE ON UPDATE CASCADE,
    room_name VARCHAR(100) NOT NULL,
    room_id_code VARCHAR(255) NOT NULL,
    room_password VARCHAR(255) NOT NULL,
    status room_status_enum NOT NULL DEFAULT 'CREATED',
    scheduled_time TIMESTAMPTZ NOT NULL,
    started_at TIMESTAMPTZ NULL,
    ended_at TIMESTAMPTZ NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Composite Index
CREATE INDEX IF NOT EXISTS idx_match_rooms_event ON match_rooms (event_id, status);

-- Triggers
CREATE TRIGGER trg_match_rooms_updated_at
    BEFORE UPDATE ON match_rooms
    FOR EACH ROW
    EXECUTE FUNCTION fn_set_updated_at();

-- Comments
COMMENT ON TABLE match_rooms IS 'Game lobby custom room credentials (Room ID & Password)';
COMMENT ON COLUMN match_rooms.id IS 'Primary Key UUID v4';
COMMENT ON COLUMN match_rooms.event_id IS 'Foreign Key to events table';
COMMENT ON COLUMN match_rooms.room_id_code IS 'Encrypted Room ID code string';
COMMENT ON COLUMN match_rooms.room_password IS 'Encrypted Room password string';
COMMENT ON COLUMN match_rooms.status IS 'Lobby status lifecycle enum';

COMMIT;

-- ==========================================
-- DOWN MIGRATION (ROLLBACK SQL)
-- ==========================================
/*
BEGIN;
DROP TRIGGER IF EXISTS trg_match_rooms_updated_at ON match_rooms;
DROP INDEX IF EXISTS idx_match_rooms_event;
DROP TABLE IF EXISTS match_rooms CASCADE;
DROP TYPE IF EXISTS room_status_enum CASCADE;
COMMIT;
*/
