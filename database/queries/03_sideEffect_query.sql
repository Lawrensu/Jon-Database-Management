-- PAKAR Tech Healthcare - Side Effects Analysis
-- COS 20031 Database Design Project
-- Author: Jason Hernando Kwee
-- Purpose: Query side effects through medication → side_effect → condition linkage

SET search_path TO app, public;

\echo '========================================'
\echo 'Side Effects Analysis'
\echo '========================================'

-- ============================================================================
-- QUERY 1: ALL SIDE EFFECTS (DEDUPLICATED)
-- ============================================================================

\echo ''
\echo 'QUERY 1: All Side Effects (Condition-Based)'
\echo '----------------------------------------'

SELECT DISTINCT ON (c.condition_id)
    se.side_effect_id,
    c.condition_id,
    c.condition_name AS side_effect_name,
    c.condition_desc AS description
FROM app.side_effect se
JOIN app.condition c ON se.condition_id = c.condition_id
ORDER BY c.condition_id, se.side_effect_id;

-- ============================================================================
-- QUERY 2: MEDICATIONS WITH SIDE EFFECTS (DEDUPLICATED)
-- ============================================================================

\echo ''
\echo 'QUERY 2: Medications with Side Effects (ID-Based Matching)'
\echo '----------------------------------------'

SELECT 
    m.medication_id,
    m.med_name,
    m.med_brand_name,
    se.side_effect_id,
    c.condition_name AS side_effect_name,
    mse.frequency,
    c.condition_desc AS description
FROM app.medication_side_effect mse
JOIN app.medication m ON mse.medication_id = m.medication_id
JOIN app.side_effect se ON mse.side_effect_id = se.side_effect_id
JOIN app.condition c ON se.condition_id = c.condition_id
WHERE m.medication_id IN (
    SELECT DISTINCT ON (med_name) medication_id
    FROM app.medication
    ORDER BY med_name, medication_id
)
ORDER BY m.med_name, mse.frequency DESC, c.condition_name;

-- ============================================================================
-- QUERY 3: SIDE EFFECTS BY MEDICATION (DEDUPLICATED)
-- ============================================================================

\echo ''
\echo 'QUERY 3: Side Effects by Medication'
\echo '----------------------------------------'

SELECT DISTINCT ON (m.med_name)
    m.medication_id,
    m.med_name,
    m.med_brand_name,
    (
        SELECT COUNT(DISTINCT mse2.side_effect_id)
        FROM app.medication_side_effect mse2
        WHERE mse2.medication_id = m.medication_id
    ) AS side_effect_count
FROM app.medication m
ORDER BY m.med_name, m.medication_id;

\echo ''
\echo '📊 Side Effects for Each Medication:'
\echo '----------------------------------------'

SELECT 
    m.med_name,
    m.med_brand_name,
    c.condition_name AS side_effect,
    mse.frequency,
    c.condition_desc AS description
FROM app.medication m
JOIN app.medication_side_effect mse ON m.medication_id = mse.medication_id
JOIN app.side_effect se ON mse.side_effect_id = se.side_effect_id
JOIN app.condition c ON se.condition_id = c.condition_id
WHERE m.medication_id IN (
    SELECT DISTINCT ON (med_name) medication_id
    FROM app.medication
    ORDER BY med_name, medication_id
)
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
-- QUERY 4: MEDICATIONS GROUPED BY SIDE EFFECT
-- ============================================================================

\echo ''
\echo 'QUERY 4: Medications Grouped by Side Effect'
\echo '----------------------------------------'

SELECT 
    c.condition_name AS side_effect,
    COUNT(DISTINCT m.med_name) AS medication_count,
    STRING_AGG(DISTINCT m.med_name, ', ') AS medications,
    STRING_AGG(DISTINCT mse.frequency, ', ') AS frequencies
FROM app.medication_side_effect mse
JOIN app.side_effect se ON mse.side_effect_id = se.side_effect_id
JOIN app.condition c ON se.condition_id = c.condition_id
JOIN app.medication m ON mse.medication_id = m.medication_id
WHERE m.medication_id IN (
    SELECT DISTINCT ON (med_name) medication_id
    FROM app.medication
    ORDER BY med_name, medication_id
)
GROUP BY c.condition_id, c.condition_name
HAVING COUNT(DISTINCT m.med_name) > 1
ORDER BY medication_count DESC, c.condition_name;

-- ============================================================================
-- QUERY 5: PATIENT PRESCRIPTIONS WITH POTENTIAL SIDE EFFECTS
-- ============================================================================

\echo ''
\echo 'QUERY 5: Patient Prescriptions with Potential Side Effects'
\echo '----------------------------------------'

SELECT 
    pr.patient_id,
    u.first_name || ' ' || u.last_name AS patient_name,
    m.med_name AS medication,
    c.condition_name AS potential_side_effect,
    mse.frequency,
    pr.status AS prescription_status
FROM app.prescription pr
JOIN app.prescription_version pv ON pr.prescription_id = pv.prescription_id
JOIN app.medication m ON pv.medication_id = m.medication_id
JOIN app.medication_side_effect mse ON m.medication_id = mse.medication_id
JOIN app.side_effect se ON mse.side_effect_id = se.side_effect_id
JOIN app.condition c ON se.condition_id = c.condition_id
JOIN app.patient p ON pr.patient_id = p.patient_id
JOIN app.user_account u ON p.user_id = u.user_id
WHERE pr.status = 'Active'
  AND pv.end_date IS NULL
  AND m.medication_id IN (
      SELECT DISTINCT ON (med_name) medication_id
      FROM app.medication
      ORDER BY med_name, medication_id
  )
ORDER BY pr.patient_id, m.med_name, 
    CASE mse.frequency
        WHEN 'Common' THEN 1
        WHEN 'Uncommon' THEN 2
        ELSE 3
    END
LIMIT 20;

-- ============================================================================
-- QUERY 6: SIDE EFFECTS VS SYMPTOMS COMPARISON
-- ============================================================================

\echo ''
\echo 'QUERY 6: Conditions Used as Both Symptoms AND Side Effects'
\echo '----------------------------------------'

SELECT DISTINCT
    c.condition_id,
    c.condition_name,
    EXISTS(SELECT 1 FROM app.symptom s WHERE s.condition_id = c.condition_id) AS is_symptom,
    EXISTS(SELECT 1 FROM app.side_effect se WHERE se.condition_id = c.condition_id) AS is_side_effect,
    CASE 
        WHEN EXISTS(SELECT 1 FROM app.symptom s WHERE s.condition_id = c.condition_id)
         AND EXISTS(SELECT 1 FROM app.side_effect se WHERE se.condition_id = c.condition_id)
        THEN 'Both Symptom & Side Effect'
        WHEN EXISTS(SELECT 1 FROM app.symptom s WHERE s.condition_id = c.condition_id)
        THEN 'Symptom Only'
        WHEN EXISTS(SELECT 1 FROM app.side_effect se WHERE se.condition_id = c.condition_id)
        THEN 'Side Effect Only'
        ELSE 'Neither'
    END AS usage_type
FROM app.condition c
ORDER BY c.condition_name;

-- ============================================================================
-- SUMMARY STATISTICS (WITH DUPLICATE DETECTION)
-- ============================================================================

\echo ''
\echo '============================================'
\echo 'SIDE EFFECTS SUMMARY'
\echo '============================================'

DO $$
DECLARE
    v_total_conditions INT;
    v_total_side_effects INT;
    v_unique_side_effects INT;
    v_total_medications INT;
    v_unique_medications INT;
    v_total_links INT;
    v_avg_side_effects_per_med NUMERIC;
    v_duplicate_meds INT;
    v_duplicate_side_effects INT;
BEGIN
    SELECT COUNT(*) INTO v_total_conditions FROM app.condition;
    SELECT COUNT(*) INTO v_total_side_effects FROM app.side_effect;
    SELECT COUNT(DISTINCT condition_id) INTO v_unique_side_effects FROM app.side_effect;
    SELECT COUNT(*) INTO v_total_medications FROM app.medication;
    SELECT COUNT(DISTINCT med_name) INTO v_unique_medications FROM app.medication;
    SELECT COUNT(*) INTO v_total_links FROM app.medication_side_effect;
    
    v_duplicate_meds := v_total_medications - v_unique_medications;
    v_duplicate_side_effects := v_total_side_effects - v_unique_side_effects;
    
    v_avg_side_effects_per_med := ROUND(
        (SELECT COUNT(*) FROM app.medication_side_effect)::NUMERIC / 
        NULLIF(v_unique_medications, 0), 
        2
    );
    
    RAISE NOTICE 'Total Conditions: %', v_total_conditions;
    RAISE NOTICE '';
    
    RAISE NOTICE 'Medications:';
    IF v_duplicate_meds > 0 THEN
        RAISE NOTICE '   Total: % (% duplicates detected)', v_total_medications, v_duplicate_meds;
        RAISE NOTICE '  Unique: %', v_unique_medications;
    ELSE
        RAISE NOTICE '  Total: % (no duplicates)', v_total_medications;
    END IF;
    RAISE NOTICE '';
    
    RAISE NOTICE 'Side Effects:';
    IF v_duplicate_side_effects > 0 THEN
        RAISE NOTICE '   Total Records: % (% duplicates detected)', v_total_side_effects, v_duplicate_side_effects;
        RAISE NOTICE '  Unique: %', v_unique_side_effects;
    ELSE
        RAISE NOTICE '  Total: % (no duplicates)', v_total_side_effects;
    END IF;
    RAISE NOTICE '';
    
    RAISE NOTICE 'Medication-SideEffect Links: %', v_total_links;
    RAISE NOTICE 'Avg Side Effects per Medication: %', v_avg_side_effects_per_med;
    
    IF v_duplicate_meds > 0 OR v_duplicate_side_effects > 0 THEN
        RAISE NOTICE '';
        RAISE NOTICE 'To fix duplicates, run: npm run schema:rebuild && npm run seeds:run';
    END IF;
    
    RAISE NOTICE '========================================';
END $$;

\echo ''
\echo 'Side Effects Query Completed Successfully!'