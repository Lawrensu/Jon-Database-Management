-- Data Science Enhancement: Patient Risk Assessment
-- Author: Cherylynn Cassidy
-- Purpose: Statistical risk scoring for patient prioritization

SET search_path TO app, public;

BEGIN;

-- Create analytics schema
CREATE SCHEMA IF NOT EXISTS analytics;

-- ============================================================================
-- PATIENT RISK ASSESSMENT VIEW
-- ============================================================================

CREATE OR REPLACE VIEW analytics.v_patient_risk_assessment AS
WITH patient_metrics AS (
  SELECT 
    p.patient_id,
    ua.first_name || ' ' || ua.last_name AS patient_name,
    EXTRACT(YEAR FROM AGE(p.birth_date)) AS age,
    p.gender,
    
    -- Active health conditions
    COUNT(DISTINCT ps.symptom_id) AS active_symptoms,
    MAX(CASE ps.severity 
      WHEN 'Severe' THEN 3
      WHEN 'Moderate' THEN 2
      ELSE 1
    END) AS max_severity,
    
    -- Medication complexity
    COUNT(DISTINCT pr.prescription_id) AS active_prescriptions,
    COUNT(DISTINCT pv.medication_id) AS unique_medications,
    
    -- Adherence rate (last 30 days)
    ROUND(
      COUNT(CASE WHEN ml.status = 'Taken' THEN 1 END)::NUMERIC / 
      NULLIF(COUNT(ml.medication_log_id), 0) * 100, 
      2
    ) AS adherence_rate,
    
    -- Time since last prescription
    EXTRACT(DAY FROM (CURRENT_TIMESTAMP - MAX(pr.created_date))) AS days_since_last_visit
    
  FROM app.patient p
  JOIN app.user_account ua ON p.user_id = ua.user_id
  LEFT JOIN app.patient_symptom ps ON p.patient_id = ps.patient_id
    AND ps.date_resolved IS NULL
  LEFT JOIN app.prescription pr ON p.patient_id = pr.patient_id
    AND pr.status = 'Active'
  LEFT JOIN app.prescription_version pv ON pr.prescription_id = pv.prescription_id
  LEFT JOIN app.medication_schedule ms ON pv.prescription_version_id = ms.prescription_version_id
  LEFT JOIN app.medication_log ml ON ms.medication_schedule_id = ml.medication_schedule_id
    AND ml.scheduled_time >= CURRENT_DATE - INTERVAL '30 days'
  GROUP BY p.patient_id, ua.first_name, ua.last_name, p.birth_date, p.gender
),
risk_calculation AS (
  SELECT 
    *,
    -- COMPOSITE RISK SCORE (0-100)
    LEAST(100, (
      -- Age factor (25 points)
      CASE 
        WHEN age >= 80 THEN 25
        WHEN age >= 65 THEN 18
        WHEN age >= 50 THEN 10
        ELSE 3
      END +
      
      -- Symptom severity (20 points)
      (max_severity * 7) +
      
      -- Symptom count (15 points)
      LEAST(15, active_symptoms * 3) +
      
      -- Medication complexity (20 points)
      LEAST(20, active_prescriptions * 4 + unique_medications * 2) +
      
      -- Non-adherence penalty (15 points)
      (100 - COALESCE(adherence_rate, 100)) * 0.15 +
      
      -- Time since visit (5 points)
      LEAST(5, COALESCE(days_since_last_visit, 0) / 30)
      
    ))::INTEGER AS ds_risk_score
  FROM patient_metrics
)
SELECT 
  patient_id,
  patient_name,
  age,
  gender,
  active_symptoms,
  active_prescriptions,
  unique_medications,
  COALESCE(adherence_rate, 100) AS adherence_percentage,
  COALESCE(days_since_last_visit, 0) AS days_since_visit,
  ds_risk_score,
  
  -- Risk classification
  CASE 
    WHEN ds_risk_score >= 75 THEN 'CRITICAL RISK'
    WHEN ds_risk_score >= 60 THEN 'HIGH RISK'
    WHEN ds_risk_score >= 40 THEN 'MEDIUM RISK'
    WHEN ds_risk_score >= 25 THEN 'LOW RISK'
    ELSE 'MINIMAL RISK'
  END AS ds_risk_category,
  
  -- Risk factors breakdown
  json_build_object(
    'age_score', CASE WHEN age >= 80 THEN 25 WHEN age >= 65 THEN 18 WHEN age >= 50 THEN 10 ELSE 3 END,
    'symptom_score', max_severity * 7,
    'medication_score', LEAST(20, active_prescriptions * 4 + unique_medications * 2),
    'adherence_score', (100 - COALESCE(adherence_rate, 100)) * 0.15
  ) AS risk_breakdown,
  
  CURRENT_TIMESTAMP AS calculated_at
FROM risk_calculation
ORDER BY ds_risk_score DESC;

COMMENT ON VIEW analytics.v_patient_risk_assessment IS 
'Data Science Enhancement: Multi-factor risk assessment with statistical weights';

-- ============================================================================
-- MODEL COMPARISON (Data Science vs AI Heuristic)
-- Note: Only creates if Jonathan's AI enhancement (health_risk_score) exists
-- ============================================================================

DO $$ 
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_schema = 'app' 
    AND table_name = 'patient' 
    AND column_name = 'health_risk_score'
  ) THEN
    EXECUTE '
      CREATE OR REPLACE VIEW analytics.v_risk_model_comparison AS
      SELECT 
        ds.patient_id,
        ds.patient_name,
        ds.ds_risk_score,
        ds.ds_risk_category,
        COALESCE(p.health_risk_score * 100, 0)::INTEGER AS ai_risk_score,
        CASE 
          WHEN p.health_risk_score >= 0.75 THEN ''HIGH RISK''
          WHEN p.health_risk_score >= 0.50 THEN ''MEDIUM RISK''
          ELSE ''LOW RISK''
        END AS ai_risk_category,
        ABS(ds.ds_risk_score - COALESCE(p.health_risk_score * 100, 0))::INTEGER AS risk_difference,
        CASE 
          WHEN ABS(ds.ds_risk_score - COALESCE(p.health_risk_score * 100, 0)) <= 10 THEN ''Models Agree''
          WHEN ds.ds_risk_score > COALESCE(p.health_risk_score * 100, 0) THEN ''DS More Conservative''
          ELSE ''AI More Conservative''
        END AS model_alignment
      FROM analytics.v_patient_risk_assessment ds
      LEFT JOIN app.patient p ON ds.patient_id = p.patient_id
      ORDER BY risk_difference DESC;
      
      COMMENT ON VIEW analytics.v_risk_model_comparison IS 
      ''Data Science Enhancement: Compare statistical model vs AI heuristic risk scores'';
    ';
    RAISE NOTICE '✅ v_risk_model_comparison created (AI enhancement detected)';
  ELSE
    RAISE NOTICE 'ℹ️  Skipping v_risk_model_comparison (AI enhancement not installed yet)';
  END IF;
END $$;

COMMIT;

-- ============================================================================
-- VERIFICATION
-- ============================================================================

DO $$
DECLARE
    view_count INT;
    high_risk_count INT;
BEGIN
    SELECT COUNT(*) INTO view_count 
    FROM information_schema.views 
    WHERE table_schema = 'analytics';
    
    SELECT COUNT(*) INTO high_risk_count
    FROM analytics.v_patient_risk_assessment
    WHERE ds_risk_category IN ('CRITICAL RISK', 'HIGH RISK');
    
    RAISE NOTICE '========================================';
    RAISE NOTICE 'Data Science Analytics Installed';
    RAISE NOTICE '========================================';
    RAISE NOTICE 'Analytics views: %', view_count;
    RAISE NOTICE 'High-risk patients: %', high_risk_count;
    RAISE NOTICE '========================================';
END $$;