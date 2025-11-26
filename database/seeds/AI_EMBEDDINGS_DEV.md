## AI / Embeddings (DEV ONLY)

Purpose: provide synthetic text + embeddings for local demos of semantic retrieval and suggestions.

1. Apply SQL patch (inside postgres container):

```powershell
docker compose exec -T postgres psql -U jondb_admin -d jon_database_dev -f database/project/99_ai_extensions.sql
```

2. Generate synthetic embeddings:

```powershell
# from project root
$env:NUM_INSERTS = "200"; node scripts/generate_synthetic_data.js
```

3. Run suggestion skeleton:

```powershell
node scripts/patient_suggestion_service.js <patient_id> "patient complains of chest pain"
```

Notes:
- Use only synthetic or anonymized text in embeddings for demos.
- Do NOT call external embedding/LLM APIs with real PII without consent and controls.
