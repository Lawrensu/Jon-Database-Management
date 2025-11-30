// scripts/generate_synthetic_data.js
// Dev-only synthetic embedding inserter.
// Usage:
//   PGHOST=localhost PGUSER=jondb_admin PGPASSWORD=... PGDATABASE=jon_database_dev NUM_INSERTS=200 node scripts/generate_synthetic_data.js

require('dotenv').config();
const { Client } = require('pg');

const EMB_DIM = Number(process.env.EMB_DIM || 1536);
const NUM_INSERTS = Number(process.env.NUM_INSERTS || 200);

function randomVectorText(d) {
  const arr = [];
  for (let i = 0; i < d; i++) arr.push((Math.random() * 2 - 1).toFixed(6));
  return '[' + arr.join(',') + ']';
}

const notes = [
  'Patient reports mild headache and nausea for 2 days.',
  'Prescribed medication for high blood pressure; take twice daily.',
  'Follow-up: symptoms improved after therapy.',
  'Patient reports allergy to penicillin.',
  'Medication adherence low; missed last 2 scheduled doses.'
];

async function main() {
  const client = new Client({
    host: process.env.POSTGRES_HOST,
    port: Number(process.env.POSTGRES_PORT),
    user: process.env.POSTGRES_USER,
    password: process.env.POSTGRES_PASSWORD,
    database: process.env.POSTGRES_DB
  });
  await client.connect();

  try {
    const res = await client.query('SELECT patient_id FROM app.patient LIMIT 50');
    const patientIds = res.rows.map(r => r.patient_id);

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