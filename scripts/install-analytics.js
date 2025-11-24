// Data Science Enhancement: Analytics Installer
// Author: Cherylynn Cassidy

const { execSync } = require('child_process');
const fs = require('fs');
const path = require('path');

const analyticsDir = path.join(__dirname, '../database/analytics');

console.log('========================================');
console.log('Installing Data Science Analytics Views');
console.log('========================================\n');

try {
  const files = fs.readdirSync(analyticsDir)
    .filter(f => f.endsWith('.sql') && f.match(/^\d{2}_/))
    .sort();

  if (files.length === 0) {
    console.error('❌ No analytics SQL files found in database/analytics/');
    process.exit(1);
  }

  for (const file of files) {
    const filePath = path.join(analyticsDir, file);
    console.log(`📊 Installing ${file}...`);
    
    // Read file content and pipe to psql via stdin (works without volume mount)
    const sqlContent = fs.readFileSync(filePath, 'utf8');
    
    try {
      execSync(
        `docker compose exec -T postgres psql -U jondb_admin -d jon_database_dev`,
        { 
          input: sqlContent,
          stdio: ['pipe', 'inherit', 'inherit']
        }
      );
      console.log(`✅ ${file} installed\n`);
    } catch (error) {
      console.error(`❌ Failed to install ${file}`);
      throw error;
    }
  }

  console.log('========================================');
  console.log('✅ All Analytics Views Installed');
  console.log('========================================');
  
  // Verify installation
  console.log('\n📊 Verifying installation...');
  execSync(
    `docker compose exec postgres psql -U jondb_admin -d jon_database_dev -c "SELECT schemaname, viewname FROM pg_views WHERE schemaname = 'analytics' ORDER BY viewname;"`,
    { stdio: 'inherit' }
  );
  
} catch (error) {
  console.error('❌ Error installing analytics:', error.message);
  process.exit(1);
}