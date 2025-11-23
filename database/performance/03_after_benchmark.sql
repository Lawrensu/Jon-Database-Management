-- ============================================================================
-- PAKAR Tech Healthcare - Performance AFTER Optimization
-- COS 20031 Database Design Project
-- Purpose: Re-measure performance AFTER creating advanced indexes
-- Author: Lawrence Lian anak Matius Ding
-- ============================================================================

SET search_path TO app, public;

\timing on

-- ============================================================================
-- CLEANUP: Delete old AFTER data before running new benchmark
-- ============================================================================

DO $$
DECLARE
    deleted_count INT;
BEGIN
    DELETE FROM performance.benchmark_metrics
    WHERE optimization_stage = 'AFTER';
    
    GET DIAGNOSTICS deleted_count = ROW_COUNT;
    
    RAISE NOTICE '========================================';
    RAISE NOTICE 'AFTER-OPTIMIZATION BENCHMARK';
    RAISE NOTICE '========================================';
    RAISE NOTICE 'Deleted % old AFTER benchmarks', deleted_count;
    RAISE NOTICE 'Re-running same benchmarks...';
    RAISE NOTICE '';
END $$;

-- ============================================================================
-- VERIFY OPTIMIZATION INDEXES EXIST
-- ============================================================================

DO $$
DECLARE
    idx_count INT;
BEGIN
    SELECT COUNT(*) INTO idx_count
    FROM pg_indexes
    WHERE schemaname = 'app'
    AND indexname IN (
        'idx_patient_birth_gender_composite',
        'idx_prescription_active_only',
        'idx_medication_fulltext_search',
        'idx_patient_birth_covering'
    );
    
    IF idx_count < 4 THEN
        RAISE EXCEPTION 'Optimization indexes not found! Run 02_advanced_indexes.sql first';
    END IF;
    
    RAISE NOTICE '========================================';
    RAISE NOTICE 'AFTER-OPTIMIZATION BENCHMARK';
    RAISE NOTICE '========================================';
    RAISE NOTICE 'Advanced indexes detected: %', idx_count;
    RAISE NOTICE 'Re-running same benchmarks...';
    RAISE NOTICE '';
END $$;

-- ============================================================================
-- BENCHMARK TEST 1: Patient Search by Birth Date and Gender (COMPOSITE INDEX)
-- ============================================================================

DO $$
DECLARE
    start_time TIMESTAMP;
    end_time TIMESTAMP;
    duration_ms NUMERIC;
    row_count INT;
    test_query TEXT;
BEGIN
    RAISE NOTICE 'BENCHMARK 1: Patient Search (Birth Date + Gender)';
    RAISE NOTICE '========================================';
    
    test_query := 'SELECT * FROM app.patient
        WHERE birth_date BETWEEN ''1950-01-01'' AND ''1974-12-31''  
        AND gender = ''Male''';
    
    start_time := clock_timestamp();
    
    EXECUTE 'SELECT COUNT(*) FROM (' || test_query || ') AS subquery'
    INTO row_count;
    
    end_time := clock_timestamp();
    duration_ms := EXTRACT(EPOCH FROM (end_time - start_time)) * 1000;
    
    INSERT INTO performance.benchmark_metrics 
        (test_name, query_text, execution_time_ms, rows_returned, optimization_stage)
    VALUES 
        ('Patient Search (Birth Date + Gender)', test_query, duration_ms, row_count, 'AFTER');
    
    RAISE NOTICE 'Execution Time: % ms', ROUND(duration_ms, 2);
    RAISE NOTICE 'Rows Returned: %', row_count;
    RAISE NOTICE 'Expected: Uses idx_patient_birth_gender_composite (composite)';
    RAISE NOTICE '';
END $$;

-- ============================================================================
-- BENCHMARK TEST 2: Birth Date Range Query (COVERING INDEX)
-- ============================================================================

DO $$
DECLARE
    start_time TIMESTAMP;
    end_time TIMESTAMP;
    duration_ms NUMERIC;
    row_count INT;
    test_query TEXT;
BEGIN
    RAISE NOTICE 'BENCHMARK 2: Birth Date Range (Covering Index)';
    RAISE NOTICE '========================================';
    
    test_query := 'SELECT birth_date, gender, user_id, patient_id 
        FROM app.patient
        WHERE birth_date > ''1980-01-01''';
    
    start_time := clock_timestamp();
    
    EXECUTE 'SELECT COUNT(*) FROM (' || test_query || ') AS subquery'
    INTO row_count;
    
    end_time := clock_timestamp();
    duration_ms := EXTRACT(EPOCH FROM (end_time - start_time)) * 1000;
    
    INSERT INTO performance.benchmark_metrics 
        (test_name, query_text, execution_time_ms, rows_returned, optimization_stage)
    VALUES 
        ('Patient Search (Birth Date Range)', test_query, duration_ms, row_count, 'AFTER');
    
    RAISE NOTICE 'Execution Time: % ms', ROUND(duration_ms, 2);
    RAISE NOTICE 'Rows Returned: %', row_count;
    RAISE NOTICE 'Expected: Index-only scan using idx_patient_birth_covering';
    RAISE NOTICE '';
END $$;

-- ============================================================================
-- BENCHMARK TEST 3: Active Prescriptions (PARTIAL INDEX)
-- ============================================================================

DO $$
DECLARE
    start_time TIMESTAMP;
    end_time TIMESTAMP;
    duration_ms NUMERIC;
    row_count INT;
    test_query TEXT;
BEGIN
    RAISE NOTICE 'BENCHMARK 3: Active Prescriptions (Partial Index)';
    RAISE NOTICE '========================================';
    
    test_query := 'SELECT * FROM app.prescription
        WHERE status = ''Active''';
    
    start_time := clock_timestamp();
    
    EXECUTE 'SELECT COUNT(*) FROM (' || test_query || ') AS subquery'
    INTO row_count;
    
    end_time := clock_timestamp();
    duration_ms := EXTRACT(EPOCH FROM (end_time - start_time)) * 1000;
    
    INSERT INTO performance.benchmark_metrics 
        (test_name, query_text, execution_time_ms, rows_returned, optimization_stage)
    VALUES 
        ('Active Prescriptions', test_query, duration_ms, row_count, 'AFTER');
    
    RAISE NOTICE 'Execution Time: % ms', ROUND(duration_ms, 2);
    RAISE NOTICE 'Rows Returned: %', row_count;
    RAISE NOTICE 'Expected: Uses idx_prescription_active_only (60%% smaller)';
    RAISE NOTICE '';
END $$;

-- ============================================================================
-- BENCHMARK TEST 4: Medication Search (GIN FULL-TEXT INDEX)
-- ============================================================================

DO $$
DECLARE
    start_time TIMESTAMP;
    end_time TIMESTAMP;
    duration_ms NUMERIC;
    row_count INT;
    test_query TEXT;
BEGIN
    RAISE NOTICE 'BENCHMARK 4: Medication Search (Full-Text Index)';
    RAISE NOTICE '========================================';
    
    -- Use GIN full-text index instead of LIKE
    test_query := 'SELECT * FROM app.medication
        WHERE to_tsvector(''english'', med_name || '' '' || COALESCE(med_desc, ''''))
        @@ to_tsquery(''english'', ''insulin | diabetes'')';
    
    start_time := clock_timestamp();
    
    EXECUTE 'SELECT COUNT(*) FROM (' || test_query || ') AS subquery'
    INTO row_count;
    
    end_time := clock_timestamp();
    duration_ms := EXTRACT(EPOCH FROM (end_time - start_time)) * 1000;
    
    INSERT INTO performance.benchmark_metrics 
        (test_name, query_text, execution_time_ms, rows_returned, optimization_stage)
    VALUES 
        ('Medication Search (Full-Text)', test_query, duration_ms, row_count, 'AFTER');
    
    RAISE NOTICE 'Execution Time: % ms', ROUND(duration_ms, 2);
    RAISE NOTICE 'Rows Returned: %', row_count;
    RAISE NOTICE 'Expected: Bitmap Index Scan using idx_medication_fulltext_search';
    RAISE NOTICE '';
END $$;

-- ============================================================================
-- BENCHMARK TEST 5: Patient Health Analytics (Complex Join)
-- ============================================================================

DO $$
DECLARE
    start_time TIMESTAMP;
    end_time TIMESTAMP;
    duration_ms NUMERIC;
    row_count INT;
    test_query TEXT;
BEGIN
    RAISE NOTICE 'BENCHMARK 5: Patient Health Analytics (Complex Join)';
    RAISE NOTICE '========================================';
    
    test_query := 'SELECT 
        p.patient_id,
        u.first_name || '' '' || u.last_name AS patient_name,
        EXTRACT(YEAR FROM AGE(p.birth_date)) AS age,
        COUNT(DISTINCT pr.prescription_id) AS total_prescriptions
    FROM app.patient p
    JOIN app.user_account u ON p.user_id = u.user_id
    LEFT JOIN app.prescription pr ON p.patient_id = pr.patient_id
    GROUP BY p.patient_id, u.first_name, u.last_name, p.birth_date';
    
    start_time := clock_timestamp();
    
    EXECUTE 'SELECT COUNT(*) FROM (' || test_query || ') AS subquery'
    INTO row_count;
    
    end_time := clock_timestamp();
    duration_ms := EXTRACT(EPOCH FROM (end_time - start_time)) * 1000;
    
    INSERT INTO performance.benchmark_metrics 
        (test_name, query_text, execution_time_ms, rows_returned, optimization_stage)
    VALUES 
        ('Patient Health Analytics', test_query, duration_ms, row_count, 'AFTER');
    
    RAISE NOTICE 'Execution Time: % ms', ROUND(duration_ms, 2);
    RAISE NOTICE 'Rows Returned: %', row_count;
    RAISE NOTICE 'Expected: Hash Join + Aggregate (uses FK indexes)';
    RAISE NOTICE '';
END $$;

-- ============================================================================
-- AFTER-OPTIMIZATION SUMMARY
-- ============================================================================

DO $$
DECLARE
    total_time_before NUMERIC;
    total_time_after NUMERIC;
    avg_time_before NUMERIC;
    avg_time_after NUMERIC;
    improvement_pct NUMERIC;
BEGIN
    SELECT 
        SUM(execution_time_ms),
        AVG(execution_time_ms)
    INTO total_time_before, avg_time_before
    FROM performance.benchmark_metrics
    WHERE optimization_stage = 'BEFORE';
    
    SELECT 
        SUM(execution_time_ms),
        AVG(execution_time_ms)
    INTO total_time_after, avg_time_after
    FROM performance.benchmark_metrics
    WHERE optimization_stage = 'AFTER';
    
    improvement_pct := ((total_time_before - total_time_after) / NULLIF(total_time_before, 0)) * 100;
    
    RAISE NOTICE '========================================';
    RAISE NOTICE 'AFTER-OPTIMIZATION SUMMARY';
    RAISE NOTICE '========================================';
    RAISE NOTICE 'Total Time BEFORE: % ms', ROUND(total_time_before, 2);
    RAISE NOTICE 'Total Time AFTER: % ms', ROUND(total_time_after, 2);
    RAISE NOTICE 'Time Saved: % ms', ROUND(total_time_before - total_time_after, 2);
    RAISE NOTICE '';
    RAISE NOTICE 'Average Time BEFORE: % ms', ROUND(avg_time_before, 2);
    RAISE NOTICE 'Average Time AFTER: % ms', ROUND(avg_time_after, 2);
    RAISE NOTICE '';
    RAISE NOTICE '   PERFORMANCE IMPROVEMENT: %%%', ROUND(improvement_pct, 2);
    RAISE NOTICE '';
    RAISE NOTICE '   Next step: Run 04_comparison_report.sql';
    RAISE NOTICE '   This will show side-by-side comparison';
    RAISE NOTICE '========================================';
END $$;

-- Show after results
SELECT 
    test_name AS "Test Name",
    ROUND(execution_time_ms, 2) AS "Time (ms)",
    rows_returned AS "Rows",
    optimization_stage AS "Stage"
FROM performance.benchmark_metrics
WHERE optimization_stage = 'AFTER'
ORDER BY test_name;

COMMIT;