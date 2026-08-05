-- Migration: 027_create_room_allocations_table.sql
-- Table: room_allocations
-- Description: Creates declarative range-partitioned room_allocations table with SMALLINT slot datatypes and FK indexes.

-- ==========================================
-- UP MIGRATION
-- ==========================================
BEGIN;

CREATE TABLE IF NOT EXISTS room_allocations (
    id UUID NOT NULL DEFAULT gen_random_uuid(),
    room_id UUID NOT NULL REFERENCES match_rooms(id) ON DELETE CASCADE ON UPDATE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE ON UPDATE CASCADE,
    team_id UUID NULL REFERENCES teams(id) ON DELETE SET NULL ON UPDATE CASCADE,
    slot_number SMALLINT NOT NULL,
    seat_number SMALLINT NOT NULL,
    credentials_sent_at TIMESTAMPTZ NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id, created_at)
) PARTITION BY RANGE (created_at);

-- Create Default Partition for fallback
CREATE TABLE IF NOT EXISTS room_allocations_default 
    PARTITION OF room_allocations DEFAULT;

-- Create Monthly Partition for Current Period (2026-07)
CREATE TABLE IF NOT EXISTS room_allocations_y2026m07 
    PARTITION OF room_allocations 
    FOR VALUES FROM ('2026-07-01 00:00:00+00') TO ('2026-08-01 00:00:00+00');

-- Composite & FK Indexes
CREATE INDEX IF NOT EXISTS idx_room_allocations_room ON room_allocations (room_id, slot_number, seat_number);
CREATE INDEX IF NOT EXISTS idx_room_allocations_user ON room_allocations (user_id);
CREATE INDEX IF NOT EXISTS idx_room_allocations_team ON room_allocations (team_id) WHERE team_id IS NOT NULL;

-- Comments
COMMENT ON TABLE room_allocations IS 'Lobby seat assignments partitioned monthly by created_at for 100M+ allocation capacity';
COMMENT ON COLUMN room_allocations.id IS 'Primary Key Part UUID v4';
COMMENT ON COLUMN room_allocations.room_id IS 'Foreign Key to match_rooms table';
COMMENT ON COLUMN room_allocations.user_id IS 'Foreign Key to users table';
COMMENT ON COLUMN room_allocations.slot_number IS 'Assigned team slot number in game lobby as SMALLINT (1-25)';
COMMENT ON COLUMN room_allocations.seat_number IS 'Assigned player position seat number in team as SMALLINT (1-4)';

COMMIT;

-- ==========================================
-- DOWN MIGRATION (ROLLBACK SQL)
-- ==========================================
/*
BEGIN;
DROP INDEX IF EXISTS idx_room_allocations_team;
DROP INDEX IF EXISTS idx_room_allocations_user;
DROP INDEX IF EXISTS idx_room_allocations_room;
DROP TABLE IF EXISTS room_allocations CASCADE;
COMMIT;
*/
