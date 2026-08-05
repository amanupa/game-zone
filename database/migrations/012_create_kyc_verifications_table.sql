-- Migration: 012_create_kyc_verifications_table.sql
-- Table: kyc_verifications
-- Description: Creates kyc_verifications table for user identity compliance records with verifier index.

-- ==========================================
-- UP MIGRATION
-- ==========================================
BEGIN;

CREATE TABLE IF NOT EXISTS kyc_verifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE ON UPDATE CASCADE,
    id_type VARCHAR(50) NOT NULL,
    id_number_hash VARCHAR(255) NOT NULL,
    document_url TEXT NOT NULL,
    status kyc_status_enum NOT NULL DEFAULT 'PENDING',
    rejection_reason TEXT NULL,
    verified_by UUID NULL REFERENCES users(id) ON DELETE SET NULL ON UPDATE CASCADE,
    verified_at TIMESTAMPTZ NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_kyc_verifications_user ON kyc_verifications (user_id);
CREATE INDEX IF NOT EXISTS idx_kyc_verifications_status ON kyc_verifications (status);
CREATE INDEX IF NOT EXISTS idx_kyc_verifications_verified_by ON kyc_verifications (verified_by);

-- Triggers
CREATE TRIGGER trg_kyc_verifications_updated_at
    BEFORE UPDATE ON kyc_verifications
    FOR EACH ROW
    EXECUTE FUNCTION fn_set_updated_at();

-- Comments
COMMENT ON TABLE kyc_verifications IS 'Government identity compliance and verification records';
COMMENT ON COLUMN kyc_verifications.id IS 'Primary Key UUID v4';
COMMENT ON COLUMN kyc_verifications.user_id IS 'Foreign Key to users table';
COMMENT ON COLUMN kyc_verifications.id_type IS 'Government ID document type (e.g. Aadhaar, PAN, Passport)';
COMMENT ON COLUMN kyc_verifications.id_number_hash IS 'Cryptographic SHA-256 hash of document ID number';
COMMENT ON COLUMN kyc_verifications.document_url IS 'AES-256 encrypted storage URL of ID proof image';

COMMIT;

-- ==========================================
-- DOWN MIGRATION (ROLLBACK SQL)
-- ==========================================
/*
BEGIN;
DROP TRIGGER IF EXISTS trg_kyc_verifications_updated_at ON kyc_verifications;
DROP INDEX IF EXISTS idx_kyc_verifications_verified_by;
DROP INDEX IF EXISTS idx_kyc_verifications_status;
DROP INDEX IF EXISTS idx_kyc_verifications_user;
DROP TABLE IF EXISTS kyc_verifications CASCADE;
COMMIT;
*/
