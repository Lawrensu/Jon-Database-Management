-- database/seeds/11_generate_embeddings.sql
-- Generate 200 synthetic embeddings for testing
-- This is a pure SQL version of generate_synthetic_data.js

-- Ensure vector extension is available
CREATE EXTENSION IF NOT EXISTS vector;

-- Generate embeddings using INSERT SELECT (avoids DO block type issues)
INSERT INTO app.embedding (source_table, source_id, text_snippet, embedding)
SELECT 
    'patient_note' AS source_table,
    p.patient_id AS source_id,
    notes.text || ' (synthetic ' || (ROW_NUMBER() OVER () - 1)::text || ')' AS text_snippet,
    -- Generate random 1536-dimensional vector
    ('[' || (
        SELECT string_agg((random() * 2 - 1)::numeric(10,6)::text, ',')
        FROM generate_series(1, 1536)
    ) || ']')::app.vector(1536) AS embedding
FROM 
    (SELECT patient_id FROM app.patient ORDER BY patient_id LIMIT 50) p
CROSS JOIN
    generate_series(1, 4) gs  -- 4 embeddings per patient = 200 total
CROSS JOIN LATERAL
    (SELECT * FROM unnest(ARRAY[
        'Patient reports mild headache and nausea for 2 days.',
        'Prescribed medication for high blood pressure; take twice daily.',
        'Follow-up: symptoms improved after therapy.',
        'Patient reports allergy to penicillin.',
        'Medication adherence low; missed last 2 scheduled doses.'
    ]) WITH ORDINALITY AS t(text, rn) 
    WHERE rn = ((gs - 1) % 5) + 1
    ) notes
LIMIT 200;

-- Analyze for better query performance
ANALYZE app.embedding;

-- Verify insertion
SELECT 
    COUNT(*) as total_embeddings,
    COUNT(DISTINCT source_id) as unique_patients
FROM app.embedding;

-- Commit the transaction
COMMIT;
