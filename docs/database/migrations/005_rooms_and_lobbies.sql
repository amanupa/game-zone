-- Game Zone PostgreSQL Migration: 005_rooms_and_lobbies.sql
-- Description: Match rooms credentials distribution and player seating allocations.

BEGIN;

-- 1. Match Rooms Table
CREATE TABLE match_rooms (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    event_id UUID NOT NULL,
    room_name VARCHAR(100) NOT NULL,
    room_id_code VARCHAR(255) NOT NULL,
    room_password VARCHAR(255) NOT NULL,
    status room_status_enum NOT NULL DEFAULT 'CREATED',
    scheduled_time TIMESTAMPTZ NOT NULL,
    started_at TIMESTAMPTZ NULL,
    ended_at TIMESTAMPTZ NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_match_rooms_event FOREIGN KEY (event_id) REFERENCES events(id) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT chk_match_rooms_timestamps CHECK (ended_at IS NULL OR ended_at >= started_at)
);

-- 2. Room Allocations Table
CREATE TABLE room_allocations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    room_id UUID NOT NULL,
    user_id UUID NOT NULL,
    team_id UUID NULL,
    slot_number INTEGER NOT NULL,
    seat_number INTEGER NOT NULL,
    credentials_sent_at TIMESTAMPTZ NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_room_allocation_seat UNIQUE (room_id, slot_number, seat_number),
    CONSTRAINT fk_room_allocations_room FOREIGN KEY (room_id) REFERENCES match_rooms(id) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_room_allocations_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_room_allocations_team FOREIGN KEY (team_id) REFERENCES teams(id) ON DELETE SET NULL ON UPDATE CASCADE,
    CONSTRAINT chk_room_allocations_position CHECK (slot_number > 0 AND seat_number > 0)
);

-- Indexes
CREATE INDEX idx_match_rooms_event ON match_rooms (event_id, status);
CREATE INDEX idx_room_allocations_room ON room_allocations (room_id, slot_number, seat_number);
CREATE INDEX idx_room_allocations_user ON room_allocations (user_id);

COMMENT ON TABLE match_rooms IS 'Game lobby room credentials (Room ID and Room Password)';
COMMENT ON TABLE room_allocations IS 'Player seating allocation per match room';

COMMIT;
