# AI feature quick-start (dev-safe)

This file describes quick steps to try the embeddings + suggestion demo locally using synthetic data.

1. Apply AI SQL patch (run inside the postgres container):

```powershell
docker compose exec -T postgres psql -U jondb_admin -d jon_database_dev -f database/project/99_ai_extensions.sql
```

2. Seed synthetic embeddings (uses your environment variables for DB connection):

```powershell
# from project root
# set PG env vars or rely on defaults in your environment
$env:NUM_INSERTS = "200"; node scripts/generate_synthetic_data.js
```

3. Run the suggestion skeleton (dev-only):

```powershell
node scripts/patient_suggestion_service.js <patient_id> "patient reports chest pain"
```

Notes:
- This demo uses randomly generated vectors for safety. Do not send real PII to external embedding or LLM services.
- The SQL patch enables `pgvector` and creates an `app.embedding` table; ensure your Postgres image supports the extension.
