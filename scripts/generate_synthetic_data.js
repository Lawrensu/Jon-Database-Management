// scripts/generate_synthetic_data.js
// Dev-only synthetic embedding inserter.
// Usage:
//   PGHOST=localhost PGUSER=jondb_admin PGPASSWORD=... PGDATABASE=jon_database_dev NUM_INSERTS=200 node scripts/generate_synthetic_data.js

const { Client } = require('pg');

const EMB_DIM = Number(process.env.EMB_DIM || 1536);
const NUM_INSERTS = Number(process.env.NUM_INSERTS || 200);

function randomVectorText(d) {
  return '[' + Array.from({ length: d }, () => (Math.random() * 2 - 1).toFixed(6)).join(',') + ']';
}

const notes = [
  'Patient reports mild headache and nausea for 2 days.',
  'Prescribed medication for high blood pressure; take twice daily.',
  'Follow-up: symptoms improved after therapy.',
  'Patient reports allergy to penicillin.',
  'Medication adherence low; missed last 2 scheduled doses.'
];

async function main() {
  const client = new Client();
  await client.connect();

  try {
    const res = await client.query('SELECT id, patient_id FROM app.patient LIMIT 50');
    const patientIds = res.rows.map(r => r.patient_id || r.id);

    for (let i = 0; i < NUM_INSERTS; i++) {
      const snippet = notes[i % notes.length] + ` (synthetic ${i})`;
      const vec = randomVectorText(EMB_DIM);
      const srcTable = 'patient_note';
      const srcId = patientIds.length ? patientIds[i % patientIds.length] : null;

      await client.query(
        `INSERT INTO app.embedding (source_table, source_id, text_snippet, embedding) VALUES ($1,$2,$3,$4)`,
        [srcTable, srcId, snippet, vec]
      );

      if (i % 50 === 0) console.log(`Inserted ${i} embeddings`);
    }

    await client.query('ANALYZE app.embedding');
    console.log('Inserted synthetic embeddings.');
  } finally {
    await client.end();
  }
}

main().catch(err => { console.error(err); process.exit(1); });
