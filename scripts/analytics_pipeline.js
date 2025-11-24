// Data Science Enhancement: Statistical Analysis Pipeline
// Author: Cherylynn Cassidy
// Complements Jonathan's generate_synthetic_data.js and patient_suggestion_service.js

const { Client } = require('pg');

const client = new Client({
  host: process.env.PGHOST || 'localhost',
  port: process.env.PGPORT || 5432,
  database: process.env.PGDATABASE || 'jon_database_dev',
  user: process.env.PGUSER || 'jondb_admin',
  password: process.env.PGPASSWORD || 'JonathanBangerDatabase26!'
});

async function runAnalyticsPipeline() {
  try {
    await client.connect();
    console.log('========================================');
    console.log('Data Science Analytics Pipeline');
    console.log('========================================\n');

    // 1. Patient Risk Distribution
    console.log('📊 Patient Risk Distribution:');
    const riskDist = await client.query(`
      SELECT ds_risk_category, COUNT(*) as count, 
             ROUND(AVG(ds_risk_score), 2) as avg_risk
      FROM analytics.v_patient_risk_assessment
      GROUP BY ds_risk_category
      ORDER BY avg_risk DESC
    `);
    console.table(riskDist.rows);

    // 2. Adherence Trends
    console.log('\n📈 Medication Adherence Trends (Last 5 Weeks):');
    const adherence = await client.query(`
      SELECT TO_CHAR(week, 'YYYY-MM-DD') as week, 
             adherence_rate,
             total_doses,
             doses_taken,
             doses_missed
      FROM analytics.v_adherence_trends
      ORDER BY week DESC
      LIMIT 5
    `);
    console.table(adherence.rows);

    // 3. Model Comparison (DS vs AI)
    console.log('\n🤖 Risk Model Comparison (DS vs AI):');
    const comparison = await client.query(`
      SELECT model_alignment, COUNT(*) as patient_count,
             ROUND(AVG(risk_difference), 2) as avg_difference
      FROM analytics.v_risk_model_comparison
      GROUP BY model_alignment
      ORDER BY patient_count DESC
    `);
    console.table(comparison.rows);

    // 4. High-Risk Patients Needing Attention
    console.log('\n⚠️  High-Risk Patients (Top 10):');
    const highRisk = await client.query(`
      SELECT patient_name, 
             ds_risk_score as risk_score, 
             ds_risk_category as risk_category,
             active_symptoms, 
             active_prescriptions,
             adherence_percentage
      FROM analytics.v_patient_risk_assessment
      WHERE ds_risk_category IN ('CRITICAL RISK', 'HIGH RISK')
      ORDER BY ds_risk_score DESC
      LIMIT 10
    `);
    console.table(highRisk.rows);

    // 5. Medication Effectiveness (Top 5)
    console.log('\n💊 Top 5 Most Effective Medications:');
    const effectiveness = await client.query(`
      SELECT med_name, 
             condition_name,
             total_prescriptions,
             ROUND(avg_adherence_rate, 2) as adherence_rate,
             symptoms_resolved,
             ROUND(effectiveness_score, 2) as effectiveness
      FROM analytics.v_medication_effectiveness
      ORDER BY effectiveness_score DESC
      LIMIT 5
    `);
    console.table(effectiveness.rows);

    // 6. Comorbidity Analysis
    console.log('\n🔬 Top Disease Comorbidities:');
    const comorbidity = await client.query(`
      SELECT condition_1,
             condition_2,
             co_occurrence_count,
             prevalence_percentage
      FROM analytics.v_condition_correlations
      ORDER BY co_occurrence_count DESC
      LIMIT 5
    `);
    console.table(comorbidity.rows);

    // 7. Dashboard Metrics
    console.log('\n📊 Dashboard KPIs:');
    const dashboard = await client.query(`
      SELECT metric_group,
             metrics,
             TO_CHAR(last_updated, 'YYYY-MM-DD HH24:MI:SS') as last_updated
      FROM analytics.mv_dashboard_kpis
    `);
    
    dashboard.rows.forEach(row => {
      console.log(`\n${row.metric_group.toUpperCase()}:`);
      console.log(JSON.stringify(row.metrics, null, 2));
    });

    // 8. Summary Statistics
    console.log('\n\n========================================');
    console.log('Analytics Summary');
    console.log('========================================');
    
    const summary = await client.query(`
      SELECT 
        (SELECT COUNT(*) FROM analytics.v_patient_risk_assessment) as total_patients,
        (SELECT COUNT(*) FROM analytics.v_patient_risk_assessment 
         WHERE ds_risk_category IN ('CRITICAL RISK', 'HIGH RISK')) as high_risk_patients,
        (SELECT ROUND(AVG(adherence_percentage), 2) 
         FROM analytics.v_patient_risk_assessment) as avg_adherence,
        (SELECT COUNT(*) FROM analytics.v_medication_effectiveness) as tracked_medications,
        (SELECT COUNT(*) FROM analytics.v_condition_correlations) as comorbidity_patterns
    `);
    
    const stats = summary.rows[0];
    console.log(`Total Patients Analyzed: ${stats.total_patients}`);
    console.log(`High-Risk Patients: ${stats.high_risk_patients} (${Math.round(stats.high_risk_patients / stats.total_patients * 100)}%)`);
    console.log(`Average Adherence Rate: ${stats.avg_adherence}%`);
    console.log(`Medications Tracked: ${stats.tracked_medications}`);
    console.log(`Comorbidity Patterns: ${stats.comorbidity_patterns}`);

    console.log('\n========================================');
    console.log('✅ Analytics Pipeline Completed');
    console.log('========================================');

  } catch (error) {
    console.error('\n❌ Error running analytics:');
    console.error(error.message);
    console.error('\nStack trace:');
    console.error(error.stack);
    process.exit(1);
  } finally {
    await client.end();
  }
}

// Run the pipeline
runAnalyticsPipeline();