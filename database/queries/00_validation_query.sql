-- PAKAR Tech Healthcare Database - Validation Queries
-- COS 20031 Database Design Project
-- File: 00_validation_queries.sql
-- Purpose: Verify schema and data integrity

SET search_path TO app, public;

-- ============================================================================
-- QUERY 1: Schema Validation
-- ============================================================================

SELECT 
    'Schema Validation' AS test_name,
    (SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = 'app') AS tables_created,
    16 AS expected_tables,
    CASE 
        WHEN (SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = 'app') = 16 
        THEN '✅ PASS' 
        ELSE '❌ FAIL' 
    END AS result;

-- ============================================================================
-- QUERY 2: Reference Data Counts
-- ============================================================================

SELECT 
    'Conditions' AS data_type,
    COUNT(*) AS record_count,
    27 AS expected_count,
    CASE WHEN COUNT(*) >= 27 THEN '✅ PASS' ELSE '❌ FAIL' END AS result
FROM app.condition
UNION ALL
SELECT 
    'Symptoms',
    COUNT(*),
    10,
    CASE WHEN COUNT(*) >= 10 THEN '✅ PASS' ELSE '❌ FAIL' END
FROM app.symptom
UNION ALL
SELECT 
    'Side Effects',
    COUNT(*),
    11,
    CASE WHEN COUNT(*) >= 11 THEN '✅ PASS' ELSE '❌ FAIL' END
FROM app.side_effect
UNION ALL
SELECT 
    'Medications',
    COUNT(*),
    15,
    CASE WHEN COUNT(*) >= 15 THEN '✅ PASS' ELSE '❌ FAIL' END
FROM app.medication;

-- ============================================================================
-- QUERY 3: Foreign Key Integrity
-- ============================================================================

SELECT 
    'Symptom → Condition FK' AS test_name,
    COUNT(*) AS orphaned_records,
    CASE WHEN COUNT(*) = 0 THEN '✅ PASS' ELSE '❌ FAIL' END AS result
FROM app.symptom s
LEFT JOIN app.condition c ON s.condition_id = c.condition_id
WHERE c.condition_id IS NULL

UNION ALL

SELECT 
    'SideEffect → Condition FK',
    COUNT(*),
    CASE WHEN COUNT(*) = 0 THEN '✅ PASS' ELSE '❌ FAIL' END
FROM app.side_effect se
LEFT JOIN app.condition c ON se.condition_id = c.condition_id
WHERE c.condition_id IS NULL

UNION ALL

SELECT 
    'MedSideEffect → Medication FK',
    COUNT(*),
    CASE WHEN COUNT(*) = 0 THEN '✅ PASS' ELSE '❌ FAIL' END
FROM app.medication_side_effect mse
LEFT JOIN app.medication m ON mse.medication_id = m.medication_id
WHERE m.medication_id IS NULL;

-- ============================================================================
-- QUERY 4: Unique Constraint Validation
-- ============================================================================

SELECT 
    'Duplicate condition names' AS test_name,
    COUNT(*) - COUNT(DISTINCT condition_name) AS duplicate_count,
    CASE 
        WHEN COUNT(*) = COUNT(DISTINCT condition_name) 
        THEN '✅ PASS' 
        ELSE '❌ FAIL' 
    END AS result
FROM app.condition;

-- ============================================================================
-- QUERY 5: Enum Type Validation
-- ============================================================================

SELECT 
    'Custom ENUM types' AS test_name,
    COUNT(*) AS enum_count,
    8 AS expected_count,
    CASE WHEN COUNT(*) = 8 THEN '✅ PASS' ELSE '❌ FAIL' END AS result
FROM pg_type 
WHERE typname IN (
    'user_type_enum', 
    'gender_enum', 
    'severity_enum', 
    'prescription_status_enum',
    'titration_unit_enum', 
    'med_timing_enum', 
    'duration_unit_enum', 
    'med_log_status_enum'
);

-- ============================================================================
-- QUERY 6: Index Coverage
-- ============================================================================

SELECT 
    schemaname,
    tablename,
    COUNT(*) AS index_count
FROM pg_indexes
WHERE schemaname = 'app'
GROUP BY schemaname, tablename
ORDER BY tablename;

-- ============================================================================
-- QUERY 7: Sample Data Report
-- ============================================================================

SELECT 
    c.condition_name,
    COUNT(DISTINCT s.symptom_id) AS used_as_symptom,
    COUNT(DISTINCT se.side_effect_id) AS used_as_side_effect
FROM app.condition c
LEFT JOIN app.symptom s ON c.condition_id = s.condition_id
LEFT JOIN app.side_effect se ON c.condition_id = se.condition_id
GROUP BY c.condition_name
ORDER BY c.condition_name;