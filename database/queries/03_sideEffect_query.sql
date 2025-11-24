-- PAKAR Tech Healthcare - Side Effects Analysis
-- COS 20031 Database Design Project
-- Author: Jason Hernando Kwee
-- Purpose: Query side effects through medication → side_effect → condition linkage

SET search_path TO app, public;

-- ============================================================================
-- QUERY 1: View All Side Effects with Condition Codes
-- ============================================================================
\echo '============================================'
\echo '📊 QUERY 1: All Side Effects with Condition Codes'
\echo '============================================'

SELECT 
    se.side_effect_id,
    'C' || LPAD(c.condition_id::TEXT, 3, '0') AS condition_code,
    c.condition_name AS side_effect_name,
    c.condition_desc AS side_effect_description,
    COUNT(DISTINCT mse.medication_id) AS total_medications,
    STRING_AGG(DISTINCT mse.frequency, ', ' ORDER BY mse.frequency) AS frequencies_reported
FROM app.side_effect se
JOIN app.condition c ON se.condition_id = c.condition_id
LEFT JOIN app.medication_side_effect mse ON se.side_effect_id = mse.side_effect_id
GROUP BY se.side_effect_id, c.condition_id, c.condition_name, c.condition_desc
ORDER BY total_medications DESC, c.condition_name;

-- ============================================================================
-- QUERY 2: Medications and Their Side Effects (with Condition Codes)
-- ============================================================================
\echo ''
\echo '============================================'
\echo '💊 QUERY 2: Medications with Side Effects'
\echo '============================================'

SELECT 
    m.medication_id,
    m.med_name,
    m.med_brand_name,
    m.med_manufacturer,
    'C' || LPAD(c.condition_id::TEXT, 3, '0') AS condition_code,
    c.condition_name AS side_effect,
    c.condition_desc AS side_effect_description,
    mse.frequency,
    CASE mse.frequency
        WHEN 'Common' THEN '⚠️ High Risk'
        WHEN 'Uncommon' THEN '⚡ Moderate Risk'
        WHEN 'Rare' THEN '✓ Low Risk'
        ELSE '❓ Unknown'
    END AS risk_level
FROM app.medication m
JOIN app.medication_side_effect mse ON m.medication_id = mse.medication_id
JOIN app.side_effect se ON mse.side_effect_id = se.side_effect_id
JOIN app.condition c ON se.condition_id = c.condition_id
ORDER BY 
    m.med_name,
    CASE mse.frequency
        WHEN 'Common' THEN 1
        WHEN 'Uncommon' THEN 2
        WHEN 'Rare' THEN 3
        ELSE 4
    END,
    c.condition_name;

-- ============================================================================
-- QUERY 3: Specific Medication Side Effect Lookup
-- ============================================================================
\echo ''
\echo '============================================'
\echo '🔍 QUERY 3: Side Effects for Specific Medication'
\echo '============================================'
\echo 'Example: Metformin Hydrochloride'

SELECT 
    m.med_name AS medication,
    m.med_brand_name AS brand,
    'C' || LPAD(c.condition_id::TEXT, 3, '0') AS condition_code,
    c.condition_name AS side_effect,
    c.condition_desc AS description,
    mse.frequency,
    CASE 
        WHEN mse.frequency = 'Common' THEN 'Occurs in >10% of patients'
        WHEN mse.frequency = 'Uncommon' THEN 'Occurs in 1-10% of patients'
        WHEN mse.frequency = 'Rare' THEN 'Occurs in <1% of patients'
        ELSE 'Frequency not specified'
    END AS frequency_detail
FROM app.medication m
JOIN app.medication_side_effect mse ON m.medication_id = mse.medication_id
JOIN app.side_effect se ON mse.side_effect_id = se.side_effect_id
JOIN app.condition c ON se.condition_id = c.condition_id
WHERE m.med_name = 'Metformin Hydrochloride'
ORDER BY 
    CASE mse.frequency
        WHEN 'Common' THEN 1
        WHEN 'Uncommon' THEN 2
        WHEN 'Rare' THEN 3
    END;

-- ============================================================================
-- QUERY 4: Condition Lookup - Show if it's a Symptom AND/OR Side Effect
-- ============================================================================
\echo ''
\echo '============================================'
\echo '🔬 QUERY 4: Conditions as Symptoms vs Side Effects'
\echo '============================================'

SELECT 
    'C' || LPAD(c.condition_id::TEXT, 3, '0') AS condition_code,
    c.condition_name,
    c.condition_desc,
    CASE 
        WHEN EXISTS (SELECT 1 FROM app.symptom s WHERE s.condition_id = c.condition_id) 
        THEN '✓ Yes' 
        ELSE '✗ No' 
    END AS is_symptom,
    CASE 
        WHEN EXISTS (SELECT 1 FROM app.side_effect se WHERE se.condition_id = c.condition_id) 
        THEN '✓ Yes' 
        ELSE '✗ No' 
    END AS is_side_effect,
    (SELECT COUNT(*) FROM app.patient_symptom ps 
     JOIN app.symptom s ON ps.symptom_id = s.symptom_id 
     WHERE s.condition_id = c.condition_id) AS times_reported_as_symptom,
    (SELECT COUNT(*) FROM app.medication_side_effect mse 
     JOIN app.side_effect se ON mse.side_effect_id = se.side_effect_id 
     WHERE se.condition_id = c.condition_id) AS times_linked_to_medications
FROM app.condition c
ORDER BY c.condition_name;

-- ============================================================================
-- QUERY 5: Find Medications by Side Effect (Using Condition Code)
-- ============================================================================
\echo ''
\echo '============================================'
\echo '🎯 QUERY 5: Find Medications Causing Specific Side Effect'
\echo '============================================'
\echo 'Example: Headache (C011)'

DO $$
DECLARE
    v_condition_code TEXT := 'C011';  -- Change this to test different conditions
    v_condition_id INT;
    v_condition_name TEXT;
BEGIN
    -- Extract numeric part from code (C011 -> 11)
    v_condition_id := SUBSTRING(v_condition_code FROM 2)::INT;
    
    SELECT condition_name INTO v_condition_name 
    FROM app.condition 
    WHERE condition_id = v_condition_id;
    
    RAISE NOTICE 'Searching for medications causing: % (Code: %)', v_condition_name, v_condition_code;
    
    -- Show results in a table
    PERFORM * FROM (
        SELECT 
            m.med_name,
            m.med_brand_name,
            mse.frequency,
            'C' || LPAD(c.condition_id::TEXT, 3, '0') AS condition_code,
            c.condition_name AS side_effect
        FROM app.medication m
        JOIN app.medication_side_effect mse ON m.medication_id = mse.medication_id
        JOIN app.side_effect se ON mse.side_effect_id = se.side_effect_id
        JOIN app.condition c ON se.condition_id = c.condition_id
        WHERE c.condition_id = v_condition_id
        ORDER BY 
            CASE mse.frequency
                WHEN 'Common' THEN 1
                WHEN 'Uncommon' THEN 2
                WHEN 'Rare' THEN 3
            END,
            m.med_name
    ) AS results;
END $$;

SELECT 
    m.med_name,
    m.med_brand_name,
    mse.frequency,
    'C' || LPAD(c.condition_id::TEXT, 3, '0') AS condition_code,
    c.condition_name AS side_effect
FROM app.medication m
JOIN app.medication_side_effect mse ON m.medication_id = mse.medication_id
JOIN app.side_effect se ON mse.side_effect_id = se.side_effect_id
JOIN app.condition c ON se.condition_id = c.condition_id
WHERE c.condition_name = 'Headache'  -- Change this to test other conditions
ORDER BY 
    CASE mse.frequency
        WHEN 'Common' THEN 1
        WHEN 'Uncommon' THEN 2
        WHEN 'Rare' THEN 3
    END,
    m.med_name;

-- ============================================================================
-- QUERY 6: Side Effects Statistics Dashboard
-- ============================================================================
\echo ''
\echo '============================================'
\echo '📈 QUERY 6: Side Effects Statistics'
\echo '============================================'

WITH side_effect_stats AS (
    SELECT 
        'C' || LPAD(c.condition_id::TEXT, 3, '0') AS condition_code,
        c.condition_name AS side_effect_name,
        COUNT(DISTINCT mse.medication_id) AS medication_count,
        COUNT(CASE WHEN mse.frequency = 'Common' THEN 1 END) AS common_count,
        COUNT(CASE WHEN mse.frequency = 'Uncommon' THEN 1 END) AS uncommon_count,
        COUNT(CASE WHEN mse.frequency = 'Rare' THEN 1 END) AS rare_count,
        STRING_AGG(DISTINCT m.med_name, ', ' ORDER BY m.med_name) AS medications
    FROM app.side_effect se
    JOIN app.condition c ON se.condition_id = c.condition_id
    LEFT JOIN app.medication_side_effect mse ON se.side_effect_id = mse.side_effect_id
    LEFT JOIN app.medication m ON mse.medication_id = m.medication_id
    GROUP BY c.condition_id, c.condition_name
)
SELECT 
    condition_code,
    side_effect_name,
    medication_count,
    common_count,
    uncommon_count,
    rare_count,
    CASE 
        WHEN medication_count >= 5 THEN '🔴 High Impact'
        WHEN medication_count >= 3 THEN '🟡 Moderate Impact'
        WHEN medication_count >= 1 THEN '🟢 Low Impact'
        ELSE '⚪ No Data'
    END AS impact_level,
    CASE 
        WHEN LENGTH(medications) > 100 
        THEN LEFT(medications, 97) || '...'
        ELSE medications
    END AS medication_list
FROM side_effect_stats
ORDER BY medication_count DESC, side_effect_name;

-- ============================================================================
-- QUERY 7: Create Reusable View for Side Effects with Condition Codes
-- ============================================================================
\echo ''
\echo '============================================'
\echo '📌 QUERY 7: Creating Reusable View'
\echo '============================================'

CREATE OR REPLACE VIEW app.v_side_effects_with_codes AS
SELECT 
    se.side_effect_id,
    'C' || LPAD(c.condition_id::TEXT, 3, '0') AS condition_code,
    c.condition_id,
    c.condition_name AS side_effect_name,
    c.condition_desc AS side_effect_description,
    COUNT(DISTINCT mse.medication_id) AS total_medications,
    COUNT(CASE WHEN mse.frequency = 'Common' THEN 1 END) AS common_frequency_count,
    COUNT(CASE WHEN mse.frequency = 'Uncommon' THEN 1 END) AS uncommon_frequency_count,
    COUNT(CASE WHEN mse.frequency = 'Rare' THEN 1 END) AS rare_frequency_count,
    STRING_AGG(DISTINCT mse.frequency, ', ' ORDER BY mse.frequency) AS frequencies,  -- ✅ FIXED
    STRING_AGG(
        m.med_name || ' (' || COALESCE(mse.frequency, 'Unknown') || ')',  
        ', ' 
        ORDER BY m.med_name                                                 
    ) AS medication_list
FROM app.side_effect se
JOIN app.condition c ON se.condition_id = c.condition_id
LEFT JOIN app.medication_side_effect mse ON se.side_effect_id = mse.side_effect_id
LEFT JOIN app.medication m ON mse.medication_id = m.medication_id
GROUP BY se.side_effect_id, c.condition_id, c.condition_name, c.condition_desc
ORDER BY total_medications DESC, c.condition_name;

COMMENT ON VIEW app.v_side_effects_with_codes IS 
'Side effects with condition codes (C001, C002, etc.) showing medication linkages';

\echo '✅ View created: app.v_side_effects_with_codes'

-- Test the view
SELECT * FROM app.v_side_effects_with_codes LIMIT 5;

-- ============================================================================
-- QUERY 8: Summary Report
-- ============================================================================
\echo ''
\echo '============================================'
\echo '📊 SUMMARY REPORT'
\echo '============================================'

SELECT 
    'Total Conditions' AS metric,
    COUNT(*)::text AS value
FROM app.condition
UNION ALL
SELECT 'Conditions Used as Side Effects', COUNT(DISTINCT se.condition_id)::text
FROM app.side_effect se
UNION ALL
SELECT 'Conditions Used as Symptoms', COUNT(DISTINCT s.condition_id)::text
FROM app.symptom s
UNION ALL
SELECT 'Total Medication-Side Effect Links', COUNT(*)::text
FROM app.medication_side_effect
UNION ALL
SELECT 'Medications with Side Effects', COUNT(DISTINCT medication_id)::text
FROM app.medication_side_effect
UNION ALL
SELECT 'Common Side Effects', COUNT(*)::text
FROM app.medication_side_effect WHERE frequency = 'Common'
UNION ALL
SELECT 'Uncommon Side Effects', COUNT(*)::text
FROM app.medication_side_effect WHERE frequency = 'Uncommon'
UNION ALL
SELECT 'Rare Side Effects', COUNT(*)::text
FROM app.medication_side_effect WHERE frequency = 'Rare';

\echo ''
\echo '✅ Side Effects Query Completed Successfully!'