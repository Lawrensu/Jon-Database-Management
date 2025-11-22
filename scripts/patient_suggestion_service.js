// scripts/patient_suggestion_service.js
// Dev-only suggestion skeleton.
// Usage:
//   node scripts/patient_suggestion_service.js <patient_id> "patient note text"
// IMPORTANT: Do NOT send real PII to external APIs in demos.

const { Client } = require('pg');

const EMB_DIM = Number(process.env.EMB_DIM || 1536);

function randomVecText(d) {
  return '[' + Array.from({ length: d }, () => (Math.random() * 2 - 1).toFixed(6)).join(',') + ']';
}

async function run(patientId, noteText) {
  const client = new Client();
  await client.connect();

  try {
    // In dev: fake embedding; replace with real embedding call for production
    const emb = randomVecText(EMB_DIM);

    const sql = `
      SELECT source_table, source_id, text_snippet
      FROM app.embedding
      ORDER BY embedding <-> $1
      LIMIT 5;
    `;
    const res = await client.query(sql, [emb]);
    const snippets = res.rows.map(r => r.text_snippet).filter(Boolean);

    console.log('Top retrieved snippets:');
    snippets.forEach((s, i) => console.log(`${i+1}. ${s}`));

    console.log('\nSuggested Actions:');
    console.log('- Check current medications for interactions');
    console.log('- Review adherence logs and missed doses');
    console.log('- Consider follow-up if health_risk_score is high');
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
