// scripts/patient_suggestion_service.js
// Dev-only suggestion skeleton.
// Usage:
//   node scripts/patient_suggestion_service.js <patient_id> "patient note text"
// IMPORTANT: Do NOT send real PII to external APIs in demos.

require('dotenv').config();
const { Client } = require('pg');

const EMB_DIM = Number(process.env.EMB_DIM || 1536);

function randomVecText(d) {
  const arr = [];
  for (let i = 0; i < d; i++) arr.push((Math.random() * 2 - 1).toFixed(6));
  return '[' + arr.join(',') + ']';
}

async function run(patientId, noteText) {
  const client = new Client({
    host: process.env.POSTGRES_HOST || 'localhost',
    port: Number(process.env.POSTGRES_PORT || 5432),
    user: process.env.POSTGRES_USER || 'jondb_admin',
    password: process.env.POSTGRES_PASSWORD || 'JonathanBangerDatabase26!',
    database: process.env.POSTGRES_DB || 'jon_database_dev'
  });
  await client.connect();

  try {
    // Set search path to include app schema for vector type
    await client.query('SET search_path TO app, public;');
    
    // In dev: fake embedding; replace with real embedding call for production
    const emb = randomVecText(EMB_DIM);

    const sql = `
      SELECT source_table, source_id, text_snippet
      FROM app.embedding
      ORDER BY embedding <-> $1::vector
      LIMIT 5;
    `;
    const res = await client.query(sql, [emb]);
    const snippets = res.rows.map(r => r.text_snippet).filter(Boolean);

    console.log('Top retrieved snippets:');
    snippets.forEach((s, i) => console.log(`${i+1}. ${s}`));

    console.log('\nSuggested Actions:');
    console.log('- Check current medications for patient', patientId);
    console.log('- Review similar cases above for treatment patterns');
    console.log('- Schedule follow-up based on risk assessment');
  } finally {
    await client.end();
  }
}

const [,, patientId, ...noteParts] = process.argv;
const noteText = noteParts.join(' ');
if (!patientId || !noteText) {
  console.error('Usage: node scripts/patient_suggestion_service.js <patient_id> "note text"');
  process.exit(1);
}
run(patientId, noteText).catch(e => { console.error(e); process.exit(1); });