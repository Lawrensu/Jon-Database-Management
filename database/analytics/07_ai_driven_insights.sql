-- database/analytics/07_ai_driven_insights.sql
-- AI-Driven Analytical Processing Views
-- Demonstrates OLAP-style analytics using AI/ML features

-- Create analytics schema if it doesn't exist
CREATE SCHEMA IF NOT EXISTS analytics;

SET search_path TO analytics, app, public;

-- ============================================================================
-- View 1: AI-Enhanced Patient Risk Stratification
-- ============================================================================
-- Purpose: Combines health_risk_score with clinical data for AI-driven triage
-- Use case: Morning dashboard showing which patients need immediate attention

CREATE MATERIALIZED VIEW IF NOT EXISTS analytics.v_ai_patient_risk_stratification AS
SELECT 
    p.patient_id,
    p.health_risk_score,
    EXTRACT(YEAR FROM AGE(p.birth_date)) AS age,
    p.gender,
    
    -- Clinical indicators
    COUNT(DISTINCT ps.symptom_id) AS total_symptoms,
    COUNT(DISTINCT CASE WHEN ps.severity = 'Severe' THEN ps.symptom_id END) AS severe_symptoms,
    COUNT(DISTINCT CASE WHEN ps.date_resolved IS NULL THEN ps.symptom_id END) AS unresolved_symptoms,
    
    -- Medication adherence
    COUNT(ml.medication_log_id) AS total_med_logs,
    COUNT(CASE WHEN ml.status = 'Taken' THEN 1 END) AS taken_count,
    COUNT(CASE WHEN ml.status = 'Missed' THEN 1 END) AS missed_count,
    ROUND(
        COALESCE(
            COUNT(CASE WHEN ml.status = 'Taken' THEN 1 END)::NUMERIC / 
            NULLIF(COUNT(ml.medication_log_id), 0),
            0
        ) * 100, 
        2
    ) AS adherence_percentage,
    
    -- Embedding availability (indicates rich clinical notes)
    (SELECT COUNT(*) FROM app.embedding e WHERE e.source_id = p.patient_id::TEXT) AS embedding_count,
    
    -- AI-driven recommendation
    CASE 
        WHEN p.health_risk_score >= 0.8 THEN 'CRITICAL: Immediate Intervention Required'
        WHEN p.health_risk_score >= 0.6 THEN 'HIGH: Monitor Closely & Schedule Follow-up'
        WHEN p.health_risk_score >= 0.4 THEN 'MODERATE: Routine Follow-up Recommended'
        ELSE 'LOW: Standard Care Protocol'
    END AS ai_recommendation,
    
    -- Priority score for triage (0-100)
    ROUND(
        (p.health_risk_score * 50) + 
        (COUNT(DISTINCT CASE WHEN ps.severity = 'Severe' THEN ps.symptom_id END) * 10) +
        (COUNT(CASE WHEN ml.status = 'Missed' THEN 1 END) * 2),
        2
    ) AS priority_score,
    
    CURRENT_TIMESTAMP AS computed_at

FROM app.patient p
LEFT JOIN app.patient_symptom ps ON p.patient_id = ps.patient_id
LEFT JOIN app.medication_log ml ON p.patient_id = ml.patient_id 
    AND ml.scheduled_time >= CURRENT_TIMESTAMP - INTERVAL '30 days'
GROUP BY p.patient_id, p.health_risk_score, p.birth_date, p.gender;

CREATE INDEX IF NOT EXISTS idx_ai_risk_strat_score ON analytics.v_ai_patient_risk_stratification(health_risk_score DESC);
CREATE INDEX IF NOT EXISTS idx_ai_risk_strat_priority ON analytics.v_ai_patient_risk_stratification(priority_score DESC);

COMMENT ON MATERIALIZED VIEW analytics.v_ai_patient_risk_stratification IS 
'AI-enhanced patient triage combining ML risk scores with clinical indicators. Refresh daily for morning rounds.';

-- ============================================================================
-- View 2: ML Training Feature Set
-- ============================================================================
-- Purpose: Prepares feature vectors for machine learning model training
-- Use case: Export to Python/scikit-learn for risk prediction model

CREATE MATERIALIZED VIEW IF NOT EXISTS analytics.v_ml_training_features AS
SELECT 
    p.patient_id,
    
    -- Demographic features
    EXTRACT(YEAR FROM AGE(p.birth_date)) AS age,
    CASE p.gender 
        WHEN 'Male' THEN 1 
        WHEN 'Female' THEN 0 
        ELSE -1 
    END AS gender_encoded,
    
    -- Symptom features
    COUNT(DISTINCT ps.symptom_id) AS feature_total_symptoms,
    COUNT(DISTINCT CASE WHEN ps.severity = 'Mild' THEN ps.symptom_id END) AS feature_mild_symptoms,
    COUNT(DISTINCT CASE WHEN ps.severity = 'Moderate' THEN ps.symptom_id END) AS feature_moderate_symptoms,
    COUNT(DISTINCT CASE WHEN ps.severity = 'Severe' THEN ps.symptom_id END) AS feature_severe_symptoms,
    COUNT(DISTINCT CASE WHEN ps.date_resolved IS NULL THEN ps.symptom_id END) AS feature_unresolved_symptoms,
    
    -- Medication adherence features
    COUNT(ml.medication_log_id) AS feature_total_med_events,
    COUNT(CASE WHEN ml.status = 'Taken' THEN 1 END) AS feature_taken_count,
    COUNT(CASE WHEN ml.status = 'Missed' THEN 1 END) AS feature_missed_count,
    COUNT(CASE WHEN ml.status = 'Skipped' THEN 1 END) AS feature_skipped_count,
    
    -- Adherence rate (normalized 0-1)
    COALESCE(
        COUNT(CASE WHEN ml.status = 'Taken' THEN 1 END)::NUMERIC / 
        NULLIF(COUNT(ml.medication_log_id), 0),
        0.5
    ) AS feature_adherence_rate,
    
    -- Prescription complexity
    COUNT(DISTINCT pr.prescription_id) AS feature_prescription_count,
    COUNT(DISTINCT pv.medication_id) AS feature_unique_medications,
    
    -- Temporal features (days since last event)
    COALESCE(
        EXTRACT(DAY FROM (CURRENT_TIMESTAMP - MAX(ps.date_reported))),
        365
    ) AS feature_days_since_last_symptom,
    
    COALESCE(
        EXTRACT(DAY FROM (CURRENT_TIMESTAMP - MAX(ml.scheduled_time))),
        30
    ) AS feature_days_since_last_med,
    
    -- Target variable (what we're trying to predict)
    p.health_risk_score AS target_risk_score,
    
    -- Classification target (for classification models)
    CASE 
        WHEN p.health_risk_score >= 0.7 THEN 1  -- High risk
        ELSE 0  -- Normal/Low risk
    END AS target_high_risk_binary,
    
    CURRENT_TIMESTAMP AS feature_extraction_date

FROM app.patient p
LEFT JOIN app.patient_symptom ps ON p.patient_id = ps.patient_id
LEFT JOIN app.medication_log ml ON p.patient_id = ml.patient_id
    AND ml.scheduled_time >= CURRENT_TIMESTAMP - INTERVAL '90 days'
LEFT JOIN app.prescription pr ON p.patient_id = pr.patient_id
    AND pr.status = 'Active'
LEFT JOIN app.prescription_version pv ON pr.prescription_id = pv.prescription_id
    AND pv.end_date IS NULL

GROUP BY p.patient_id, p.birth_date, p.gender, p.health_risk_score;

CREATE INDEX IF NOT EXISTS idx_ml_features_target ON analytics.v_ml_training_features(target_high_risk_binary, target_risk_score);

COMMENT ON MATERIALIZED VIEW analytics.v_ml_training_features IS 
'Feature engineering view for ML model training. Export to CSV for scikit-learn, TensorFlow, or XGBoost training.';

-- ============================================================================
-- View 3: Semantic Search Performance Analysis
-- ============================================================================
-- Purpose: Compare traditional SQL vs vector similarity search performance
-- Use case: Demonstrate AI database performance advantages

CREATE OR REPLACE VIEW analytics.v_semantic_search_readiness AS
SELECT 
    'Embedding Storage' AS metric_name,
    COUNT(*)::TEXT AS metric_value,
    'Total vectors stored' AS description
FROM app.embedding

UNION ALL

SELECT 
    'Unique Patients with Embeddings',
    COUNT(DISTINCT source_id)::TEXT,
    'Patients with clinical note embeddings'
FROM app.embedding
WHERE source_table = 'patient_note'

UNION ALL

SELECT 
    'Average Embedding Dimension',
    '1536',
    'Vector dimensionality (configured)'

UNION ALL

SELECT 
    'Vector Index Status',
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM pg_indexes 
            WHERE schemaname = 'app' 
            AND tablename = 'embedding' 
            AND indexname LIKE '%ivfflat%'
        ) THEN 'ENABLED'
        ELSE 'MISSING'
    END,
    'IVFFlat ANN index for fast similarity search'

UNION ALL

SELECT 
    'Patients Ready for AI Analysis',
    COUNT(*)::TEXT,
    'Patients with risk score > 0'
FROM app.patient
WHERE health_risk_score > 0;

COMMENT ON VIEW analytics.v_semantic_search_readiness IS 
'Health check for AI/ML infrastructure. Verify embeddings and indexes are operational.';

-- ============================================================================
-- View 4: AI Model Performance Metrics
-- ============================================================================
-- Purpose: Track accuracy and performance of risk scoring model
-- Use case: Model monitoring and drift detection

CREATE MATERIALIZED VIEW IF NOT EXISTS analytics.v_ai_model_performance AS
WITH risk_distribution AS (
    SELECT 
        CASE 
            WHEN health_risk_score < 0.4 THEN 'Low Risk (0.0-0.39)'
            WHEN health_risk_score < 0.6 THEN 'Moderate Risk (0.40-0.59)'
            WHEN health_risk_score < 0.8 THEN 'High Risk (0.60-0.79)'
            ELSE 'Critical Risk (0.80-1.00)'
        END AS risk_category,
        COUNT(*) AS patient_count,
        AVG(health_risk_score) AS avg_risk_score,
        MIN(health_risk_score) AS min_risk,
        MAX(health_risk_score) AS max_risk
    FROM app.patient
    WHERE health_risk_score IS NOT NULL
    GROUP BY 
        CASE 
            WHEN health_risk_score < 0.4 THEN 'Low Risk (0.0-0.39)'
            WHEN health_risk_score < 0.6 THEN 'Moderate Risk (0.40-0.59)'
            WHEN health_risk_score < 0.8 THEN 'High Risk (0.60-0.79)'
            ELSE 'Critical Risk (0.80-1.00)'
        END
)
SELECT 
    risk_category,
    patient_count,
    ROUND(avg_risk_score, 3) AS avg_risk_score,
    ROUND(min_risk, 3) AS min_risk,
    ROUND(max_risk, 3) AS max_risk,
    ROUND(
        (patient_count::NUMERIC / SUM(patient_count) OVER ()) * 100, 
        2
    ) AS percentage_of_total,
    CURRENT_TIMESTAMP AS snapshot_date
FROM risk_distribution
ORDER BY avg_risk_score DESC;

COMMENT ON MATERIALIZED VIEW analytics.v_ai_model_performance IS 
'Track distribution of AI risk predictions. Monitor for model drift over time.';

-- ============================================================================
-- Summary Query: AI Database Readiness Report
-- ============================================================================

DO $$
DECLARE
    total_patients INT;
    patients_with_risk INT;
    total_embeddings INT;
    total_features INT;
BEGIN
    SELECT COUNT(*) INTO total_patients FROM app.patient;
    SELECT COUNT(*) INTO patients_with_risk FROM app.patient WHERE health_risk_score > 0;
    SELECT COUNT(*) INTO total_embeddings FROM app.embedding;
    SELECT COUNT(*) INTO total_features FROM analytics.v_ml_training_features;
    
    RAISE NOTICE '========================================';
    RAISE NOTICE 'AI Database Analytics Installation';
    RAISE NOTICE '========================================';
    RAISE NOTICE 'Materialized Views Created:';
    RAISE NOTICE '  ✓ v_ai_patient_risk_stratification';
    RAISE NOTICE '  ✓ v_ml_training_features';
    RAISE NOTICE '  ✓ v_ai_model_performance';
    RAISE NOTICE '';
    RAISE NOTICE 'Regular Views Created:';
    RAISE NOTICE '  ✓ v_semantic_search_readiness';
    RAISE NOTICE '';
    RAISE NOTICE 'Database Status:';
    RAISE NOTICE '  Total Patients: %', total_patients;
    RAISE NOTICE '  Patients with Risk Scores: %', patients_with_risk;
    RAISE NOTICE '  Vector Embeddings: %', total_embeddings;
    RAISE NOTICE '  ML Feature Rows: %', total_features;
    RAISE NOTICE '========================================';
    RAISE NOTICE 'Next Steps:';
    RAISE NOTICE '  1. Query: SELECT * FROM analytics.v_ai_patient_risk_stratification ORDER BY priority_score DESC LIMIT 10;';
    RAISE NOTICE '  2. Export: \copy analytics.v_ml_training_features TO ''ml_features.csv'' CSV HEADER';
    RAISE NOTICE '  3. Refresh: REFRESH MATERIALIZED VIEW analytics.v_ai_patient_risk_stratification;';
    RAISE NOTICE '========================================';
END $$;
