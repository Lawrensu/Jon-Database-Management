-- database/analytics/08_analytics_report.sql
-- Comprehensive analytics dashboard report
-- Run this to see all DS analytics + AI/DS integration

BEGIN;

\echo '========================================'
\echo 'Data Science Analytics Pipeline'
\echo '========================================'
\echo ''

-- 1. Patient Risk Distribution
\echo '📊 Patient Risk Distribution:'
SELECT 
    ds_risk_category,
    COUNT(*) as count,
    ROUND(AVG(ds_risk_score), 2) as avg_risk
FROM analytics.v_patient_risk_assessment
GROUP BY ds_risk_category
ORDER BY 
    CASE ds_risk_category
        WHEN 'CRITICAL RISK' THEN 1
        WHEN 'HIGH RISK' THEN 2
        WHEN 'MEDIUM RISK' THEN 3
        WHEN 'LOW RISK' THEN 4
        WHEN 'MINIMAL RISK' THEN 5
    END;

\echo ''
\echo '📈 Medication Adherence Trends (Last 5 Weeks):'
SELECT 
    week,
    ROUND(adherence_rate, 2) as adherence_rate,
    total_doses,
    doses_taken,
    doses_missed
FROM analytics.v_adherence_trends
ORDER BY week DESC
LIMIT 5;

\echo ''
\echo '🤖 Risk Model Comparison (DS vs AI):'
SELECT 
    model_alignment,
    COUNT(*) as patient_count,
    ROUND(AVG(risk_difference), 2) as avg_difference
FROM analytics.v_risk_model_comparison
GROUP BY model_alignment
ORDER BY patient_count DESC;

\echo ''
\echo '⚠️  High-Risk Patients (Top 10):'
SELECT 
    patient_name,
    ds_risk_score as risk_score,
    ds_risk_category as risk_category,
    active_symptoms,
    active_prescriptions,
    ROUND(adherence_percentage, 2) as adherence_pct
FROM analytics.v_patient_risk_assessment
WHERE ds_risk_category IN ('CRITICAL RISK', 'HIGH RISK')
ORDER BY ds_risk_score DESC
LIMIT 10;

\echo ''
\echo '💊 Top 5 Most Effective Medications:'
SELECT 
    med_name,
    condition_name,
    total_prescriptions,
    ROUND(avg_adherence_rate, 2) as avg_adherence,
    ROUND(effectiveness_score, 2) as effectiveness
FROM analytics.v_medication_effectiveness
ORDER BY effectiveness_score DESC
LIMIT 5;

\echo ''
\echo '🔬 Top Disease Comorbidities:'
SELECT 
    condition_1,
    condition_2,
    co_occurrence_count,
    ROUND(prevalence_percentage, 2) as prevalence_pct
FROM analytics.v_condition_correlations
ORDER BY co_occurrence_count DESC
LIMIT 5;

\echo ''
\echo '📊 Dashboard KPIs:'
SELECT 
    metric_group,
    metrics::text as metrics,
    last_updated
FROM analytics.mv_dashboard_kpis
ORDER BY metric_group;

\echo ''
\echo '========================================'
\echo 'Analytics Summary'
\echo '========================================'
SELECT 
    COUNT(*) as total_patients,
    SUM(CASE WHEN ds_risk_category IN ('CRITICAL RISK', 'HIGH RISK') THEN 1 ELSE 0 END) as high_risk_patients,
    ROUND(AVG(adherence_percentage), 2) as avg_adherence_rate
FROM analytics.v_patient_risk_assessment;

SELECT 
    COUNT(DISTINCT med_name) as medications_tracked
FROM analytics.v_medication_effectiveness;

SELECT 
    COUNT(*) as comorbidity_patterns
FROM analytics.v_condition_correlations 
WHERE prevalence_percentage >= 5.0;

\echo ''
\echo '✅ Analytics Pipeline Completed'
\echo ''

ROLLBACK;
