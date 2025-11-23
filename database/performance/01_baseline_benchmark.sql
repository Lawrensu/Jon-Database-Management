-- ============================================================================
-- PAKAR Tech Healthcare - Performance Baseline (This is BEFORE Optimization)
-- COS 20031 Database Design Project
-- Purpose: Capture performance metrics before optimization
-- Author: Lawrence Lian anak Matius Ding
-- ============================================================================

SET search_path TO app, public;

\timing on

-- ============================================================================
-- CREATE PERFORMANCE TRACKING SCHEMA
-- ============================================================================

CREATE SCHEMA IF NOT EXISTS performance;

CREATE TABLE IF NOT EXISTS performance.benchmark_metrics (
    benchmark_id SERIAL PRIMARY KEY,
    test_name TEXT NOT NULL,
    query_text TEXT,
    execution_time_ms NUMERIC,
    rows_returned INT,
    query_plan TEXT,
    optimization_stage TEXT DEFAULT 'BEFORE',
    measured_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================================
-- BENCHMARK TEST 1: Patient Search by Age and Gender
-- ============================================================================

DO $$
DECLARE
    start_time TIMESTAMP;
    end_time TIMESTAMP;
    duration_ms NUMERIC;
    row_count INT;
    test_query TEXT;
BEGIN
    RAISE NOTICE '========================================';
    RAISE NOTICE 'BENCHMARK 1: Patient Search (Age + Gender)';
    RAISE NOTICE '========================================';
    
    test_query := 'SELECT * FROM app.patient p
        JOIN app.user_account u ON p.user_id = u.user_id
        WHERE EXTRACT(YEAR FROM AGE(p.birth_date)) > 50
        AND p.gender = ''Male''';
    
    -- Measure execution time
    start_time := clock_timestamp();
    
    EXECUTE 'SELECT COUNT(*) FROM (' || test_query || ') AS subquery'
    INTO row_count;
    
    end_time := clock_timestamp();
    duration_ms := EXTRACT(EPOCH FROM (end_time - start_time)) * 1000;
    
    -- Store baseline
    INSERT INTO performance.benchmark_metrics 
        (test_name, query_text, execution_time_ms, rows_returned, optimization_stage)
    VALUES 
        ('Patient Search (Age + Gender)', test_query, duration_ms, row_count, 'BEFORE');
    
    RAISE NOTICE 'Execution Time: % ms', ROUND(duration_ms, 2);
    RAISE NOTICE 'Rows Returned: %', row_count;
    RAISE NOTICE 'Query Type: Sequential Scan (SLOW - no index on calculated age)';
    RAISE NOTICE '';
END $$;

-- ============================================================================
-- BENCHMARK TEST 2: Patient Search by Birth Date Range
-- ============================================================================

DO $$
DECLARE
    start_time TIMESTAMP;
    end_time TIMESTAMP;
    duration_ms NUMERIC;
    row_count INT;
    test_query TEXT;
BEGIN
    RAISE NOTICE 'BENCHMARK 2: Patient Search (Birth Date Range)';
    RAISE NOTICE '========================================';
    
    test_query := 'SELECT * FROM app.patient
        WHERE birth_date BETWEEN ''1950-01-01'' AND ''1980-12-31''';
    
    start_time := clock_timestamp();
    
    EXECUTE 'SELECT COUNT(*) FROM (' || test_query || ') AS subquery'
    INTO row_count;
    
    end_time := clock_timestamp();
    duration_ms := EXTRACT(EPOCH FROM (end_time - start_time)) * 1000;
    
    INSERT INTO performance.benchmark_metrics 
        (test_name, query_text, execution_time_ms, rows_returned, optimization_stage)
    VALUES 
        ('Patient Search (Birth Date Range)', test_query, duration_ms, row_count, 'BEFORE');
    
    RAISE NOTICE 'Execution Time: % ms', ROUND(duration_ms, 2);
    RAISE NOTICE 'Rows Returned: %', row_count;
    RAISE NOTICE 'Query Type: Index Scan (uses existing idx_patient_birth_date)';
    RAISE NOTICE '';
END $$;

-- ============================================================================
-- BENCHMARK TEST 3: Active Prescriptions Query
-- ============================================================================

DO $$
DECLARE
    start_time TIMESTAMP;
    end_time TIMESTAMP;
    duration_ms NUMERIC;
    row_count INT;
    test_query TEXT;
BEGIN
    RAISE NOTICE 'BENCHMARK 3: Active Prescriptions';
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
        ('Active Prescriptions', test_query, duration_ms, row_count, 'BEFORE');
    
    RAISE NOTICE 'Execution Time: % ms', ROUND(duration_ms, 2);
    RAISE NOTICE 'Rows Returned: %', row_count;
    RAISE NOTICE 'Query Type: Index Scan (uses existing idx_prescription_status)';
    RAISE NOTICE '';
END $$;

-- ============================================================================
-- BENCHMARK TEST 4: Medication Search (Text Search)
-- ============================================================================

DO $$
DECLARE
    start_time TIMESTAMP;
    end_time TIMESTAMP;
    duration_ms NUMERIC;
    row_count INT;
    test_query TEXT;
BEGIN
    RAISE NOTICE 'BENCHMARK 4: Medication Search (LIKE query)';
    RAISE NOTICE '========================================';
    
    test_query := 'SELECT * FROM app.medication
        WHERE med_name LIKE ''%insulin%'' 
        OR med_desc LIKE ''%diabetes%''';
    
    start_time := clock_timestamp();
    
    EXECUTE 'SELECT COUNT(*) FROM (' || test_query || ') AS subquery'
    INTO row_count;
    
    end_time := clock_timestamp();
    duration_ms := EXTRACT(EPOCH FROM (end_time - start_time)) * 1000;
    
    INSERT INTO performance.benchmark_metrics 
        (test_name, query_text, execution_time_ms, rows_returned, optimization_stage)
    VALUES 
        ('Medication Search (LIKE)', test_query, duration_ms, row_count, 'BEFORE');
    
    RAISE NOTICE 'Execution Time: % ms', ROUND(duration_ms, 2);
    RAISE NOTICE 'Rows Returned: %', row_count;
    RAISE NOTICE 'Query Type: Sequential Scan (LIKE cannot use index efficiently)';
    RAISE NOTICE '';
END $$;

-- ============================================================================
-- BENCHMARK TEST 5: Complex Patient Analytics (Expensive Query)
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
        ('Patient Health Analytics', test_query, duration_ms, row_count, 'BEFORE');
    
    RAISE NOTICE 'Execution Time: % ms', ROUND(duration_ms, 2);
    RAISE NOTICE 'Rows Returned: %', row_count;
    RAISE NOTICE 'Query Type: Hash Join + Aggregate (EXPENSIVE)';
    RAISE NOTICE '';
END $$;

-- ============================================================================
-- BASELINE SUMMARY
-- ============================================================================

DO $$
DECLARE
    total_time NUMERIC;
    avg_time NUMERIC;
    slowest_query TEXT;
    slowest_time NUMERIC;
BEGIN
    SELECT 
        SUM(execution_time_ms),
        AVG(execution_time_ms)
    INTO total_time, avg_time
    FROM performance.benchmark_metrics
    WHERE optimization_stage = 'BEFORE';
    
    SELECT test_name, execution_time_ms
    INTO slowest_query, slowest_time
    FROM performance.benchmark_metrics
    WHERE optimization_stage = 'BEFORE'
    ORDER BY execution_time_ms DESC
    LIMIT 1;
    
    RAISE NOTICE '========================================';
    RAISE NOTICE 'BASELINE PERFORMANCE SUMMARY';
    RAISE NOTICE '========================================';
    RAISE NOTICE 'Total Execution Time: % ms', ROUND(total_time, 2);
    RAISE NOTICE 'Average Query Time: % ms', ROUND(avg_time, 2);
    RAISE NOTICE 'Slowest Query: %', slowest_query;
    RAISE NOTICE 'Slowest Time: % ms', ROUND(slowest_time, 2);
    RAISE NOTICE '';
    RAISE NOTICE '📊 Baseline captured to: performance.benchmark_metrics';
    RAISE NOTICE '📌 Next step: Run 02_advanced_indexes.sql to apply optimizations';
    RAISE NOTICE '========================================';
END $$;

-- Show baseline results
SELECT 
    test_name AS "Test Name",
    ROUND(execution_time_ms, 2) AS "Time (ms)",
    rows_returned AS "Rows",
    optimization_stage AS "Stage"
FROM performance.benchmark_metrics
WHERE optimization_stage = 'BEFORE'
ORDER BY execution_time_ms DESC;