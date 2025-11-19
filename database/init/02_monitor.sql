-- ============================================================================
-- PAKAR Tech Healthcare Database - Monitoring System
-- Final Corrected Version
-- ============================================================================

-- Create a dedicated schema for security objects if it doesn't exist
CREATE SCHEMA IF NOT EXISTS security;

-- Drop the old table if it exists to ensure a clean slate with the correct types
DROP TABLE IF EXISTS security.events_log CASCADE;

-- Create the main table to store all security events
CREATE TABLE security.events_log (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    event_time TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    user_name TEXT NOT NULL,
    session_id TEXT,
    action TEXT NOT NULL, -- e.g., 'SELECT', 'INSERT', 'UPDATE', 'DELETE', 'ALERT'
    table_name TEXT NOT NULL,
    record_id INTEGER, -- INTEGER to match the new schema's SERIAL keys
    old_values JSONB,
    new_values JSONB,
    details TEXT -- For free-form notes or alert messages
);

-- Create indexes for faster lookups
CREATE INDEX IF NOT EXISTS idx_events_log_user_time ON security.events_log(user_name, event_time);
CREATE INDEX IF NOT EXISTS idx_events_log_table_action ON security.events_log(table_name, action);

COMMENT ON TABLE security.events_log IS 'Central log for tracking database access and modifications.';

-- Create a generic trigger function to log data changes (DYNAMIC PK VERSION)
CREATE OR REPLACE FUNCTION security.log_table_changes()
RETURNS TRIGGER AS $$ DECLARE
    pk_column_name TEXT;
    pk_value INTEGER;
BEGIN
    -- Dynamically find the name of the primary key column for the current table
    SELECT column_name INTO pk_column_name
    FROM information_schema.table_constraints tc
    JOIN information_schema.key_column_usage kcu
      ON tc.constraint_name = kcu.constraint_name
      AND tc.table_schema = kcu.table_schema
    WHERE tc.constraint_type = 'PRIMARY KEY'
      AND tc.table_name = TG_TABLE_NAME
      AND tc.table_schema = TG_TABLE_SCHEMA;

    -- Use dynamic SQL to get the primary key value from the NEW or OLD record
    IF TG_OP = 'DELETE' THEN
        EXECUTE format('SELECT ($1).%I', pk_column_name) INTO pk_value USING OLD;
        INSERT INTO security.events_log (user_name, action, table_name, record_id, old_values)
        VALUES (current_user, TG_OP, TG_TABLE_NAME, pk_value, to_jsonb(OLD));
        RETURN OLD;
    ELSIF TG_OP = 'UPDATE' THEN
        EXECUTE format('SELECT ($1).%I', pk_column_name) INTO pk_value USING NEW;
        INSERT INTO security.events_log (user_name, action, table_name, record_id, old_values, new_values)
        VALUES (current_user, TG_OP, TG_TABLE_NAME, pk_value, to_jsonb(OLD), to_jsonb(NEW));
        RETURN NEW;
    ELSIF TG_OP = 'INSERT' THEN
        EXECUTE format('SELECT ($1).%I', pk_column_name) INTO pk_value USING NEW;
        INSERT INTO security.events_log (user_name, action, table_name, record_id, new_values)
        VALUES (current_user, TG_OP, TG_TABLE_NAME, pk_value, to_jsonb(NEW));
        RETURN NEW;
    END IF;

    RETURN NULL;
END;
 $$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create the anomaly detection function for rapid data changes
CREATE OR REPLACE FUNCTION security.detect_rapid_data_changes()
RETURNS TRIGGER AS $$ DECLARE
    recent_update_count INTEGER;
    update_threshold INTEGER := 5; -- Alert if > 5 updates in 1 minute
    time_window INTERVAL := INTERVAL '1 minute';
BEGIN
    -- Count how many patient records this user has UPDATED in the last minute
    SELECT COUNT(*)
    INTO recent_update_count
    FROM security.events_log
    WHERE user_name = current_user
      AND table_name = 'patient'
      AND action = 'UPDATE'
      AND event_time > NOW() - time_window;

    -- If the count exceeds our threshold, create an alert
    IF recent_update_count > update_threshold THEN
        INSERT INTO security.events_log (user_name, action, table_name, details)
        VALUES (
            current_user,
            'ALERT',
            'patient',
            format('Rapid data modification detected: %s patient records updated in %s.', recent_update_count, time_window)
        );
    END IF;

    RETURN NULL; -- AFTER STATEMENT triggers must return NULL
END;
 $$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================================
-- CREATE ALL TRIGGERS
-- ============================================================================

-- Apply the logging trigger to sensitive tables
DROP TRIGGER IF EXISTS user_account_audit_trigger ON app.user_account;
CREATE TRIGGER user_account_audit_trigger
    AFTER INSERT OR UPDATE OR DELETE ON app.user_account
    FOR EACH ROW EXECUTE FUNCTION security.log_table_changes();

DROP TRIGGER IF EXISTS patient_audit_trigger ON app.patient;
CREATE TRIGGER patient_audit_trigger
    AFTER INSERT OR UPDATE OR DELETE ON app.patient
    FOR EACH ROW EXECUTE FUNCTION security.log_table_changes();

DROP TRIGGER IF EXISTS prescription_audit_trigger ON app.prescription;
CREATE TRIGGER prescription_audit_trigger
    AFTER INSERT OR UPDATE OR DELETE ON app.prescription
    FOR EACH ROW EXECUTE FUNCTION security.log_table_changes();

DROP TRIGGER IF EXISTS medication_log_audit_trigger ON app.medication_log;
CREATE TRIGGER medication_log_audit_trigger
    AFTER INSERT OR UPDATE OR DELETE ON app.medication_log
    FOR EACH ROW EXECUTE FUNCTION security.log_table_changes();

-- Apply the anomaly detection trigger
DROP TRIGGER IF EXISTS patient_data_change_monitor ON app.patient;
CREATE TRIGGER patient_data_change_monitor
    AFTER UPDATE ON app.patient
    FOR EACH STATEMENT
    EXECUTE FUNCTION security.detect_rapid_data_changes();

-- ============================================================================
-- COMPLETION MESSAGE
-- ============================================================================
DO $$ BEGIN
    RAISE NOTICE '=========================================';
    RAISE NOTICE 'Database Monitoring System Activated (FINAL)';
    RAISE NOTICE '=========================================';
    RAISE NOTICE 'Security events are now being logged to: security.events_log';
    RAISE NOTICE 'Anomaly detection for rapid data changes is enabled.';
    RAISE NOTICE '=========================================';
END $$;