-- ============================================================================
-- PAKAR Tech Healthcare Database - Validation Queries
-- COS 20031 Database Design Project
-- Purpose: Verify database structure and data integrity
-- ============================================================================

SET search_path TO app, public;

-- ============================================================================
-- SECTION 1: SCHEMA VALIDATION
-- ============================================================================

DO $$
DECLARE
    table_count INT;
    enum_count INT;
    index_count INT;
    trigger_count INT;
BEGIN
    -- Count tables in app schema
    SELECT COUNT(*) INTO table_count
    FROM information_schema.tables
    WHERE table_schema = 'app';
    
    -- Count custom ENUM types
    SELECT COUNT(*) INTO enum_count
    FROM pg_type t
    JOIN pg_namespace n ON t.typnamespace = n.oid
    WHERE n.nspname = 'app' AND t.typtype = 'e';
    
    -- Count indexes
    SELECT COUNT(*) INTO index_count
    FROM pg_indexes
    WHERE schemaname = 'app';
    
    -- Count triggers
    SELECT COUNT(*) INTO trigger_count
    FROM pg_trigger t
    JOIN pg_class c ON t.tgrelid = c.oid
    JOIN pg_namespace n ON c.relnamespace = n.oid
    WHERE n.nspname = 'app'
    AND NOT t.tgisinternal;  -- Exclude internal triggers
    
    RAISE NOTICE '========================================';
    RAISE NOTICE 'Schema Validation';
    RAISE NOTICE '========================================';
    RAISE NOTICE 'Tables in app schema: % (expected: 16)', table_count;
    RAISE NOTICE 'Custom ENUM types: % (expected: 8)', enum_count;
    RAISE NOTICE 'Indexes created: % (expected: 30+)', index_count;
    RAISE NOTICE 'Triggers active: % (expected: 9+)', trigger_count;
    RAISE NOTICE '';
END $$;

-- ============================================================================
-- SECTION 2: DATA VALIDATION
-- ============================================================================

WITH validation AS (
    SELECT 
        'Conditions' AS table_name,
        (SELECT COUNT(*) FROM app.condition) AS actual_count,
        27 AS expected_count
    UNION ALL
    SELECT 
        'Symptoms',
        (SELECT COUNT(*) FROM app.symptom),
        10
    UNION ALL
    SELECT 
        'Side Effects',
        (SELECT COUNT(*) FROM app.side_effect),
        11
    UNION ALL
    SELECT 
        'Medications',
        (SELECT COUNT(*) FROM app.medication),
        15
    UNION ALL
    SELECT 
        'Med-SideEffect Links',
        (SELECT COUNT(*) FROM app.medication_side_effect),
        6
    UNION ALL
    SELECT 
        'Patients',
        (SELECT COUNT(*) FROM app.patient),
        200
    UNION ALL
    SELECT 
        'Doctors',
        (SELECT COUNT(*) FROM app.doctor),
        20
    UNION ALL
    SELECT 
        'Admins',
        (SELECT COUNT(*) FROM app.admin),
        3
    UNION ALL
    SELECT 
        'Super Admins',
        (SELECT COUNT(*) FROM app.super_admin),
        2
    UNION ALL
    SELECT 
        'User Accounts (Total)',
        (SELECT COUNT(*) FROM app.user_account),
        225  -- 200 patients + 20 doctors + 3 admins + 2 super admins
    UNION ALL
    SELECT 
        'User Accounts (Patient)',
        (SELECT COUNT(*) FROM app.user_account WHERE user_type = 'Patient'),
        200
    UNION ALL
    SELECT 
        'User Accounts (Doctor)',
        (SELECT COUNT(*) FROM app.user_account WHERE user_type = 'Doctor'),
        20
    UNION ALL
    SELECT 
        'User Accounts (Admin)',
        (SELECT COUNT(*) FROM app.user_account WHERE user_type = 'Admin'),
        3
    UNION ALL
    SELECT 
        'User Accounts (SuperAdmin)',
        (SELECT COUNT(*) FROM app.user_account WHERE user_type = 'SuperAdmin'),
        2
)
SELECT 
    table_name AS "Table/Data",
    expected_count AS "Expected",
    actual_count AS "Actual",
    CASE 
        WHEN actual_count = expected_count THEN '✅ PASS'
        WHEN actual_count > expected_count THEN '⚠️  MORE'
        ELSE '❌ FAIL'
    END AS "Status"
FROM validation
ORDER BY 
    CASE 
        WHEN table_name LIKE 'User Accounts%' THEN 3
        WHEN table_name IN ('Patients', 'Doctors', 'Admins', 'Super Admins') THEN 2
        ELSE 1
    END,
    table_name;

-- ============================================================================
-- SECTION 3: FOREIGN KEY VALIDATION
-- ============================================================================

DO $$
DECLARE
    orphaned_patients INT;
    orphaned_doctors INT;
    orphaned_admins INT;
    orphaned_super_admins INT;
    invalid_patient_doctors INT;
BEGIN
    -- Check for orphaned patients (patient without user_account)
    SELECT COUNT(*) INTO orphaned_patients
    FROM app.patient p
    LEFT JOIN app.user_account u ON p.user_id = u.user_id
    WHERE u.user_id IS NULL;
    
    -- Check for orphaned doctors
    SELECT COUNT(*) INTO orphaned_doctors
    FROM app.doctor d
    LEFT JOIN app.user_account u ON d.user_id = u.user_id
    WHERE u.user_id IS NULL;
    
    -- Check for orphaned admins
    SELECT COUNT(*) INTO orphaned_admins
    FROM app.admin a
    LEFT JOIN app.user_account u ON a.user_id = u.user_id
    WHERE u.user_id IS NULL;
    
    -- Check for orphaned super_admins
    SELECT COUNT(*) INTO orphaned_super_admins
    FROM app.super_admin sa
    LEFT JOIN app.user_account u ON sa.user_id = u.user_id
    WHERE u.user_id IS NULL;
    
    -- Check for patients with invalid doctor references
    SELECT COUNT(*) INTO invalid_patient_doctors
    FROM app.patient p
    WHERE p.doctor_id IS NOT NULL
    AND NOT EXISTS (
        SELECT 1 FROM app.doctor d WHERE d.doctor_id = p.doctor_id
    );
    
    RAISE NOTICE '========================================';
    RAISE NOTICE 'Foreign Key Validation';
    RAISE NOTICE '========================================';
    RAISE NOTICE 'Orphaned patients: % (expected: 0)', orphaned_patients;
    RAISE NOTICE 'Orphaned doctors: % (expected: 0)', orphaned_doctors;
    RAISE NOTICE 'Orphaned admins: % (expected: 0)', orphaned_admins;
    RAISE NOTICE 'Orphaned super_admins: % (expected: 0)', orphaned_super_admins;
    RAISE NOTICE 'Invalid patient→doctor refs: % (expected: 0)', invalid_patient_doctors;
    
    IF orphaned_patients = 0 AND orphaned_doctors = 0 AND 
       orphaned_admins = 0 AND orphaned_super_admins = 0 AND
       invalid_patient_doctors = 0 THEN
        RAISE NOTICE '✅ All foreign keys are valid';
    ELSE
        RAISE WARNING '❌ Foreign key violations found!';
    END IF;
    RAISE NOTICE '';
END $$;

-- ============================================================================
-- SECTION 4: MONITORING SYSTEM VALIDATION
-- ============================================================================

DO $$
DECLARE
    audit_log_count INT;
    security_schema_exists BOOLEAN;
    events_log_exists BOOLEAN;
    audit_triggers_count INT;
    monitor_triggers_count INT;
BEGIN
    -- Check if security schema exists
    SELECT EXISTS (
        SELECT 1 FROM information_schema.schemata WHERE schema_name = 'security'
    ) INTO security_schema_exists;
    
    IF security_schema_exists THEN
        -- Check if events_log table exists
        SELECT EXISTS (
            SELECT 1 FROM information_schema.tables 
            WHERE table_schema = 'security' AND table_name = 'events_log'
        ) INTO events_log_exists;
        
        IF events_log_exists THEN
            -- Count audit log entries
            SELECT COUNT(*) INTO audit_log_count FROM security.events_log;
            
            -- Count audit triggers
            SELECT COUNT(*) INTO audit_triggers_count
            FROM pg_trigger t
            JOIN pg_class c ON t.tgrelid = c.oid
            JOIN pg_namespace n ON c.relnamespace = n.oid
            WHERE n.nspname = 'app'
            AND t.tgname LIKE '%audit%'
            AND NOT t.tgisinternal;
            
            -- Count monitoring triggers
            SELECT COUNT(*) INTO monitor_triggers_count
            FROM pg_trigger t
            JOIN pg_class c ON t.tgrelid = c.oid
            JOIN pg_namespace n ON c.relnamespace = n.oid
            WHERE n.nspname = 'app'
            AND t.tgname LIKE '%monitor%'
            AND NOT t.tgisinternal;
            
            RAISE NOTICE '========================================';
            RAISE NOTICE 'Monitoring System Validation';
            RAISE NOTICE '========================================';
            RAISE NOTICE 'Security schema: ✅ EXISTS';
            RAISE NOTICE 'Events log table: ✅ EXISTS';
            RAISE NOTICE 'Audit log entries: % (expected: 225+)', audit_log_count;
            RAISE NOTICE 'Audit triggers: % (expected: 5)', audit_triggers_count;
            RAISE NOTICE 'Monitor triggers: % (expected: 1)', monitor_triggers_count;
            
            IF audit_log_count >= 225 THEN
                RAISE NOTICE '✅ Audit logging is working';
            ELSE
                RAISE WARNING '⚠️  Expected at least 225 audit entries (from seeds)';
            END IF;
            
            IF audit_triggers_count >= 5 AND monitor_triggers_count >= 1 THEN
                RAISE NOTICE '✅ All monitoring triggers active';
            ELSE
                RAISE WARNING '⚠️  Some triggers may be missing';
                RAISE WARNING '    Run: npm run monitoring:enable';
            END IF;
        ELSE
            RAISE WARNING '========================================';
            RAISE WARNING 'Monitoring System Validation';
            RAISE WARNING '========================================';
            RAISE WARNING '❌ Events log table does NOT exist';
            RAISE WARNING 'Database initialization may have failed';
            RAISE WARNING 'Run: npm run db:reset && npm run db:start';
        END IF;
    ELSE
        RAISE WARNING '========================================';
        RAISE WARNING 'Monitoring System Validation';
        RAISE WARNING '========================================';
        RAISE WARNING '❌ Security schema does NOT exist';
        RAISE WARNING 'Database initialization may have failed';
        RAISE WARNING 'Run: npm run db:reset && npm run db:start';
    END IF;
    RAISE NOTICE '';
END $$;

-- ============================================================================
-- SECTION 5: DATA INTEGRITY CHECKS
-- ============================================================================

DO $$
DECLARE
    duplicate_usernames INT;
    duplicate_emails INT;
    duplicate_license_nums INT;
    expired_licenses INT;
    invalid_birth_dates INT;
    future_created_dates INT;
BEGIN
    -- Check for duplicate usernames
    SELECT COUNT(*) INTO duplicate_usernames
    FROM (
        SELECT username, COUNT(*) 
        FROM app.user_account 
        GROUP BY username 
        HAVING COUNT(*) > 1
    ) duplicates;
    
    -- Check for duplicate emails
    SELECT COUNT(*) INTO duplicate_emails
    FROM (
        SELECT email, COUNT(*) 
        FROM app.user_account 
        GROUP BY email 
        HAVING COUNT(*) > 1
    ) duplicates;
    
    -- Check for duplicate license numbers
    SELECT COUNT(*) INTO duplicate_license_nums
    FROM (
        SELECT license_num, COUNT(*) 
        FROM app.doctor 
        GROUP BY license_num 
        HAVING COUNT(*) > 1
    ) duplicates;
    
    -- Check for expired doctor licenses
    SELECT COUNT(*) INTO expired_licenses
    FROM app.doctor
    WHERE license_exp <= CURRENT_TIMESTAMP;
    
    -- Check for invalid birth dates (future dates)
    SELECT COUNT(*) INTO invalid_birth_dates
    FROM app.patient
    WHERE birth_date > CURRENT_TIMESTAMP;
    
    -- Check for future created_at dates
    SELECT COUNT(*) INTO future_created_dates
    FROM app.user_account
    WHERE created_at > CURRENT_TIMESTAMP;
    
    RAISE NOTICE '========================================';
    RAISE NOTICE 'Data Integrity Checks';
    RAISE NOTICE '========================================';
    RAISE NOTICE 'Duplicate usernames: % (expected: 0)', duplicate_usernames;
    RAISE NOTICE 'Duplicate emails: % (expected: 0)', duplicate_emails;
    RAISE NOTICE 'Duplicate license numbers: % (expected: 0)', duplicate_license_nums;
    RAISE NOTICE 'Expired doctor licenses: % (expected: 0)', expired_licenses;
    RAISE NOTICE 'Future birth dates: % (expected: 0)', invalid_birth_dates;
    RAISE NOTICE 'Future created_at dates: % (expected: 0)', future_created_dates;
    
    IF duplicate_usernames = 0 AND duplicate_emails = 0 AND 
       duplicate_license_nums = 0 AND expired_licenses = 0 AND 
       invalid_birth_dates = 0 AND future_created_dates = 0 THEN
        RAISE NOTICE '✅ All data integrity checks passed';
    ELSE
        RAISE WARNING '❌ Data integrity violations found!';
    END IF;
    RAISE NOTICE '';
END $$;

-- ============================================================================
-- SECTION 6: PASSWORD CONSISTENCY CHECK
-- ============================================================================

DO $$
DECLARE
    password_lengths TEXT;
    inconsistent_passwords BOOLEAN := FALSE;
BEGIN
    -- Check if all passwords have the same length
    SELECT STRING_AGG(DISTINCT LENGTH(password)::TEXT, ', ')
    INTO password_lengths
    FROM app.user_account;
    
    -- Check if there's more than one distinct password length
    IF POSITION(',' IN password_lengths) > 0 THEN
        inconsistent_passwords := TRUE;
    END IF;
    
    RAISE NOTICE '========================================';
    RAISE NOTICE 'Password Consistency Check';
    RAISE NOTICE '========================================';
    RAISE NOTICE 'Password hash lengths found: %', password_lengths;
    
    IF inconsistent_passwords THEN
        RAISE WARNING '⚠️  Inconsistent password hashes detected';
        RAISE WARNING '    All seeds should use: decode(''73656564'', ''hex'')';
        RAISE WARNING '    This ensures password "seed" for all test accounts';
    ELSE
        RAISE NOTICE '✅ All passwords have consistent hash length';
    END IF;
    RAISE NOTICE '';
END $$;

-- ============================================================================
-- SECTION 7: TABLE RELATIONSHIP VERIFICATION
-- ============================================================================

DO $$
DECLARE
    prescription_count INT;
    prescription_version_count INT;
    medication_schedule_count INT;
    medication_log_count INT;
    patient_symptom_count INT;
BEGIN
    -- Count records in relationship tables
    SELECT COUNT(*) INTO prescription_count FROM app.prescription;
    SELECT COUNT(*) INTO prescription_version_count FROM app.prescription_version;
    SELECT COUNT(*) INTO medication_schedule_count FROM app.medication_schedule;
    SELECT COUNT(*) INTO medication_log_count FROM app.medication_log;
    SELECT COUNT(*) INTO patient_symptom_count FROM app.patient_symptom;
    
    RAISE NOTICE '========================================';
    RAISE NOTICE 'Table Relationship Verification';
    RAISE NOTICE '========================================';
    RAISE NOTICE 'Prescriptions: % records', prescription_count;
    RAISE NOTICE 'Prescription Versions: % records', prescription_version_count;
    RAISE NOTICE 'Medication Schedules: % records', medication_schedule_count;
    RAISE NOTICE 'Medication Logs: % records', medication_log_count;
    RAISE NOTICE 'Patient Symptoms: % records', patient_symptom_count;
    
    IF prescription_count = 0 THEN
        RAISE NOTICE '⚠️  No prescriptions loaded yet';
        RAISE NOTICE '    This is expected if prescription seeds not loaded';
    END IF;
    RAISE NOTICE '';
END $$;

-- ============================================================================
-- FINAL SUMMARY
-- ============================================================================

DO $$
DECLARE
    total_users INT;
    total_patients INT;
    total_doctors INT;
    total_admins INT;
    total_conditions INT;
    total_medications INT;
    audit_events INT;
BEGIN
    SELECT COUNT(*) INTO total_users FROM app.user_account;
    SELECT COUNT(*) INTO total_patients FROM app.patient;
    SELECT COUNT(*) INTO total_doctors FROM app.doctor;
    SELECT COUNT(*) INTO total_admins FROM app.admin;
    SELECT COUNT(*) INTO total_conditions FROM app.condition;
    SELECT COUNT(*) INTO total_medications FROM app.medication;
    
    -- Check audit events (if monitoring enabled)
    IF EXISTS (SELECT 1 FROM information_schema.schemata WHERE schema_name = 'security') THEN
        SELECT COUNT(*) INTO audit_events FROM security.events_log;
    ELSE
        audit_events := 0;
    END IF;
    
    RAISE NOTICE '========================================';
    RAISE NOTICE 'Database Validation Complete';
    RAISE NOTICE '========================================';
    RAISE NOTICE 'Database is ready for use';
    RAISE NOTICE '';
    RAISE NOTICE 'Quick Stats:';
    RAISE NOTICE '  - Total Users: % (200 patients + 20 doctors + 5 admins)', total_users;
    RAISE NOTICE '  - Patients: %', total_patients;
    RAISE NOTICE '  - Doctors: %', total_doctors;
    RAISE NOTICE '  - Admins: %', total_admins;
    RAISE NOTICE '  - Medical Conditions: %', total_conditions;
    RAISE NOTICE '  - Medications: %', total_medications;
    
    IF audit_events > 0 THEN
        RAISE NOTICE '  - Audit Events Logged: %', audit_events;
        RAISE NOTICE '  - Monitoring: ✅ ACTIVE';
    ELSE
        RAISE NOTICE '  - Monitoring: ⚠️  NOT ENABLED';
        RAISE NOTICE '    Run: npm run monitoring:enable';
    END IF;
    
    RAISE NOTICE '';
    RAISE NOTICE 'Next Steps:';
    RAISE NOTICE '  1. Test queries: npm run queries:test';
    RAISE NOTICE '  2. Access pgAdmin: http://localhost:8080';
    RAISE NOTICE '  3. Connect via psql: npm run db:connect';
    RAISE NOTICE '  4. View audit logs: SELECT * FROM security.events_log;';
    RAISE NOTICE '========================================';
END $$;