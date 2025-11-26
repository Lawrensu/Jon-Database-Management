-- database/queries/03_semantic_search.sql
-- Semantic similarity search using embeddings
-- Usage: Pass patient_id and search query as parameters

BEGIN;

-- Set search path to include app schema for vector operators
SET search_path TO app, public;

\echo '=========================================='
\echo 'AI Semantic Patient Similarity Search'
\echo '=========================================='
\echo ''

-- Set variables (you can change these when running)
-- Default: search for patient similar to patient #1
\set target_patient 1
\set search_query '''patient reports chest pain and dizziness'''

\echo 'Search Parameters:'
\echo '  Target Patient ID: ' :target_patient
\echo '  Query: ' :search_query
\echo ''

-- Get patient information
\echo '📋 Target Patient Information:'
SELECT 
    p.patient_id,
    u.first_name || ' ' || u.last_name as patient_name,
    EXTRACT(YEAR FROM age(CURRENT_DATE, p.birth_date))::int as age,
    p.gender,
    p.health_risk_score
FROM app.patient p
JOIN app.user_account u ON p.user_id = u.user_id
WHERE p.patient_id = :'target_patient';

\echo ''
\echo '🔍 Finding Similar Patients (Top 10)...'
\echo ''

-- Find similar patients using vector similarity
-- Note: In production, you'd embed the search_query using an API
-- For demo, we'll find patients with similar embeddings

SELECT 
    e.source_id as similar_patient_id,
    u.first_name || ' ' || u.last_name as patient_name,
    EXTRACT(YEAR FROM age(CURRENT_DATE, p.birth_date))::int as age,
    p.gender,
    e.text_snippet,
    -- Calculate similarity score (L2 distance - lower is more similar)
    ROUND((e.embedding <-> (
        SELECT embedding 
        FROM app.embedding 
        WHERE source_id = :'target_patient' 
        LIMIT 1
    ))::numeric, 4) as distance,
    p.health_risk_score as ai_risk_score
FROM app.embedding e
JOIN app.patient p ON e.source_id::int = p.patient_id
JOIN app.user_account u ON p.user_id = u.user_id
WHERE e.source_id != :'target_patient'  -- Exclude target patient
  AND e.source_table = 'patient_note'
ORDER BY e.embedding <-> (
    SELECT embedding 
    FROM app.embedding 
    WHERE source_id = :'target_patient' 
    LIMIT 1
)
LIMIT 10;

\echo ''
\echo '📊 Risk Assessment of Similar Patients:'
\echo ''

-- Show DS risk scores for similar patients
WITH similar_patients AS (
    SELECT 
        e.source_id::int as patient_id,
        e.embedding <-> (
            SELECT embedding 
            FROM app.embedding 
            WHERE source_id = :'target_patient' 
            LIMIT 1
        ) as dist
    FROM app.embedding e
    WHERE e.source_id != :'target_patient'
      AND e.source_table = 'patient_note'
    ORDER BY dist
    LIMIT 10
)
SELECT 
    vra.patient_name,
    vra.ds_risk_score,
    vra.ds_risk_category,
    vra.active_symptoms,
    vra.active_prescriptions,
    ROUND(vra.adherence_percentage, 2) as adherence_pct
FROM analytics.v_patient_risk_assessment vra
JOIN similar_patients sp ON vra.patient_id = sp.patient_id
ORDER BY vra.ds_risk_score DESC;

\echo ''
\echo '✅ Semantic Search Completed'
\echo ''

ROLLBACK;
