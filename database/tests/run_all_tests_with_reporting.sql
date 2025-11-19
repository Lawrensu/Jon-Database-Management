-- Master Test Runner with Result Collection
-- Runs all tests and collects results before failing

-- Create a temporary table to store test results
CREATE TEMP TABLE test_results (
    test_suite VARCHAR,
    test_name VARCHAR,
    status VARCHAR,
    message VARCHAR,
    ran_at TIMESTAMP DEFAULT NOW()
);

-- Create a temporary table to track failures
CREATE TEMP TABLE test_failures (
    failure_id SERIAL PRIMARY KEY,
    test_suite VARCHAR,
    test_name VARCHAR,
    error_message VARCHAR
);

\set ON_ERROR_STOP off

-- ============================================================================
-- RUN SCHEMA TESTS
-- ============================================================================
DO $$ BEGIN
    RAISE NOTICE '========================================';
    RAISE NOTICE 'RUNNING: Schema Tests';
    RAISE NOTICE '========================================';
    
    BEGIN
        -- Check for the existence of the 'app' schema
        IF NOT EXISTS (SELECT 1 FROM information_schema.schemata WHERE schema_name = 'app') THEN
            INSERT INTO test_failures (test_suite, test_name, error_message) 
            VALUES ('schema_tests', 'app_schema_exists', 'Schema "app" does not exist.');
            RAISE NOTICE 'FAILED: app_schema_exists - Schema "app" does not exist.';
        ELSE
            INSERT INTO test_results (test_suite, test_name, status, message)
            VALUES ('schema_tests', 'app_schema_exists', 'PASSED', 'Schema "app" exists.');
            RAISE NOTICE 'PASSED: app_schema_exists';
        END IF;

        -- Check for the existence of patient table
        IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'app' AND table_name = 'patient') THEN
            INSERT INTO test_failures (test_suite, test_name, error_message)
            VALUES ('schema_tests', 'patient_table_exists', 'Table "app.patient" does not exist.');
            RAISE NOTICE 'FAILED: patient_table_exists - Table "app.patient" does not exist.';
        ELSE
            INSERT INTO test_results (test_suite, test_name, status, message)
            VALUES ('schema_tests', 'patient_table_exists', 'PASSED', 'Table "app.patient" exists.');
            RAISE NOTICE 'PASSED: patient_table_exists';
        END IF;

        -- Check for the existence of doctor table
        IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'app' AND table_name = 'doctor') THEN
            INSERT INTO test_failures (test_suite, test_name, error_message)
            VALUES ('schema_tests', 'doctor_table_exists', 'Table "app.doctor" does not exist.');
            RAISE NOTICE 'FAILED: doctor_table_exists - Table "app.doctor" does not exist.';
        ELSE
            INSERT INTO test_results (test_suite, test_name, status, message)
            VALUES ('schema_tests', 'doctor_table_exists', 'PASSED', 'Table "app.doctor" exists.');
            RAISE NOTICE 'PASSED: doctor_table_exists';
        END IF;

    EXCEPTION WHEN OTHERS THEN
        INSERT INTO test_failures (test_suite, test_name, error_message)
        VALUES ('schema_tests', 'schema_test_block', SQLERRM);
        RAISE NOTICE 'ERROR in schema_tests: %', SQLERRM;
    END;
END $$;

-- ============================================================================
-- RUN DATA INTEGRITY TESTS
-- ============================================================================
DO $$ DECLARE
    patient_count INTEGER;
    doctor_count INTEGER;
BEGIN
    RAISE NOTICE '========================================';
    RAISE NOTICE 'RUNNING: Data Integrity Tests';
    RAISE NOTICE '========================================';
    
    BEGIN
        -- Check patient seed data
        SELECT COUNT(*) INTO patient_count FROM app.patient;
        IF patient_count = 0 THEN
            INSERT INTO test_failures (test_suite, test_name, error_message)
            VALUES ('data_integrity_tests', 'patient_seed_data', 'No seed data found in "app.patient" table.');
            RAISE NOTICE 'FAILED: patient_seed_data - No seed data found.';
        ELSE
            INSERT INTO test_results (test_suite, test_name, status, message)
            VALUES ('data_integrity_tests', 'patient_seed_data', 'PASSED', 'Found ' || patient_count || ' patients.');
            RAISE NOTICE 'PASSED: patient_seed_data - Found % patients', patient_count;
        END IF;

        -- Check doctor seed data
        SELECT COUNT(*) INTO doctor_count FROM app.doctor;
        IF doctor_count = 0 THEN
            INSERT INTO test_failures (test_suite, test_name, error_message)
            VALUES ('data_integrity_tests', 'doctor_seed_data', 'No seed data found in "app.doctor" table.');
            RAISE NOTICE 'FAILED: doctor_seed_data - No seed data found.';
        ELSE
            INSERT INTO test_results (test_suite, test_name, status, message)
            VALUES ('data_integrity_tests', 'doctor_seed_data', 'PASSED', 'Found ' || doctor_count || ' doctors.');
            RAISE NOTICE 'PASSED: doctor_seed_data - Found % doctors', doctor_count;
        END IF;

    EXCEPTION WHEN OTHERS THEN
        INSERT INTO test_failures (test_suite, test_name, error_message)
        VALUES ('data_integrity_tests', 'data_integrity_test_block', SQLERRM);
        RAISE NOTICE 'ERROR in data_integrity_tests: %', SQLERRM;
    END;
END $$;

-- ============================================================================
-- RUN MONITORING TESTS
-- ============================================================================
DO $$ BEGIN
    RAISE NOTICE '========================================';
    RAISE NOTICE 'RUNNING: Monitoring Tests';
    RAISE NOTICE '========================================';
    
    BEGIN
        -- Test 1: Security schema exists
        IF NOT EXISTS (SELECT 1 FROM information_schema.schemata WHERE schema_name = 'security') THEN
            INSERT INTO test_failures (test_suite, test_name, error_message)
            VALUES ('monitoring_tests', 'security_schema_exists', 'Security schema does not exist.');
            RAISE NOTICE 'FAILED: security_schema_exists - Security schema does not exist.';
        ELSE
            INSERT INTO test_results (test_suite, test_name, status, message)
            VALUES ('monitoring_tests', 'security_schema_exists', 'PASSED', 'Security schema exists.');
            RAISE NOTICE 'PASSED: security_schema_exists';
        END IF;

        -- Test 2: events_log table exists
        IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'security' AND table_name = 'events_log') THEN
            INSERT INTO test_failures (test_suite, test_name, error_message)
            VALUES ('monitoring_tests', 'events_log_table_exists', 'Security events_log table does not exist.');
            RAISE NOTICE 'FAILED: events_log_table_exists';
        ELSE
            INSERT INTO test_results (test_suite, test_name, status, message)
            VALUES ('monitoring_tests', 'events_log_table_exists', 'PASSED', 'events_log table exists.');
            RAISE NOTICE 'PASSED: events_log_table_exists';
        END IF;

    EXCEPTION WHEN OTHERS THEN
        INSERT INTO test_failures (test_suite, test_name, error_message)
        VALUES ('monitoring_tests', 'monitoring_test_block', SQLERRM);
        RAISE NOTICE 'ERROR in monitoring_tests: %', SQLERRM;
    END;
END $$;

-- ============================================================================
-- GENERATE TEST REPORT
-- ============================================================================
\set ON_ERROR_STOP on

DO $$ DECLARE
    total_tests INT;
    passed_tests INT;
    failed_tests INT;
BEGIN
    RAISE NOTICE '========================================';
    RAISE NOTICE 'TEST REPORT SUMMARY';
    RAISE NOTICE '========================================';
    
    SELECT COUNT(*) INTO total_tests FROM test_results;
    SELECT COUNT(*) INTO passed_tests FROM test_results WHERE status = 'PASSED';
    SELECT COUNT(*) INTO failed_tests FROM (SELECT * FROM test_failures) AS f;
    
    RAISE NOTICE 'Total Tests: %', (total_tests + failed_tests);
    RAISE NOTICE 'Passed: %', passed_tests;
    RAISE NOTICE 'Failed: %', failed_tests;
    
    IF failed_tests > 0 THEN
        RAISE NOTICE '';
        RAISE NOTICE '========================================';
        RAISE NOTICE 'FAILURES:';
        RAISE NOTICE '========================================';
        
        RETURN QUERY EXECUTE 'SELECT test_suite || '': '' || test_name || '' - '' || error_message FROM test_failures ORDER BY failure_id';
    END IF;
    
    IF failed_tests > 0 THEN
        RAISE EXCEPTION 'Test suite failed with % test(s) failing', failed_tests;
    ELSE
        RAISE NOTICE '========================================';
        RAISE NOTICE 'All tests passed!';
        RAISE NOTICE '========================================';
    END IF;
END $$;
