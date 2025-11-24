-- Data Science Enhancement: Dashboard KPIs
-- Author: Cherylynn Cassidy

SET search_path TO app, public;

BEGIN;

-- ============================================================================
-- REAL-TIME DASHBOARD METRICS (Materialized View)
-- ============================================================================

CREATE MATERIALIZED VIEW IF NOT EXISTS analytics.mv_dashboard_kpis AS
SELECT 
  'patient_metrics' AS metric_group,
  json_build_object(
    'total_patients', (SELECT COUNT(*) FROM app.patient),
    'high_risk_patients', (
      SELECT COUNT(*) 
      FROM analytics.v_patient_risk_assessment 
      WHERE ds_risk_category IN ('CRITICAL RISK', 'HIGH RISK')
    ),
    'avg_age', (
      SELECT ROUND(AVG(EXTRACT(YEAR FROM AGE(birth_date))), 1) 
      FROM app.patient
    ),
    'active_prescriptions', (
      SELECT COUNT(*) 
      FROM app.prescription 
      WHERE status = 'Active'
    )
  ) AS metrics,
  CURRENT_TIMESTAMP AS last_updated
UNION ALL
SELECT 
  'adherence_metrics' AS metric_group,
  json_build_object(
    'overall_adherence', (
      SELECT ROUND(AVG(adherence_percentage), 2) 
      FROM analytics.v_patient_risk_assessment
    ),
    'doses_taken_today', (
      SELECT COUNT(*) 
      FROM app.medication_log 
      WHERE scheduled_time::DATE = CURRENT_DATE 
        AND status = 'Taken'
    ),
    'doses_missed_today', (
      SELECT COUNT(*) 
      FROM app.medication_log 
      WHERE scheduled_time::DATE = CURRENT_DATE 
        AND status = 'Missed'
    )
  ) AS metrics,
  CURRENT_TIMESTAMP AS last_updated;

-- Refresh function
CREATE OR REPLACE FUNCTION analytics.refresh_dashboard_views()
RETURNS void AS $$
BEGIN
  REFRESH MATERIALIZED VIEW analytics.mv_dashboard_kpis;
  RAISE NOTICE 'Dashboard metrics refreshed at %', CURRENT_TIMESTAMP;
END;
$$ LANGUAGE plpgsql;

COMMENT ON MATERIALIZED VIEW analytics.mv_dashboard_kpis IS 
'Data Science Enhancement: Pre-computed metrics for instant dashboard loading';

COMMIT;

-- Initial refresh
SELECT analytics.refresh_dashboard_views();

-- Verification
DO $$
BEGIN
    RAISE NOTICE '✅ Dashboard metrics view created and refreshed';
END $$;