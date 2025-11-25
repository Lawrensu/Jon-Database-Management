require('dotenv').config();
const { Client } = require('pg');
const fs = require('fs');
const path = require('path');

// Database connection configuration
const client = new Client({
  host: process.env.POSTGRES_HOST || 'localhost',
  port: process.env.POSTGRES_PORT || 5432,
  database: process.env.POSTGRES_DB || 'jon_database_dev',
  user: process.env.POSTGRES_USER || 'jondb_admin',
  password: process.env.POSTGRES_PASSWORD || 'JonathanBangerDatabase26!',
});

async function installAnalytics() {
  try {
    await client.connect();
    console.log('✅ Connected to database\n');

    console.log('========================================');
    console.log('Installing Data Science Analytics Views');
    console.log('========================================\n');

    const analyticsDir = path.join(__dirname, '..', 'database', 'analytics');
    const files = [
      '01_patient_risk_analytics.sql',
      '02_temporal_analysis.sql',
      '03_medication_effectiveness.sql',
      '04_comorbidity_analysis.sql',
      '05_dashboard_metrics.sql',
      '06_ml_feature_engineering.sql'
    ];

    for (const file of files) {
      const filePath = path.join(analyticsDir, file);
      console.log(`📊 Installing ${file}...`);
      
      const sql = fs.readFileSync(filePath, 'utf8');
      await client.query(sql);
      
      console.log(`✅ Installed successfully\n`);
    }

    console.log('========================================');
    console.log('✅ All Analytics Views Installed');
    console.log('========================================\n');

  } catch (error) {
    console.error('\n❌ Error installing analytics:');
    console.error(error.message);
    console.error('\nStack trace:');
    console.error(error.stack);
    process.exit(1);
  } finally {
    await client.end();
  }
}

// Run installation
installAnalytics();