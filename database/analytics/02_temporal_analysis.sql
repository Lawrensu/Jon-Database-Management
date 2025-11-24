-- Data Science Enhancement: Time-Series Analysis
-- Author: Cherylynn Cassidy

SET search_path TO app, public;

BEGIN;

-- ============================================================================
-- MEDICATION ADHERENCE TRENDS (Weekly)
-- ============================================================================

CREATE OR REPLACE VIEW analytics.v_adherence_trends AS
SELECT 
  DATE_TRUNC('week', ml.scheduled_time) AS week,
  COUNT(*) AS total_doses,
  COUNT(CASE WHEN ml.status = 'Taken' THEN 1 END) AS doses_taken,
  COUNT(CASE WHEN ml.status = 'Missed' THEN 1 END) AS doses_missed,
  ROUND(
    COUNT(CASE WHEN ml.status = 'Taken' THEN 1 END)::NUMERIC / 
    NULLIF(COUNT(*), 0) * 100, 
    2
  ) AS adherence_rate
FROM app.medication_log ml
WHERE ml.scheduled_time >= CURRENT_DATE - INTERVAL '90 days'
GROUP BY DATE_TRUNC('week', ml.scheduled_time)
ORDER BY week DESC;

COMMENT ON VIEW analytics.v_adherence_trends IS 
'Data Science Enhancement: Weekly adherence patterns for time-series analysis';

-- ============================================================================
-- SYMPTOM PROGRESSION TRACKING
-- ============================================================================

CREATE OR REPLACE VIEW analytics.v_symptom_progression AS
SELECT 
  p.patient_id,
  ua.first_name || ' ' || ua.last_name AS patient_name,
  c.condition_name,
  c.condition_name AS symptom_name,  -- Using condition name as symptom identifier
  ps.severity,
  ps.date_reported,
  ps.date_resolved,
  COALESCE(
    EXTRACT(DAY FROM (ps.date_resolved - ps.date_reported)),
    EXTRACT(DAY FROM (CURRENT_TIMESTAMP - ps.date_reported))
  ) AS duration_days,
  
  -- Recovery classification
  CASE 
    WHEN ps.date_resolved IS NULL THEN 'Ongoing'
    WHEN EXTRACT(DAY FROM (ps.date_resolved - ps.date_reported)) <= 7 THEN 'Fast Recovery'
    WHEN EXTRACT(DAY FROM (ps.date_resolved - ps.date_reported)) <= 30 THEN 'Normal Recovery'
    ELSE 'Slow Recovery'
  END AS recovery_classification,
  
  -- Severity trend
  LAG(ps.severity) OVER (
    PARTITION BY p.patient_id, c.condition_id 
    ORDER BY ps.date_reported
  ) AS previous_severity,
  
  CASE 
    WHEN LAG(ps.severity) OVER (PARTITION BY p.patient_id, c.condition_id ORDER BY ps.date_reported) = 'Mild' 
         AND ps.severity IN ('Moderate', 'Severe') THEN 'Worsening'
    WHEN LAG(ps.severity) OVER (PARTITION BY p.patient_id, c.condition_id ORDER BY ps.date_reported) = 'Severe' 
         AND ps.severity IN ('Mild', 'Moderate') THEN 'Improving'
    ELSE 'Stable'
  END AS severity_trend
  
FROM app.patient_symptom ps
JOIN app.patient p ON ps.patient_id = p.patient_id
JOIN app.user_account ua ON p.user_id = ua.user_id
JOIN app.symptom s ON ps.symptom_id = s.symptom_id
JOIN app.condition c ON s.condition_id = c.condition_id
ORDER BY p.patient_id, ps.date_reported DESC;

COMMENT ON VIEW analytics.v_symptom_progression IS 
'Data Science Enhancement: Track symptom duration and recovery patterns';

COMMIT;

-- Verification
DO $$
BEGIN
    RAISE NOTICE '✅ Temporal analysis views created successfully';
END $$;