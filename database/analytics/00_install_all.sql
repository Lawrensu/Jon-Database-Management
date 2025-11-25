-- database/analytics/00_install_all.sql
-- Install all analytics views in correct order
-- This replaces the Node.js install-analytics.js script

BEGIN;

\echo '=========================================='
\echo 'Installing Data Science Analytics Views'
\echo '=========================================='
\echo ''

-- 1. Patient Risk Analytics
\echo '📊 Installing 01_patient_risk_analytics.sql...'
\ir 01_patient_risk_analytics.sql
\echo ''

-- 2. Temporal Analysis
\echo '📊 Installing 02_temporal_analysis.sql...'
\ir 02_temporal_analysis.sql
\echo ''

-- 3. Medication Effectiveness
\echo '📊 Installing 03_medication_effectiveness.sql...'
\ir 03_medication_effectiveness.sql
\echo ''

-- 4. Comorbidity Analysis
\echo '📊 Installing 04_comorbidity_analysis.sql...'
\ir 04_comorbidity_analysis.sql
\echo ''

-- 5. Dashboard Metrics
\echo '📊 Installing 05_dashboard_metrics.sql...'
\ir 05_dashboard_metrics.sql
\echo ''

-- 6. ML Feature Engineering
\echo '📊 Installing 06_ml_feature_engineering.sql...'
\ir 06_ml_feature_engineering.sql
\echo ''

-- 7. AI-Driven Insights
\echo '📊 Installing 07_ai_driven_insights.sql...'
\ir 07_ai_driven_insights.sql
\echo ''

-- Verify installation
\echo '📊 Verifying installation...'
SELECT 
    schemaname, 
    viewname 
FROM pg_views 
WHERE schemaname = 'analytics' 
ORDER BY viewname;

\echo ''
\echo '=========================================='
\echo '✅ All Analytics Views Installed'
\echo '=========================================='
\echo ''

COMMIT;
