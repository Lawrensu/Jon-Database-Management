-- ============================================================================
-- PAKAR Tech Healthcare Database - Monitoring System
-- COS 20031 Database Design Project
-- Purpose: Security monitoring and audit logging
-- Note: Triggers are created AFTER core schema exists
-- ============================================================================

-- Create a dedicated schema for security objects
CREATE SCHEMA IF NOT EXISTS security;

-- Drop the old table if it exists to ensure a clean slate
DROP TABLE IF EXISTS security.events_log CASCADE;

-- ============================================================================
-- SECTION 1: AUDIT LOG TABLE
-- ============================================================================

CREATE TABLE security.events_log (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    event_time TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    user_name TEXT NOT NULL,
    session_id TEXT,
    action TEXT NOT NULL, -- 'INSERT', 'UPDATE', 'DELETE', 'ALERT'
    table_name TEXT NOT NULL,
    record_id INTEGER, -- INTEGER to match SERIAL primary keys
    old_values JSONB,
    new_values JSONB,
    details TEXT -- For free-form notes or alert messages
);

-- Create indexes for faster lookups
CREATE INDEX IF NOT EXISTS idx_events_log_user_time 
    ON security.events_log(user_name, event_time);
CREATE INDEX IF NOT EXISTS idx_events_log_table_action 
    ON security.events_log(table_name, action);
CREATE INDEX IF NOT EXISTS idx_events_log_record 
    ON security.events_log(table_name, record_id);

COMMENT ON TABLE security.events_log IS 'Central log for tracking database access and modifications.';

-- ============================================================================
-- SECTION 2: AUDIT LOGGING FUNCTION
-- ============================================================================

CREATE OR REPLACE FUNCTION security.log_table_changes()
RETURNS TRIGGER AS $$ 
DECLARE
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
      AND tc.table_schema = TG_TABLE_SCHEMA
    LIMIT 1;

    -- Handle different operations
    IF TG_OP = 'DELETE' THEN
        -- Extract primary key value from OLD record
        EXECUTE format('SELECT ($1).%I', pk_column_name) INTO pk_value USING OLD;
        
        INSERT INTO security.events_log (user_name, action, table_name, record_id, old_values)
        VALUES (current_user, TG_OP, TG_TABLE_NAME, pk_value, to_jsonb(OLD));
        
        RETURN OLD;
        
    ELSIF TG_OP = 'UPDATE' THEN
        -- Extract primary key value from NEW record
        EXECUTE format('SELECT ($1).%I', pk_column_name) INTO pk_value USING NEW;
        
        INSERT INTO security.events_log (user_name, action, table_name, record_id, old_values, new_values)
        VALUES (current_user, TG_OP, TG_TABLE_NAME, pk_value, to_jsonb(OLD), to_jsonb(NEW));
        
        RETURN NEW;
        
    ELSIF TG_OP = 'INSERT' THEN
        -- Extract primary key value from NEW record
        EXECUTE format('SELECT ($1).%I', pk_column_name) INTO pk_value USING NEW;
        
        INSERT INTO security.events_log (user_name, action, table_name, record_id, new_values)
        VALUES (current_user, TG_OP, TG_TABLE_NAME, pk_value, to_jsonb(NEW));
        
        RETURN NEW;
    END IF;

    RETURN NULL;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON FUNCTION security.log_table_changes() IS 'Generic trigger function to log INSERT/UPDATE/DELETE operations with dynamic primary key detection.';

-- ============================================================================
-- SECTION 3: ANOMALY DETECTION FUNCTION
-- ============================================================================

CREATE OR REPLACE FUNCTION security.detect_rapid_data_changes()
RETURNS TRIGGER AS $$ 
DECLARE
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

COMMENT ON FUNCTION security.detect_rapid_data_changes() IS 'Detects rapid bulk updates to patient records and logs alerts.';

-- ============================================================================
-- SECTION 4: NOTE ABOUT TRIGGERS
-- ============================================================================

-- IMPORTANT: Triggers are NOT created here!
-- They must be created AFTER the core schema exists.

-- ============================================================================
-- COMPLETION MESSAGE
-- ============================================================================

DO $$ 
BEGIN
    RAISE NOTICE '=========================================';
    RAISE NOTICE 'Database Monitoring System INITIALIZED';
    RAISE NOTICE '=========================================';
    RAISE NOTICE 'Security schema and functions created.';
    RAISE NOTICE '';
    RAISE NOTICE 'IMPORTANT: Triggers NOT created yet!';
    RAISE NOTICE '';
    RAISE NOTICE 'After running "npm run schema:create", execute:';
    RAISE NOTICE '  npm run monitoring:enable';
    RAISE NOTICE '';
    RAISE NOTICE 'This will attach triggers to core tables.';
    RAISE NOTICE '=========================================';
END $$;