-- Data Science Enhancement: Disease Correlation Analysis
-- Author: Cherylynn Cassidy

SET search_path TO app, public;

BEGIN;

-- ============================================================================
-- CONDITION CO-OCCURRENCE ANALYSIS
-- ============================================================================

CREATE OR REPLACE VIEW analytics.v_condition_correlations AS
WITH patient_conditions AS (
  SELECT DISTINCT
    ps1.patient_id,
    c1.condition_name AS condition_1,
    c2.condition_name AS condition_2
  FROM app.patient_symptom ps1
  JOIN app.symptom s1 ON ps1.symptom_id = s1.symptom_id
  JOIN app.condition c1 ON s1.condition_id = c1.condition_id
  JOIN app.patient_symptom ps2 ON ps1.patient_id = ps2.patient_id
  JOIN app.symptom s2 ON ps2.symptom_id = s2.symptom_id
  JOIN app.condition c2 ON s2.condition_id = c2.condition_id
  WHERE c1.condition_id < c2.condition_id  -- Avoid duplicates
    AND ps1.date_resolved IS NULL
    AND ps2.date_resolved IS NULL
)
SELECT 
  condition_1,
  condition_2,
  COUNT(*) AS co_occurrence_count,
  ROUND(
    COUNT(*)::NUMERIC / (SELECT COUNT(DISTINCT patient_id) FROM app.patient) * 100,
    2
  ) AS prevalence_percentage
FROM patient_conditions
GROUP BY condition_1, condition_2
HAVING COUNT(*) >= 3  -- Statistical significance threshold
ORDER BY co_occurrence_count DESC;

COMMENT ON VIEW analytics.v_condition_correlations IS 
'Data Science Enhancement: Identify frequently co-occurring medical conditions';

COMMIT;

-- Verification
DO $$
BEGIN
    RAISE NOTICE '✅ Comorbidity analysis view created successfully';
END $$;