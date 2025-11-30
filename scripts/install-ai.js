require('dotenv').config();
const { Client } = require('pg');
const fs = require('fs');
const path = require('path');

const client = new Client({
  host: process.env.POSTGRES_HOST,
  port: Number(process.env.POSTGRES_PORT),
  user: process.env.POSTGRES_USER,
  password: process.env.POSTGRES_PASSWORD,
  database: process.env.POSTGRES_DB
});

async function installAI() {
  try {
    await client.connect();
    console.log('✅ Connected to database\n');

    console.log('========================================');
    console.log('Installing AI Enhancement');
    console.log('========================================\n');

    const sqlPath = path.join(__dirname, '..', 'database', 'project', '99_ai_extensions.sql');
    console.log('📊 Installing 99_ai_extensions.sql...');
    
    if (!fs.existsSync(sqlPath)) {
      throw new Error(`SQL file not found: ${sqlPath}`);
    }
    
    const sql = fs.readFileSync(sqlPath, 'utf8');
    await client.query(sql);
    
    console.log('✅ AI enhancement installed successfully\n');

    // Verify installation
    console.log('🔍 Verifying installation...');
    
    const embeddingTable = await client.query(`
      SELECT COUNT(*) as count 
      FROM information_schema.tables 
      WHERE table_schema = 'app' 
        AND table_name = 'embedding';
    `);
    
    const healthRiskColumn = await client.query(`
      SELECT COUNT(*) as count 
      FROM information_schema.columns 
      WHERE table_schema = 'app' 
        AND table_name = 'patient' 
        AND column_name = 'health_risk_score';
    `);
    
    const auditTable = await client.query(`
      SELECT COUNT(*) as count 
      FROM information_schema.tables 
      WHERE table_schema = 'app' 
        AND table_name = 'ai_audit_log';
    `);

    console.log('✅ app.embedding table:', embeddingTable.rows[0].count === '1' ? 'Created' : 'Missing');
    console.log('✅ patient.health_risk_score column:', healthRiskColumn.rows[0].count === '1' ? 'Created' : 'Missing');
    console.log('✅ app.ai_audit_log table:', auditTable.rows[0].count === '1' ? 'Created' : 'Missing');

    console.log('\n========================================');
    console.log('✅ AI Enhancement Installed');
    console.log('========================================\n');
    
    console.log('Next steps:');
    console.log('  1. npm run ai:generate   # Generate embeddings');
    console.log('  2. npm run ai:suggest 1 "chest pain"   # Test search\n');

  } catch (error) {
    console.error('\n❌ Error installing AI enhancement:');
    console.error(error.message);
    if (error.stack) {
      console.error('\nStack trace:');
      console.error(error.stack);
    }
    process.exit(1);
  } finally {
    await client.end();
  }
}

installAI();