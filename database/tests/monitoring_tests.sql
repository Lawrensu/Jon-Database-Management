DO $$ BEGIN
    RAISE NOTICE '========================================';
    RAISE NOTICE 'Starting Database Monitoring Tests...';
    RAISE NOTICE '========================================';
END $$;

-- Test 1: Check if the security schema exists
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.schemata WHERE schema_name = 'security') THEN
        RAISE EXCEPTION 'Test 1 FAILED: Security schema does not exist.';
    END IF;
    RAISE NOTICE 'Test 1 PASSED: Security schema exists.';
END $$;

-- Test 2: Check if the events_log table exists with the correct structure
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'security' AND table_name = 'events_log') THEN
        RAISE EXCEPTION 'Test 2 FAILED: Security events_log table does not exist.';
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'security' AND table_name = 'events_log' AND column_name = 'record_id' AND data_type = 'integer') THEN
        RAISE EXCEPTION 'Test 2 FAILED: events_log.record_id column is not of type integer.';
    END IF;
    
    RAISE NOTICE 'Test 2 PASSED: Security events_log table exists with correct structure.';
END $$;

-- Test 3: Check if the main logging trigger exists on the patient table
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'patient_audit_trigger') THEN
        RAISE EXCEPTION 'Test 3 FAILED: patient_audit_trigger does not exist.';
    END IF;
    RAISE NOTICE 'Test 3 PASSED: patient_audit_trigger exists.';
END $$;

-- Test 4: Check if the anomaly detection trigger exists on the patient table
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'patient_data_change_monitor') THEN
        RAISE EXCEPTION 'Test 4 FAILED: patient_data_change_monitor does not exist.';
    END IF;
    RAISE NOTICE 'Test 4 PASSED: patient_data_change_monitor exists.';
END $$;

-- Test 5: Test INSERT logging
DO $$ DECLARE
    new_user_id INT;
    log_count INT;
BEGIN
    -- Create a test user and patient
    INSERT INTO app.user_account (username, password, user_type, first_name, last_name, email)
    VALUES ('ci_test_user', 'hash', 'Patient', 'CI', 'Test', 'ci@example.com')
    RETURNING user_id INTO new_user_id;

    INSERT INTO app.patient (user_id, phone_num, birth_date, gender)
    VALUES (new_user_id, 1234567890, '1990-01-01', 'Other');

    -- Check that one INSERT was logged for the patient table
    SELECT COUNT(*) INTO log_count
    FROM security.events_log
    WHERE table_name = 'patient' AND action = 'INSERT';

    IF log_count <> 1 THEN
        RAISE EXCEPTION 'Test 5 FAILED: Expected 1 INSERT log for patient, but found %.', log_count;
    END IF;
    
    RAISE NOTICE 'Test 5 PASSED: Patient INSERT was logged correctly.';
END $$;

-- Test 6: Test UPDATE logging
DO $$ DECLARE
    log_count INT;
BEGIN
    -- Update the patient's phone number
    UPDATE app.patient SET phone_num = 9876543210 WHERE patient_id = 1;

    -- Check that one UPDATE was logged for the patient table
    SELECT COUNT(*) INTO log_count
    FROM security.events_log
    WHERE table_name = 'patient' AND action = 'UPDATE';

    IF log_count <> 1 THEN
        RAISE EXCEPTION 'Test 6 FAILED: Expected 1 UPDATE log for patient, but found %.', log_count;
    END IF;
    
    RAISE NOTICE 'Test 6 PASSED: Patient UPDATE was logged correctly.';
END $$;

-- Test 7: Test DELETE logging
DO $$ DECLARE
    log_count INT;
BEGIN
    -- Delete the test records
    DELETE FROM app.patient WHERE patient_id = 1;
    DELETE FROM app.user_account WHERE user_id = 1;

    -- Check that one DELETE was logged for the patient table
    SELECT COUNT(*) INTO log_count
    FROM security.events_log
    WHERE table_name = 'patient' AND action = 'DELETE';

    IF log_count <> 1 THEN
        RAISE EXCEPTION 'Test 7 FAILED: Expected 1 DELETE log for patient, but found %.', log_count;
    END IF;
    
    RAISE NOTICE 'Test 7 PASSED: Patient DELETE was logged correctly.';
END $$;

-- Test 8: Test Anomaly Detection
DO $$ DECLARE
    new_user_id INT;
    alert_count INT;
BEGIN
    -- Create a new record to update
    INSERT INTO app.user_account (username, password, user_type, first_name, last_name, email)
    VALUES ('ci_test_user2', 'hash', 'Patient', 'CI', 'Test2', 'ci2@example.com')
    RETURNING user_id INTO new_user_id;

    INSERT INTO app.patient (user_id, phone_num, birth_date, gender)
    VALUES (new_user_id, 1111111111, '1990-01-01', 'Other');

    -- Run 6 rapid UPDATEs to trigger the alert (threshold is 5)
    UPDATE app.patient SET phone_num = 1111111112 WHERE patient_id = 2;
    UPDATE app.patient SET phone_num = 1111111113 WHERE patient_id = 2;
    UPDATE app.patient SET phone_num = 1111111114 WHERE patient_id = 2;
    UPDATE app.patient SET phone_num = 1111111115 WHERE patient_id = 2;
    UPDATE app.patient SET phone_num = 1111111116 WHERE patient_id = 2;
    UPDATE app.patient SET phone_num = 1111111117 WHERE patient_id = 2;

    -- Check that one ALERT was generated
    SELECT COUNT(*) INTO alert_count
    FROM security.events_log
    WHERE action = 'ALERT' AND table_name = 'patient';

    IF alert_count <> 1 THEN
        RAISE EXCEPTION 'Test 8 FAILED: Expected 1 anomaly alert, but found %.', alert_count;
    END IF;
    
    RAISE NOTICE 'Test 8 PASSED: Anomaly detection generated an alert.';

    -- Clean up the test record
    DELETE FROM app.patient WHERE patient_id = 2;
    DELETE FROM app.user_account WHERE user_id = 2;
END $$;

DO $$ BEGIN
    RAISE NOTICE '========================================';
    RAISE NOTICE 'All monitoring tests passed successfully!';
    RAISE NOTICE '========================================';
END $$;