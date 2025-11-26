-- Data Science Enhancement: ML Feature Engineering
-- Author: Cherylynn Cassidy
-- Purpose: Create ML-ready features that bridge with AI embeddings

SET search_path TO app, public;

BEGIN;

-- ============================================================================
-- ML-READY PATIENT FEATURES
-- ============================================================================

CREATE OR REPLACE VIEW analytics.v_ml_patient_features AS
SELECT 
  p.patient_id,
  
  -- Demographic features
  EXTRACT(YEAR FROM AGE(p.birth_date)) AS age,
  p.gender,
  
  -- Health metrics
  COUNT(DISTINCT ps.symptom_id) AS symptom_count,
  COUNT(DISTINCT CASE WHEN ps.severity = 'Severe' THEN ps.symptom_id END) AS severe_symptom_count,
  AVG(CASE ps.severity 
    WHEN 'Severe' THEN 3 
    WHEN 'Moderate' THEN 2 
    ELSE 1 
  END) AS avg_severity_score,
  
  -- Medication features
  COUNT(DISTINCT pr.prescription_id) AS prescription_count,
  COUNT(DISTINCT pv.medication_id) AS unique_medication_count,
  
  -- Adherence features
  ROUND(
    COUNT(CASE WHEN ml.status = 'Taken' THEN 1 END)::NUMERIC / 
    NULLIF(COUNT(ml.medication_log_id), 0) * 100,
    2
  ) AS adherence_rate,
  COUNT(CASE WHEN ml.status = 'Missed' THEN 1 END) AS missed_dose_count,
  
  -- Temporal features
  EXTRACT(EPOCH FROM (CURRENT_TIMESTAMP - MAX(pr.created_date))) / 86400 AS days_since_last_prescription,
  EXTRACT(EPOCH FROM (CURRENT_TIMESTAMP - p.created_at)) / 86400 AS days_since_registration,
  
  -- Comorbidity features
  COUNT(DISTINCT c.condition_id) AS unique_condition_count
  
  -- Note: AI bridge (embedding_reference) added separately if Jonathan's AI is installed
  
FROM app.patient p
LEFT JOIN app.patient_symptom ps ON p.patient_id = ps.patient_id
LEFT JOIN app.symptom s ON ps.symptom_id = s.symptom_id
LEFT JOIN app.condition c ON s.condition_id = c.condition_id
LEFT JOIN app.prescription pr ON p.patient_id = pr.patient_id
LEFT JOIN app.prescription_version pv ON pr.prescription_id = pv.prescription_id
LEFT JOIN app.medication_schedule ms ON pv.prescription_version_id = ms.prescription_version_id
LEFT JOIN app.medication_log ml ON ms.medication_schedule_id = ml.medication_schedule_id
  AND ml.scheduled_time >= CURRENT_DATE - INTERVAL '30 days'
GROUP BY p.patient_id, p.birth_date, p.gender, p.created_at;

COMMENT ON VIEW analytics.v_ml_patient_features IS 
'Data Science Enhancement: Engineered features for ML models, compatible with Jonathan''s AI embeddings';

COMMIT;

-- Verification
DO $$
BEGIN
    RAISE NOTICE '✅ ML feature engineering view created successfully';
END $$;