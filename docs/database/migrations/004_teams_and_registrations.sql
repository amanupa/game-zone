-- Game Zone PostgreSQL Migration: 004_teams_and_registrations.sql
-- Description: Teams, roster memberships, and tournament event registrations.

BEGIN;

-- 1. Teams Table
CREATE TABLE teams (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(100) NOT NULL,
    tag VARCHAR(10) NOT NULL,
    captain_id UUID NOT NULL,
    logo_url TEXT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMPTZ NULL,
    CONSTRAINT uq_teams_tag UNIQUE (tag),
    CONSTRAINT fk_teams_captain FOREIGN KEY (captain_id) REFERENCES users(id) ON DELETE RESTRICT ON UPDATE CASCADE
);

-- 2. Team Members Table
CREATE TABLE team_members (
    team_id UUID NOT NULL,
    user_id UUID NOT NULL,
    role VARCHAR(20) NOT NULL DEFAULT 'MEMBER',
    joined_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (team_id, user_id),
    CONSTRAINT fk_team_members_team FOREIGN KEY (team_id) REFERENCES teams(id) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_team_members_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE ON UPDATE CASCADE
);

-- 3. Event Registrations Table
CREATE TABLE event_registrations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    event_id UUID NOT NULL,
    user_id UUID NOT NULL,
    team_id UUID NULL,
    registration_status registration_status_enum NOT NULL DEFAULT 'PENDING',
    payment_id UUID NULL,
    slot_number INTEGER NULL,
    registered_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMPTZ NULL,
    CONSTRAINT uq_event_user_reg UNIQUE (event_id, user_id),
    CONSTRAINT fk_event_reg_event FOREIGN KEY (event_id) REFERENCES events(id) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_event_reg_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_event_reg_team FOREIGN KEY (team_id) REFERENCES teams(id) ON DELETE RESTRICT ON UPDATE CASCADE
);

-- Indexes
CREATE INDEX idx_teams_captain ON teams (captain_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_teams_tag ON teams (tag) WHERE deleted_at IS NULL;
CREATE INDEX idx_event_registrations_event_user ON event_registrations (event_id, user_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_event_registrations_status ON event_registrations (event_id, registration_status) WHERE deleted_at IS NULL;
CREATE INDEX idx_event_registrations_user ON event_registrations (user_id) WHERE deleted_at IS NULL;

COMMENT ON TABLE teams IS 'Esports player teams and squads';
COMMENT ON TABLE event_registrations IS 'Tournament registrations and slot reservations';

COMMIT;
