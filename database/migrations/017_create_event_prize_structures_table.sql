-- Migration: 017_create_event_prize_structures_table.sql
-- Table: event_prize_structures
-- Description: Creates event_prize_structures table with SMALLINT datatypes for rank ranges.

-- ==========================================
-- UP MIGRATION
-- ==========================================
BEGIN;

CREATE TABLE IF NOT EXISTS event_prize_structures (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    event_id UUID NOT NULL REFERENCES events(id) ON DELETE CASCADE ON UPDATE CASCADE,
    rank_min SMALLINT NOT NULL,
    rank_max SMALLINT NOT NULL,
    prize_amount NUMERIC(15,2) NOT NULL DEFAULT 0.00,
    percentage_share NUMERIC(5,2) NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    -- Constraints
    CONSTRAINT chk_prize_rank_range CHECK (rank_min > 0 AND rank_max >= rank_min),
    CONSTRAINT chk_prize_amount_positive CHECK (prize_amount >= 0.00),
    CONSTRAINT chk_prize_percentage CHECK (percentage_share IS NULL OR (percentage_share >= 0.00 AND percentage_share <= 100.00))
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_event_prize_structures_event ON event_prize_structures (event_id, rank_min);

-- Triggers
CREATE TRIGGER trg_event_prize_structures_updated_at
    BEFORE UPDATE ON event_prize_structures
    FOR EACH ROW
    EXECUTE FUNCTION fn_set_updated_at();

-- Comments
COMMENT ON TABLE event_prize_structures IS 'Prize pool breakdown per rank placement range for tournaments';
COMMENT ON COLUMN event_prize_structures.id IS 'Primary Key UUID v4';
COMMENT ON COLUMN event_prize_structures.event_id IS 'Foreign Key to events table';
COMMENT ON COLUMN event_prize_structures.rank_min IS 'Starting rank in placement range as SMALLINT (e.g. 1)';
COMMENT ON COLUMN event_prize_structures.rank_max IS 'Ending rank in placement range as SMALLINT (e.g. 1 or 3)';
COMMENT ON COLUMN event_prize_structures.prize_amount IS 'Guaranteed payout cash amount per player/team';

COMMIT;

-- ==========================================
-- DOWN MIGRATION (ROLLBACK SQL)
-- ==========================================
/*
BEGIN;
DROP TRIGGER IF EXISTS trg_event_prize_structures_updated_at ON event_prize_structures;
DROP INDEX IF EXISTS idx_event_prize_structures_event;
DROP TABLE IF EXISTS event_prize_structures CASCADE;
COMMIT;
*/
