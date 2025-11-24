-- PAKAR Tech Healthcare - Patient Symptoms
-- COS 20031 Database Design Project
-- Purpose: Link patients to their reported symptoms

SET search_path TO app, public;

BEGIN;

INSERT INTO app.patient_symptom (
    patient_id,
    symptom_id,
    date_reported,
    notes,
    severity,
    date_resolved
)
SELECT 
    p.patient_id,
    s.symptom_id,
    (CURRENT_TIMESTAMP - ((30 + random() * 30)::INTEGER * INTERVAL '1 day')) AS date_reported,
    'Patient reported ' || c.condition_name || ' - ' ||
    CASE 
        WHEN c.condition_name = 'Headache' THEN 'Throbbing pain in temples'
        WHEN c.condition_name = 'Nausea' THEN 'Feeling sick after meals'
        WHEN c.condition_name = 'Dizziness' THEN 'Light-headed when standing'
        WHEN c.condition_name = 'Fatigue' THEN 'Extreme tiredness throughout day'
        WHEN c.condition_name = 'Fever' THEN 'Body temperature 38.5°C'
        WHEN c.condition_name = 'Cough' THEN 'Persistent dry cough'
        WHEN c.condition_name = 'Chest Pain' THEN 'Discomfort in chest area'
        WHEN c.condition_name = 'Shortness of Breath' THEN 'Difficulty breathing'
        WHEN c.condition_name = 'Abdominal Pain' THEN 'Stomach cramps and discomfort'
        WHEN c.condition_name = 'Joint Pain' THEN 'Pain and stiffness in joints'
        ELSE 'General discomfort'
    END AS notes,
    CASE 
        WHEN random() < 0.3 THEN 'Mild'::severity_enum
        WHEN random() < 0.8 THEN 'Moderate'::severity_enum
        ELSE 'Severe'::severity_enum
    END AS severity,
    CASE 
        WHEN random() < 0.5 THEN 
            (CURRENT_TIMESTAMP - (random() * 29)::INTEGER * INTERVAL '1 day')
        ELSE NULL
    END AS date_resolved
FROM app.patient p
CROSS JOIN LATERAL (
    SELECT symptom_id 
    FROM app.symptom 
    ORDER BY RANDOM() 
    LIMIT (1 + random() * 2)::INT
) s
JOIN app.symptom sym ON s.symptom_id = sym.symptom_id
JOIN app.condition c ON sym.condition_id = c.condition_id
WHERE p.patient_id <= 150
ON CONFLICT (patient_id, symptom_id, date_reported) DO NOTHING;

COMMIT;

DO $$
DECLARE
    total_symptoms INT;
    date_error_count INT;
BEGIN
    SELECT COUNT(*) INTO total_symptoms FROM app.patient_symptom;
    
    SELECT COUNT(*) INTO date_error_count 
    FROM app.patient_symptom 
    WHERE date_resolved IS NOT NULL AND date_resolved < date_reported;
    
    RAISE NOTICE '========================================';
    RAISE NOTICE 'Patient Symptom Seed Data Loaded';
    RAISE NOTICE '========================================';
    RAISE NOTICE 'Total Patient Symptoms: %', total_symptoms;
    RAISE NOTICE 'Date Constraint Errors: % (should be 0)', date_error_count;
    RAISE NOTICE '========================================';
END $$;