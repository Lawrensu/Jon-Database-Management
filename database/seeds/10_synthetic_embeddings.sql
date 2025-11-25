-- database/seeds/10_synthetic_embeddings.sql
-- Generate 200 synthetic embeddings for AI testing

-- Ensure vector extension is loaded
CREATE EXTENSION IF NOT EXISTS vector;

BEGIN;

DO $$
DECLARE
  patient_record RECORD;
  counter INT := 0;
  snippet TEXT;
  vec TEXT;
  notes TEXT[] := ARRAY[
    'Patient reports mild headache and nausea for 2 days.',
    'Prescribed medication for high blood pressure; take twice daily.',
    'Follow-up: symptoms improved after therapy.',
    'Patient reports allergy to penicillin.',
    'Medication adherence low; missed last 2 scheduled doses.'
  ];
BEGIN
  RAISE NOTICE 'Starting synthetic embedding generation...';
  
  FOR patient_record IN 
    SELECT patient_id FROM app.patient ORDER BY patient_id LIMIT 50
  LOOP
    FOR i IN 1..4 LOOP
      snippet := notes[(counter % 5) + 1] || ' (synthetic ' || counter || ')';
      vec := '[' || (SELECT string_agg((random()*2-1)::TEXT, ',') FROM generate_series(1, 1536)) || ']';
      
      INSERT INTO app.embedding (source_table, source_id, text_snippet, embedding)
      VALUES ('patient_note', patient_record.patient_id::TEXT, snippet, vec::app.vector);
      
      counter := counter + 1;
      
      IF counter % 50 = 0 THEN
        RAISE NOTICE 'Inserted % embeddings', counter;
      END IF;
      
      IF counter >= 200 THEN
        EXIT;
      END IF;
    END LOOP;
    
    IF counter >= 200 THEN
      EXIT;
    END IF;
  END LOOP;
  
  RAISE NOTICE 'Total synthetic embeddings inserted: %', counter;
  ANALYZE app.embedding;
  
  RAISE NOTICE '✓ Synthetic embeddings generated successfully!';
END $$;

COMMIT;

-- Verify the results
SELECT 
  'Total Embeddings' as metric,
  COUNT(*)::TEXT as value
FROM app.embedding

UNION ALL

SELECT 
  'Unique Patients with Embeddings',
  COUNT(DISTINCT source_id)::TEXT
FROM app.embedding;
