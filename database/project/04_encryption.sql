-- PAKAR Tech Healthcare - Complete Encryption Setup
-- COS 20031 Database Design Project
-- Purpose: Enable pgcrypto and encrypt sensitive data
-- Author: Jason Hernando Kwee

BEGIN;

SET search_path TO app, public;

\echo '========================================'
\echo '🔒 PAKAR Tech Encryption Setup'
\echo '========================================'

-- ============================================================================
-- STEP 1: ENABLE PGCRYPTO EXTENSION
-- ============================================================================

\echo ''
\echo 'STEP 1: Enabling pgcrypto extension...'

CREATE EXTENSION IF NOT EXISTS pgcrypto;

COMMENT ON EXTENSION pgcrypto IS 'Cryptographic functions for PostgreSQL';

DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM pg_extension WHERE extname = 'pgcrypto') THEN
        RAISE NOTICE '✅ pgcrypto extension enabled';
    ELSE
        RAISE EXCEPTION '❌ Failed to enable pgcrypto extension';
    END IF;
END $$;

-- ============================================================================
-- STEP 2: ADD ENCRYPTED COLUMNS TO SENSITIVE TABLES
-- ============================================================================

\echo ''
\echo 'STEP 2: Adding encrypted columns to sensitive tables...'

-- Patient table: Encrypt address and emergency contact
ALTER TABLE app.patient 
    ADD COLUMN IF NOT EXISTS address_encrypted BYTEA,
    ADD COLUMN IF NOT EXISTS emergency_contact_name_encrypted BYTEA,
    ADD COLUMN IF NOT EXISTS emergency_contact_phone_encrypted BYTEA;

COMMENT ON COLUMN app.patient.address_encrypted IS 'Encrypted patient address using pgp_sym_encrypt';
COMMENT ON COLUMN app.patient.emergency_contact_name_encrypted IS 'Encrypted emergency contact name';
COMMENT ON COLUMN app.patient.emergency_contact_phone_encrypted IS 'Encrypted emergency phone number';

-- Doctor table: Encrypt phone number
ALTER TABLE app.doctor
    ADD COLUMN IF NOT EXISTS phone_encrypted BYTEA;

COMMENT ON COLUMN app.doctor.phone_encrypted IS 'Encrypted doctor phone number';

-- Prescription table: Encrypt doctor notes
ALTER TABLE app.prescription
    ADD COLUMN IF NOT EXISTS doctor_note_encrypted BYTEA;

COMMENT ON COLUMN app.prescription.doctor_note_encrypted IS 'Encrypted prescription notes';

DO $$
BEGIN
    RAISE NOTICE '✅ Added encrypted columns to 3 tables (patient, doctor, prescription)';
END $$;

-- ============================================================================
-- STEP 3: CREATE ENCRYPTION KEY MANAGEMENT TABLE
-- ============================================================================

\echo ''
\echo 'STEP 3: Setting up encryption key management...'

CREATE TABLE IF NOT EXISTS app.encryption_keys (
    key_id SERIAL PRIMARY KEY,
    key_name VARCHAR(50) UNIQUE NOT NULL,
    encryption_key TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT NOW(),
    expires_at TIMESTAMP
);

COMMENT ON TABLE app.encryption_keys IS 'Encryption key storage (⚠️ Use external KMS in production)';

-- Insert demo encryption key (⚠️ DEVELOPMENT ONLY)
INSERT INTO app.encryption_keys (key_name, encryption_key, expires_at)
VALUES (
    'master_key_v1',
    'pakar-tech-2024-secret-key-do-not-use-in-production',
    NOW() + INTERVAL '1 year'
)
ON CONFLICT (key_name) DO NOTHING;

DO $$
BEGIN
    RAISE NOTICE '✅ Encryption key table created';
    RAISE NOTICE '⚠️  WARNING: Using demo encryption key - replace with AWS KMS/Azure Key Vault in production';
END $$;

-- ============================================================================
-- STEP 4: CREATE ENCRYPTION/DECRYPTION FUNCTIONS
-- ============================================================================

\echo ''
\echo 'STEP 4: Creating encryption/decryption functions...'

-- Function: Encrypt text data
CREATE OR REPLACE FUNCTION app.encrypt_text(plain_text TEXT)
RETURNS BYTEA AS $$
DECLARE
    encryption_key TEXT;
BEGIN
    SELECT ek.encryption_key INTO encryption_key
    FROM app.encryption_keys ek
    WHERE ek.key_name = 'master_key_v1'
      AND (ek.expires_at IS NULL OR ek.expires_at > NOW())
    LIMIT 1;
    
    IF encryption_key IS NULL THEN
        RAISE EXCEPTION 'No valid encryption key found';
    END IF;
    
    RETURN pgp_sym_encrypt(plain_text, encryption_key);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON FUNCTION app.encrypt_text(TEXT) IS 'Encrypts plain text using AES-256 symmetric encryption';

-- Function: Decrypt text data
CREATE OR REPLACE FUNCTION app.decrypt_text(encrypted_data BYTEA)
RETURNS TEXT AS $$
DECLARE
    encryption_key TEXT;
BEGIN
    IF encrypted_data IS NULL THEN
        RETURN NULL;
    END IF;
    
    SELECT ek.encryption_key INTO encryption_key
    FROM app.encryption_keys ek
    WHERE ek.key_name = 'master_key_v1'
      AND (ek.expires_at IS NULL OR ek.expires_at > NOW())
    LIMIT 1;
    
    IF encryption_key IS NULL THEN
        RAISE EXCEPTION 'No valid decryption key found';
    END IF;
    
    RETURN pgp_sym_decrypt(encrypted_data, encryption_key);
EXCEPTION
    WHEN OTHERS THEN
        RAISE WARNING 'Decryption failed: %', SQLERRM;
        RETURN NULL;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON FUNCTION app.decrypt_text(BYTEA) IS 'Decrypts encrypted data back to plain text';

-- Function: Encrypt BIGINT (phone numbers)
CREATE OR REPLACE FUNCTION app.encrypt_bigint(plain_number BIGINT)
RETURNS BYTEA AS $$
BEGIN
    RETURN app.encrypt_text(plain_number::TEXT);
END;
$$ LANGUAGE plpgsql;

-- Function: Decrypt BIGINT
CREATE OR REPLACE FUNCTION app.decrypt_bigint(encrypted_data BYTEA)
RETURNS BIGINT AS $$
DECLARE
    decrypted_text TEXT;
BEGIN
    decrypted_text := app.decrypt_text(encrypted_data);
    IF decrypted_text IS NULL THEN
        RETURN NULL;
    END IF;
    RETURN decrypted_text::BIGINT;
EXCEPTION
    WHEN OTHERS THEN
        RETURN NULL;
END;
$$ LANGUAGE plpgsql;

DO $$
BEGIN
    RAISE NOTICE '✅ Created 4 encryption functions (encrypt/decrypt for text and bigint)';
END $$;

-- ============================================================================
-- STEP 5: MIGRATE EXISTING DATA TO ENCRYPTED COLUMNS
-- ============================================================================

\echo ''
\echo 'STEP 5: Migrating existing data to encrypted columns...'
\echo '   → Encrypting patient addresses...'

UPDATE app.patient
SET address_encrypted = app.encrypt_text(address)
WHERE address IS NOT NULL AND address_encrypted IS NULL;

\echo '   → Encrypting emergency contact names...'

UPDATE app.patient
SET emergency_contact_name_encrypted = app.encrypt_text(emergency_contact_name)
WHERE emergency_contact_name IS NOT NULL AND emergency_contact_name_encrypted IS NULL;

\echo '   → Encrypting emergency contact phones...'

UPDATE app.patient
SET emergency_contact_phone_encrypted = app.encrypt_bigint(emergency_phone)
WHERE emergency_phone IS NOT NULL AND emergency_contact_phone_encrypted IS NULL;

\echo '   → Encrypting doctor phone numbers...'

UPDATE app.doctor
SET phone_encrypted = app.encrypt_bigint(phone_num)
WHERE phone_num IS NOT NULL AND phone_encrypted IS NULL;

\echo '   → Encrypting prescription doctor notes...'

UPDATE app.prescription
SET doctor_note_encrypted = app.encrypt_text(doctor_note)
WHERE doctor_note IS NOT NULL AND doctor_note_encrypted IS NULL;

-- ============================================================================
-- STEP 6: CREATE SECURE VIEWS WITH AUTOMATIC DECRYPTION
-- ============================================================================

\echo ''
\echo 'STEP 6: Creating secure views with automatic decryption...'

-- Patient secure view
CREATE OR REPLACE VIEW app.v_patient_secure AS
SELECT 
    p.patient_id,
    u.username,
    u.first_name,
    u.last_name,
    u.email,
    p.phone_num,
    app.decrypt_text(p.address_encrypted) AS address_decrypted,
    app.decrypt_text(p.emergency_contact_name_encrypted) AS emergency_contact_decrypted,
    app.decrypt_bigint(p.emergency_contact_phone_encrypted) AS emergency_phone_decrypted,
    p.birth_date,
    p.gender,
    p.created_at
FROM app.patient p
JOIN app.user_account u ON p.user_id = u.user_id;

COMMENT ON VIEW app.v_patient_secure IS 'Patient data with decrypted sensitive fields (use for authorized access only)';

-- Doctor secure view
CREATE OR REPLACE VIEW app.v_doctor_secure AS
SELECT 
    d.doctor_id,
    u.username,
    u.first_name,
    u.last_name,
    u.email,
    app.decrypt_bigint(d.phone_encrypted) AS phone_decrypted,
    d.license_num,
    d.license_exp,
    d.specialisation,
    d.qualification,
    d.created_at
FROM app.doctor d
JOIN app.user_account u ON d.user_id = u.user_id;

COMMENT ON VIEW app.v_doctor_secure IS 'Doctor data with decrypted phone numbers (use for authorized access only)';

-- Prescription secure view
CREATE OR REPLACE VIEW app.v_prescription_secure AS
SELECT 
    pr.prescription_id,
    pr.patient_id,
    pr.doctor_id,
    app.decrypt_text(pr.doctor_note_encrypted) AS doctor_note_decrypted,
    pr.status,
    pr.created_date
FROM app.prescription pr;

COMMENT ON VIEW app.v_prescription_secure IS 'Prescription data with decrypted doctor notes (use for authorized access only)';

DO $$
BEGIN
    RAISE NOTICE '✅ Created 3 secure views (v_patient_secure, v_doctor_secure, v_prescription_secure)';
END $$;

-- ============================================================================
-- STEP 7: CREATE ENCRYPTION STATUS VIEW
-- ============================================================================

\echo ''
\echo 'STEP 7: Creating audit views for encrypted data access...'

CREATE OR REPLACE VIEW app.v_encryption_status AS
SELECT 
    'Patient Addresses' AS data_type,
    COUNT(*) AS total_records,
    COUNT(address_encrypted) AS encrypted_records,
    ROUND(COUNT(address_encrypted) * 100.0 / NULLIF(COUNT(*), 0), 2) AS encryption_percentage
FROM app.patient
UNION ALL
SELECT 
    'Emergency Contacts',
    COUNT(*),
    COUNT(emergency_contact_name_encrypted),
    ROUND(COUNT(emergency_contact_name_encrypted) * 100.0 / NULLIF(COUNT(*), 0), 2)
FROM app.patient
UNION ALL
SELECT 
    'Doctor Phones',
    COUNT(*),
    COUNT(phone_encrypted),
    ROUND(COUNT(phone_encrypted) * 100.0 / NULLIF(COUNT(*), 0), 2)
FROM app.doctor
UNION ALL
SELECT 
    'Prescription Notes',
    COUNT(*),
    COUNT(doctor_note_encrypted),
    ROUND(COUNT(doctor_note_encrypted) * 100.0 / NULLIF(COUNT(*), 0), 2)
FROM app.prescription;

COMMENT ON VIEW app.v_encryption_status IS 'Shows encryption coverage across sensitive tables';

DO $$
BEGIN
    RAISE NOTICE '✅ Created encryption status view';
END $$;

COMMIT;

-- ============================================================================
-- SUMMARY
-- ============================================================================

\echo ''
\echo '========================================'
\echo '📊 ENCRYPTION SETUP SUMMARY'
\echo '========================================'

SELECT * FROM app.v_encryption_status;

\echo ''
\echo '✅ Encryption setup completed successfully!'
\echo ''
\echo '📌 What was created:'
\echo '   • pgcrypto extension (AES-256 encryption)'
\echo '   • 3 encrypted BYTEA columns in patient table'
\echo '   • 1 encrypted BYTEA column in doctor table'
\echo '   • 1 encrypted BYTEA column in prescription table'
\echo '   • 1 encryption key management table'
\echo '   • 4 encryption/decryption functions'
\echo '   • 3 secure views with auto-decryption'
\echo '   • 1 encryption status audit view'
\echo ''
\echo '⚠️  SECURITY WARNINGS:'
\echo '   • Demo encryption key used - replace with AWS KMS/Azure Key Vault in production'
\echo '   • Restrict access to v_*_secure views to authorized users only'
\echo '   • Enable SSL/TLS for database connections to encrypt data in transit'
\echo '   • Regularly rotate encryption keys (update encryption_keys table)'
\echo ''
\echo '📖 Usage Examples:'
\echo '   -- View decrypted patient data (authorized users only)'
\echo '   SELECT * FROM app.v_patient_secure WHERE patient_id = 1;'
\echo ''
\echo '   -- Insert new patient with encrypted data'
\echo '   INSERT INTO app.patient (user_id, address_encrypted, ...)'
\echo '   VALUES (123, app.encrypt_text(''123 Main St''), ...);'
\echo ''
\echo '   -- Check encryption coverage'
\echo '   SELECT * FROM app.v_encryption_status;'
\echo ''
\echo '========================================'