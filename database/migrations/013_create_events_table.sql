-- Migration: 013_create_events_table.sql
-- Table: events
-- Description: Creates events table, tournament enums, outbox trigger, composite, GIN, and partial unique indexes.

-- ==========================================
-- UP MIGRATION
-- ==========================================
BEGIN;

-- Custom Enums
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'event_status_enum') THEN
        CREATE TYPE event_status_enum AS ENUM (
            'DRAFT', 'PUBLISHED', 'REGISTRATION_OPEN', 'REGISTRATION_CLOSED', 
            'IN_PROGRESS', 'RESULT_SETTLED', 'COMPLETED', 'CANCELLED'
        );
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'event_format_enum') THEN
        CREATE TYPE event_format_enum AS ENUM ('SOLO', 'DUO', 'SQUAD', 'CUSTOM');
    END IF;
END $$;

COMMENT ON TYPE event_status_enum IS 'Lifecycle state machine for tournaments';
COMMENT ON TYPE event_format_enum IS 'Tournament slot format composition';

CREATE TABLE IF NOT EXISTS events (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    game_id UUID NOT NULL REFERENCES games(id) ON DELETE RESTRICT ON UPDATE CASCADE,
    game_mode_id UUID NOT NULL REFERENCES game_modes(id) ON DELETE RESTRICT ON UPDATE CASCADE,
    title VARCHAR(150) NOT NULL,
    slug VARCHAR(180) NOT NULL,
    description TEXT NULL,
    banner_url TEXT NULL,
    entry_fee NUMERIC(15,2) NOT NULL DEFAULT 0.00,
    prize_pool NUMERIC(15,2) NOT NULL DEFAULT 0.00,
    max_slots INTEGER NOT NULL,
    filled_slots INTEGER NOT NULL DEFAULT 0,
    format event_format_enum NOT NULL DEFAULT 'SOLO',
    status event_status_enum NOT NULL DEFAULT 'DRAFT',
    registration_start_at TIMESTAMPTZ NOT NULL,
    registration_end_at TIMESTAMPTZ NOT NULL,
    tournament_start_at TIMESTAMPTZ NOT NULL,
    tournament_end_at TIMESTAMPTZ NULL,
    rules_json JSONB NULL DEFAULT '{}',
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMPTZ NULL,
    created_by UUID NULL REFERENCES users(id) ON DELETE SET NULL ON UPDATE CASCADE,
    updated_by UUID NULL REFERENCES users(id) ON DELETE SET NULL ON UPDATE CASCADE,

    -- Constraints
    CONSTRAINT chk_events_entry_fee_positive CHECK (entry_fee >= 0.00),
    CONSTRAINT chk_events_prize_pool_positive CHECK (prize_pool >= 0.00),
    CONSTRAINT chk_events_slots_sanity CHECK (max_slots > 0 AND filled_slots >= 0 AND filled_slots <= max_slots),
    CONSTRAINT chk_events_schedule_order CHECK (
        registration_end_at > registration_start_at 
        AND tournament_start_at >= registration_end_at 
        AND (tournament_end_at IS NULL OR tournament_end_at > tournament_start_at)
    )
);

-- DBA Optimization: Partial Unique Index on slug (WHERE deleted_at IS NULL)
CREATE UNIQUE INDEX IF NOT EXISTS uq_events_slug ON events (slug) WHERE deleted_at IS NULL;

-- Indexes
CREATE INDEX IF NOT EXISTS idx_events_game_status ON events (game_id, status, registration_start_at) WHERE deleted_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_events_status_schedule ON events (status, tournament_start_at) WHERE deleted_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_events_created_by ON events (created_by);
CREATE INDEX IF NOT EXISTS idx_events_rules_gin ON events USING GIN (rules_json);

-- Triggers
CREATE TRIGGER trg_events_updated_at
    BEFORE UPDATE ON events
    FOR EACH ROW
    EXECUTE FUNCTION fn_set_updated_at();

-- Outbox Status Change Trigger Function & Trigger
CREATE OR REPLACE FUNCTION fn_trg_outbox_event_status()
RETURNS TRIGGER AS $$
BEGIN
    IF (OLD.status IS DISTINCT FROM NEW.status) THEN
        INSERT INTO outbox_events (
            aggregate_type, aggregate_id, event_type, payload_json, status
        ) VALUES (
            'events', NEW.id, 'gamezone.events.status_changed',
            jsonb_build_object(
                'event_id', NEW.id,
                'old_status', OLD.status,
                'new_status', NEW.status,
                'game_id', NEW.game_id,
                'timestamp', CURRENT_TIMESTAMP
            ),
            'PENDING'
        );
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_events_outbox_status
    AFTER UPDATE ON events
    FOR EACH ROW
    EXECUTE FUNCTION fn_trg_outbox_event_status();

-- Comments
COMMENT ON TABLE events IS 'Tournament master catalog and state machine tracking';
COMMENT ON COLUMN events.id IS 'Primary Key UUID v4';
COMMENT ON COLUMN events.game_id IS 'Foreign Key to games table';
COMMENT ON COLUMN events.game_mode_id IS 'Foreign Key to game_modes table';
COMMENT ON COLUMN events.title IS 'Tournament title string';
COMMENT ON COLUMN events.slug IS 'Unique SEO-friendly URL slug (enforced for active events)';
COMMENT ON COLUMN events.entry_fee IS 'Entry fee in base currency (CHECK >= 0)';
COMMENT ON COLUMN events.prize_pool IS 'Total guaranteed prize pool (CHECK >= 0)';
COMMENT ON COLUMN events.max_slots IS 'Total registration capacity limit';
COMMENT ON COLUMN events.filled_slots IS 'Currently claimed slots (CHECK 0 <= filled <= max)';
COMMENT ON COLUMN events.status IS 'Tournament lifecycle state machine status';
COMMENT ON COLUMN events.rules_json IS 'JSONB document for dynamic rule parameters';

COMMIT;

-- ==========================================
-- DOWN MIGRATION (ROLLBACK SQL)
-- ==========================================
/*
BEGIN;
DROP TRIGGER IF EXISTS trg_events_outbox_status ON events;
DROP FUNCTION IF EXISTS fn_trg_outbox_event_status();
DROP TRIGGER IF EXISTS trg_events_updated_at ON events;
DROP INDEX IF EXISTS idx_events_rules_gin;
DROP INDEX IF EXISTS idx_events_created_by;
DROP INDEX IF EXISTS idx_events_status_schedule;
DROP INDEX IF EXISTS idx_events_game_status;
DROP INDEX IF EXISTS uq_events_slug;
DROP TABLE IF EXISTS events CASCADE;
DROP TYPE IF EXISTS event_format_enum CASCADE;
DROP TYPE IF EXISTS event_status_enum CASCADE;
COMMIT;
*/
