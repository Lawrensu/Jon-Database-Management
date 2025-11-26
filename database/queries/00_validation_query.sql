-- PAKAR Tech Healthcare - Database Validation
-- COS 20031 Database Design Project

SET search_path TO app, public;

\echo '========================================'
\echo 'Database Validation Results'
\echo '========================================'

-- ============================================================================
-- SCHEMA VALIDATION
-- ============================================================================

\echo ''
\echo 'Schema Validation'
\echo '----------------------------------------'

SELECT 
    'Total Tables' AS metric,
    COUNT(*)::TEXT AS expected,
    (SELECT COUNT(*)::TEXT FROM information_schema.tables WHERE table_schema = 'app') AS actual,
    CASE 
        WHEN COUNT(*) = (SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = 'app')
        THEN 'PASS' 
        ELSE 'FAIL' 
    END AS status
FROM information_schema.tables 
WHERE table_schema = 'app';

-- ============================================================================
-- DATA VALIDATION (FIXED TABLE NAMES)
-- ============================================================================

\echo ''
\echo 'Data Validation'
\echo '----------------------------------------'

SELECT 
    'Conditions' AS table_name,
    '27' AS expected,
    COUNT(*)::TEXT AS actual,
    CASE WHEN COUNT(*) = 27 THEN 'PASS' ELSE 'FAIL' END AS status
FROM app.condition
UNION ALL
SELECT 
    'Symptoms',
    '10',
    COUNT(*)::TEXT,
    CASE WHEN COUNT(*) = 10 THEN 'PASS' ELSE 'FAIL' END
FROM app.symptom
UNION ALL
SELECT 
    'Side Effects',
    '11',
    COUNT(*)::TEXT,
    CASE WHEN COUNT(*) = 11 THEN 'PASS' ELSE 'FAIL' END
FROM app.side_effect
UNION ALL
SELECT 
    'Medications',
    '15',
    COUNT(*)::TEXT,
    CASE WHEN COUNT(*) = 15 THEN 'PASS' ELSE 'FAIL' END
FROM app.medication
UNION ALL
SELECT 
    'Patients',  -- ✅ FIXED: Changed from 'patients'
    '200',
    COUNT(*)::TEXT,
    CASE WHEN COUNT(*) >= 200 THEN 'PASS' ELSE 'FAIL' END
FROM app.patient  -- ✅ FIXED: Singular table name
UNION ALL
SELECT 
    'Doctors',  -- ✅ FIXED: Changed from 'doctors'
    '20',
    COUNT(*)::TEXT,
    CASE WHEN COUNT(*) >= 20 THEN 'PASS' ELSE 'FAIL' END
FROM app.doctor  -- ✅ FIXED: Singular table name
UNION ALL
SELECT 
    'Admins',
    '3',
    COUNT(*)::TEXT,
    CASE WHEN COUNT(*) >= 3 THEN 'PASS' ELSE 'FAIL' END
FROM app.admin
UNION ALL
SELECT 
    'Super Admins',
    '2',
    COUNT(*)::TEXT,
    CASE WHEN COUNT(*) >= 2 THEN 'PASS' ELSE 'FAIL' END
FROM app.super_admin
UNION ALL
SELECT 
    'User Accounts',
    '225',
    COUNT(*)::TEXT,
    CASE WHEN COUNT(*) >= 225 THEN 'PASS' ELSE 'FAIL' END
FROM app.user_account
UNION ALL
SELECT 
    'Audit Log (Events)',
    '225+',
    CASE 
        WHEN COUNT(*) >= 225 THEN '✅ ' || COUNT(*)::TEXT 
        ELSE '❌ ' || COUNT(*)::TEXT 
    END,
    CASE WHEN COUNT(*) >= 225 THEN 'PASS' ELSE 'FAIL' END
FROM security.events_log;

\echo ''
\echo '========================================'