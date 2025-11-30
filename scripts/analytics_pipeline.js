require('dotenv').config();
const { Client } = require('pg');

// Database connection configuration
const client = new Client({
  host: process.env.POSTGRES_HOST,
  port: Number(process.env.POSTGRES_PORT),
  user: process.env.POSTGRES_USER,
  password: process.env.POSTGRES_PASSWORD,
  database: process.env.POSTGRES_DB
});

async function runAnalyticsPipeline() {
  try {
    await client.connect();
    console.log('✅ Connected to database\n');

    console.log('========================================');
    console.log('Data Science Analytics Pipeline');
    console.log('========================================\n');

    // 1. Patient Risk Distribution
    console.log('📊 Patient Risk Distribution:');
    const riskDistribution = await client.query(`
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
    `);
    console.table(riskDistribution.rows);

    // 2. Adherence Trends (Last 5 weeks)
    console.log('📈 Medication Adherence Trends (Last 5 Weeks):');
    const adherenceTrends = await client.query(`
      SELECT 
        week,
        ROUND(adherence_rate, 2) as adherence_rate,
        total_doses,
        doses_taken,
        doses_missed
      FROM analytics.v_adherence_trends
      ORDER BY week DESC
      LIMIT 5;
    `);
    console.table(adherenceTrends.rows);

    // 3. Risk Model Comparison (AI vs DS)
    console.log('🤖 Risk Model Comparison (DS vs AI):');
    const modelComparison = await client.query(`
      SELECT 
        model_alignment,
        COUNT(*) as patient_count,
        ROUND(AVG(risk_difference), 2) as avg_difference
      FROM analytics.v_risk_model_comparison
      GROUP BY model_alignment
      ORDER BY patient_count DESC;
    `);
    
    if (modelComparison.rows.length > 0) {
      console.table(modelComparison.rows);
    } else {
      console.log('⚠️  Risk model comparison view exists but has no data.');
      console.log('   This is expected if AI enhancement is not installed yet.\n');
    }

    // 4. High-Risk Patients (Top 10)
    console.log('⚠️  High-Risk Patients (Top 10):');
    const highRiskPatients = await client.query(`
      SELECT 
        patient_name,
        ds_risk_score as risk_score,
        ds_risk_category as risk_category,
        active_symptoms,
        active_prescriptions,
        ROUND(adherence_percentage, 2) as adherence_percentage
      FROM analytics.v_patient_risk_assessment
      WHERE ds_risk_category IN ('CRITICAL RISK', 'HIGH RISK')
      ORDER BY ds_risk_score DESC
      LIMIT 10;
    `);
    console.table(highRiskPatients.rows);

    // 5. Medication Effectiveness (Top 5)
    console.log('💊 Top 5 Most Effective Medications:');
    const topMedications = await client.query(`
      SELECT 
        med_name,
        condition_name,
        total_prescriptions,
        ROUND(avg_adherence_rate, 2) as avg_adherence_rate,
        ROUND(effectiveness_score, 2) as effectiveness_score
      FROM analytics.v_medication_effectiveness
      ORDER BY effectiveness_score DESC
      LIMIT 5;
    `);
    console.table(topMedications.rows);

    // 6. Top Comorbidities
    console.log('🔬 Top Disease Comorbidities:');
    const comorbidities = await client.query(`
      SELECT 
        condition_1,
        condition_2,
        co_occurrence_count,
        ROUND(prevalence_percentage, 2) as prevalence_percentage
      FROM analytics.v_condition_correlations
      ORDER BY co_occurrence_count DESC
      LIMIT 5;
    `);
    console.table(comorbidities.rows);

    // 7. Dashboard KPIs
    console.log('📊 Dashboard KPIs:');
    const dashboardKPIs = await client.query(`
      SELECT 
        metric_group,
        metrics,
        last_updated
      FROM analytics.mv_dashboard_kpis
      ORDER BY metric_group;
    `);
    console.table(dashboardKPIs.rows);

    // Summary
    console.log('========================================');
    console.log('Analytics Summary');
    console.log('========================================');
    
    const summary = await client.query(`
      SELECT 
        COUNT(*) as total_patients,
        SUM(CASE WHEN ds_risk_category IN ('CRITICAL RISK', 'HIGH RISK') THEN 1 ELSE 0 END) as high_risk_patients,
        ROUND(AVG(adherence_percentage), 2) as avg_adherence_rate
      FROM analytics.v_patient_risk_assessment;
    `);
    
    const summaryRow = summary.rows[0];
    console.log(`Total Patients Analyzed: ${summaryRow.total_patients}`);
    console.log(`High-Risk Patients: ${summaryRow.high_risk_patients} (${Math.round((summaryRow.high_risk_patients / summaryRow.total_patients) * 100)}%)`);
    console.log(`Average Adherence Rate: ${summaryRow.avg_adherence_rate}%`);

    const medicationCount = await client.query(`SELECT COUNT(DISTINCT med_name) as count FROM analytics.v_medication_effectiveness;`);
    console.log(`Medications Tracked: ${medicationCount.rows[0].count}`);

    const comorbidityCount = await client.query(`SELECT COUNT(*) as count FROM analytics.v_condition_correlations WHERE co_occurrence_count >= 3;`);
    console.log(`Comorbidity Patterns: ${comorbidityCount.rows[0].count}`);

    console.log('\n========================================');
    console.log('✅ Analytics Pipeline Completed');
    console.log('========================================\n');

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