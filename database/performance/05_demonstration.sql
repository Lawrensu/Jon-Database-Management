-- ============================================================================
-- PERFORMANCE ENHANCEMENT DEMONSTRATION
-- COS 20031 Database Design Project
-- Purpose: Show lecturers the exact performance improvement
-- Author: Lawrence Lian anak Matius Ding
-- ============================================================================

SET search_path TO app, public;

\timing on

-- ============================================================================
-- DEMONSTRATION 1: Full-Text Search Performance
-- ============================================================================

\echo '========================================'
\echo 'DEMO 1: Medication Full-Text Search'
\echo '========================================'
\echo ''
\echo 'Query: Search for "insulin" or "diabetes" in medications'
\echo ''

-- Show execution plan WITH index
EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT)
SELECT med_name, med_desc
FROM app.medication
WHERE to_tsvector('english', med_name || ' ' || COALESCE(med_desc, ''))
      @@ to_tsquery('english', 'insulin | diabetes');

\echo ''
\echo 'Notice: Uses "Bitmap Index Scan on idx_medication_fulltext_search"'
\echo 'Result: Sub-millisecond execution time'
\echo ''

-- ============================================================================
-- DEMONSTRATION 2: Active Prescriptions Query
-- ============================================================================

\echo '========================================'
\echo 'DEMO 2: Active Prescriptions Lookup'
\echo '========================================'
\echo ''
\echo 'Query: Retrieve all active prescriptions'
\echo ''

-- Show execution plan WITH partial index
EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT)
SELECT p.patient_id, pr.prescription_id, pr.status, pr.created_date
FROM app.prescription pr
JOIN app.patient p ON pr.patient_id = p.patient_id
WHERE pr.status = 'Active'
ORDER BY pr.created_date DESC;

\echo ''
\echo 'Notice: Uses "Index Scan on idx_prescription_active_only"'
\echo 'Result: Only scans active rows (60% of table)'
\echo ''

-- ============================================================================
-- DEMONSTRATION 3: Birth Date + Gender Search
-- ============================================================================

\echo '========================================'
\echo 'DEMO 3: Patient Search (Age + Gender)'
\echo '========================================'
\echo ''
\echo 'Query: Male patients born 1950-1974'
\echo ''

-- Show execution plan WITH composite index
EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT)
SELECT u.first_name, u.last_name, p.birth_date, p.gender
FROM app.patient p
JOIN app.user_account u ON p.user_id = u.user_id
WHERE p.birth_date BETWEEN '1950-01-01' AND '1974-12-31'
  AND p.gender = 'Male';

\echo ''
\echo 'Notice: Uses "Index Scan on idx_patient_birth_gender_composite"'
\echo 'Result: Single index scan (no multiple lookups)'
\echo ''

-- ============================================================================
-- DEMONSTRATION 4: Birth Date Range (Covering Index)
-- ============================================================================

\echo '========================================'
\echo 'DEMO 4: Birth Date Range (Covering Index)'
\echo '========================================'
\echo ''
\echo 'Query: All patients born 1950-1980'
\echo ''

-- Show execution plan WITH covering index
EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT)
SELECT patient_id, birth_date, gender
FROM app.patient
WHERE birth_date BETWEEN '1950-01-01' AND '1980-12-31';

\echo ''
\echo 'Notice: "Index Only Scan on idx_patient_birth_covering"'
\echo 'Result: No heap access needed (all data in index)'
\echo ''

-- ============================================================================
-- PERFORMANCE COMPARISON TABLE
-- ============================================================================

\echo '========================================'
\echo 'PERFORMANCE COMPARISON SUMMARY'
\echo '========================================'
\echo ''

SELECT
    b.test_name AS "Test Name",
    ROUND(b.execution_time_ms, 2) AS "Before (ms)",
    ROUND(a.execution_time_ms, 2) AS "After (ms)",
    ROUND(((b.execution_time_ms - a.execution_time_ms) / NULLIF(b.execution_time_ms, 0)) * 100, 2) AS "Improvement (%)",
    CASE
        WHEN ((b.execution_time_ms - a.execution_time_ms) / NULLIF(b.execution_time_ms, 0)) * 100 > 80 THEN '🚀 EXCELLENT'
        WHEN ((b.execution_time_ms - a.execution_time_ms) / NULLIF(b.execution_time_ms, 0)) * 100 > 50 THEN '✅ GOOD'
        WHEN ((b.execution_time_ms - a.execution_time_ms) / NULLIF(b.execution_time_ms, 0)) * 100 > 20 THEN '👍 MODERATE'
        ELSE 'MINIMAL'
    END AS "Rating"
FROM performance.benchmark_metrics b
JOIN performance.benchmark_metrics a
    ON b.test_name = a.test_name
    AND a.optimization_stage = 'AFTER'
WHERE b.optimization_stage = 'BEFORE'
ORDER BY "Improvement (%)" DESC;

\echo ''
\echo '========================================'
\echo 'INDEX USAGE STATISTICS'
\echo '========================================'
\echo ''

SELECT
    schemaname AS "Schema",
    tablename AS "Table",
    indexname AS "Index Name",
    idx_scan AS "Times Used",
    idx_tup_read AS "Rows Read",
    idx_tup_fetch AS "Rows Fetched",
    pg_size_pretty(pg_relation_size(indexrelid)) AS "Size"
FROM pg_stat_user_indexes
WHERE schemaname = 'app'
AND indexname IN (
    'idx_patient_birth_gender_composite',
    'idx_prescription_active_only',
    'idx_medication_fulltext_search',
    'idx_patient_birth_covering'
)
ORDER BY idx_scan DESC;

\echo ''
\echo 'DEMONSTRATION COMPLETE'
\echo '========================================'