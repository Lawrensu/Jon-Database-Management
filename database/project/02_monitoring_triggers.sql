-- ============================================================================
-- PAKAR Tech Healthcare Database - Monitoring Triggers
-- COS 20031 Database Design Project
-- Purpose: Attach audit triggers to core tables
-- Note: This runs AFTER 01_core_schema.sql is created
-- ============================================================================

BEGIN;

SET search_path TO app, public;

-- ============================================================================
-- SECTION 1: ATTACH AUDIT TRIGGERS TO CORE TABLES
-- ============================================================================

-- Drop existing triggers if they exist (for idempotency)
DROP TRIGGER IF EXISTS user_account_audit_trigger ON app.user_account;
DROP TRIGGER IF EXISTS patient_audit_trigger ON app.patient;
DROP TRIGGER IF EXISTS doctor_audit_trigger ON app.doctor;
DROP TRIGGER IF EXISTS prescription_audit_trigger ON app.prescription;
DROP TRIGGER IF EXISTS medication_log_audit_trigger ON app.medication_log;

-- Trigger for user_account table
CREATE TRIGGER user_account_audit_trigger
    AFTER INSERT OR UPDATE OR DELETE ON app.user_account
    FOR EACH ROW EXECUTE FUNCTION security.log_table_changes();

-- Trigger for patient table
CREATE TRIGGER patient_audit_trigger
    AFTER INSERT OR UPDATE OR DELETE ON app.patient
    FOR EACH ROW EXECUTE FUNCTION security.log_table_changes();

-- Trigger for doctor table
CREATE TRIGGER doctor_audit_trigger
    AFTER INSERT OR UPDATE OR DELETE ON app.doctor
    FOR EACH ROW EXECUTE FUNCTION security.log_table_changes();

-- Trigger for prescription table
CREATE TRIGGER prescription_audit_trigger
    AFTER INSERT OR UPDATE OR DELETE ON app.prescription
    FOR EACH ROW EXECUTE FUNCTION security.log_table_changes();

-- Trigger for medication_log table
CREATE TRIGGER medication_log_audit_trigger
    AFTER INSERT OR UPDATE OR DELETE ON app.medication_log
    FOR EACH ROW EXECUTE FUNCTION security.log_table_changes();

-- ============================================================================
-- SECTION 2: ATTACH ANOMALY DETECTION TRIGGER
-- ============================================================================

-- Drop existing anomaly detection trigger
DROP TRIGGER IF EXISTS patient_data_change_monitor ON app.patient;

-- Apply the anomaly detection trigger to patient table
CREATE TRIGGER patient_data_change_monitor
    AFTER UPDATE ON app.patient
    FOR EACH STATEMENT EXECUTE FUNCTION security.detect_rapid_data_changes();

-- ============================================================================
-- VERIFICATION
-- ============================================================================

DO $$ 
DECLARE
    trigger_count INT;
    audit_trigger_count INT;
    monitor_trigger_count INT;
BEGIN
    -- Count all monitoring triggers in app schema (CORRECTED LOGIC)
    SELECT COUNT(*) INTO trigger_count
    FROM pg_trigger t
    JOIN pg_class c ON t.tgrelid = c.oid
    JOIN pg_namespace n ON c.relnamespace = n.oid
    WHERE n.nspname = 'app'
    AND (t.tgname LIKE '%audit%' OR t.tgname LIKE '%monitor%')
    AND NOT t.tgisinternal;  -- Exclude internal triggers
    
    -- Count audit triggers specifically
    SELECT COUNT(*) INTO audit_trigger_count
    FROM pg_trigger t
    JOIN pg_class c ON t.tgrelid = c.oid
    JOIN pg_namespace n ON c.relnamespace = n.oid
    WHERE n.nspname = 'app'
    AND t.tgname LIKE '%audit%'
    AND NOT t.tgisinternal;
    
    -- Count monitoring triggers
    SELECT COUNT(*) INTO monitor_trigger_count
    FROM pg_trigger t
    JOIN pg_class c ON t.tgrelid = c.oid
    JOIN pg_namespace n ON c.relnamespace = n.oid
    WHERE n.nspname = 'app'
    AND t.tgname LIKE '%monitor%'
    AND NOT t.tgisinternal;
    
    RAISE NOTICE '=========================================';
    RAISE NOTICE 'Monitoring Triggers ENABLED';
    RAISE NOTICE '=========================================';
    RAISE NOTICE 'Total active triggers: %', trigger_count;
    RAISE NOTICE '  - Audit triggers: %', audit_trigger_count;
    RAISE NOTICE '  - Monitor triggers: %', monitor_trigger_count;
    RAISE NOTICE '';
    RAISE NOTICE 'Logging to: security.events_log';
    RAISE NOTICE 'Anomaly detection: ACTIVE';
    
    IF audit_trigger_count = 5 AND monitor_trigger_count = 1 THEN
        RAISE NOTICE 'All expected triggers are active';
    ELSE
        RAISE WARNING 'Unexpected trigger count!';
        RAISE WARNING 'Expected: 5 audit + 1 monitor = 6 total';
        RAISE WARNING 'Found: % audit + % monitor = % total', 
            audit_trigger_count, monitor_trigger_count, trigger_count;
    END IF;
    
    RAISE NOTICE '=========================================';
END $$;

COMMIT;