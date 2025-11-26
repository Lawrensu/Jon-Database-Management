SET search_path TO app, public;

-- ============================================================================
-- TEST QUERY: Count records in each table
-- ============================================================================

SELECT 
    'Conditions' AS table_name,
    COUNT(*) AS record_count
FROM app.condition
UNION ALL
SELECT 
    'Medications',
    COUNT(*)
FROM app.medication
UNION ALL
SELECT 
    'Symptoms',
    COUNT(*)
FROM app.symptom;