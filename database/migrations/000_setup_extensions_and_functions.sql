-- Migration: 000_setup_extensions_and_functions.sql
-- Description: Enables pgcrypto extension and creates global helper functions.

-- ==========================================
-- UP MIGRATION
-- ==========================================
BEGIN;

-- Enable pgcrypto for UUID generation and cryptographic functions
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- Global helper function to automatically update updated_at timestamp columns
CREATE OR REPLACE FUNCTION fn_set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION fn_set_updated_at() IS 'Trigger function to automatically set updated_at column to current timestamp on record modification';

COMMIT;

-- ==========================================
-- DOWN MIGRATION (ROLLBACK SQL)
-- ==========================================
/*
BEGIN;
DROP FUNCTION IF EXISTS fn_set_updated_at() CASCADE;
DROP EXTENSION IF EXISTS "pgcrypto";
COMMIT;
*/
