-- Data Science Enhancement: Medication Effectiveness Analysis
-- Author: Cherylynn Cassidy

SET search_path TO app, public;

BEGIN;

-- ============================================================================
-- MEDICATION EFFECTIVENESS SCORING
-- ============================================================================

CREATE OR REPLACE VIEW analytics.v_medication_effectiveness AS
WITH prescription_outcomes AS (
  SELECT 
    m.med_name,
    m.med_brand_name,
    c.condition_name,
    pr.prescription_id,
    pr.status,
    
    -- Adherence rate
    ROUND(
      COUNT(CASE WHEN ml.status = 'Taken' THEN 1 END)::NUMERIC /
      NULLIF(COUNT(ml.medication_log_id), 0) * 100,
      2
    ) AS adherence_rate,
    
    -- Symptom resolution check
    MAX(CASE 
      WHEN ps.date_resolved IS NOT NULL 
           AND ps.date_resolved > pv.start_date 
      THEN 1
      ELSE 0
    END) AS symptom_resolved
    
  FROM app.prescription pr
  JOIN app.prescription_version pv ON pr.prescription_id = pv.prescription_id
  JOIN app.medication m ON pv.medication_id = m.medication_id
  JOIN app.patient_symptom ps ON pr.patient_id = ps.patient_id
  JOIN app.symptom s ON ps.symptom_id = s.symptom_id
  JOIN app.condition c ON s.condition_id = c.condition_id
  LEFT JOIN app.medication_schedule ms ON pv.prescription_version_id = ms.prescription_version_id
  LEFT JOIN app.medication_log ml ON ms.medication_schedule_id = ml.medication_schedule_id
  WHERE pv.start_date <= ps.date_reported
  GROUP BY m.med_name, m.med_brand_name, c.condition_name, pr.prescription_id, pr.status
)
SELECT 
  med_name,
  med_brand_name,
  condition_name,
  COUNT(*) AS total_prescriptions,
  COUNT(CASE WHEN status = 'Completed' THEN 1 END) AS completed_prescriptions,
  ROUND(AVG(adherence_rate), 2) AS avg_adherence_rate,
  COUNT(CASE WHEN symptom_resolved = 1 THEN 1 END) AS symptoms_resolved,
  
  -- Effectiveness score (0-100)
  ROUND((
    -- Completion rate (40%)
    (COUNT(CASE WHEN status = 'Completed' THEN 1 END)::NUMERIC / NULLIF(COUNT(*), 0) * 40) +
    -- Adherence rate (30%)
    (AVG(adherence_rate) * 0.3) +
    -- Resolution rate (30%)
    (COUNT(CASE WHEN symptom_resolved = 1 THEN 1 END)::NUMERIC / NULLIF(COUNT(*), 0) * 30)
  )::NUMERIC, 2) AS effectiveness_score
  
FROM prescription_outcomes
GROUP BY med_name, med_brand_name, condition_name
HAVING COUNT(*) >= 3  -- Require at least 3 prescriptions for statistical significance
ORDER BY effectiveness_score DESC;

COMMENT ON VIEW analytics.v_medication_effectiveness IS 
'Data Science Enhancement: Treatment outcome analysis with effectiveness scoring';

COMMIT;

-- Verification
DO $$
BEGIN
    RAISE NOTICE '✅ Medication effectiveness view created successfully';
END $$;