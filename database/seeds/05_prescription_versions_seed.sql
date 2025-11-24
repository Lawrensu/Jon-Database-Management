-- PAKAR Tech Healthcare - Prescription Versions (Medication Details)
-- COS 20031 Database Design Project
-- Purpose: Link prescriptions to specific medications with dosages

SET search_path TO app, public;

BEGIN;

INSERT INTO app.prescription_version (
    prescription_id,
    medication_id,
    titration,
    titration_unit,
    start_date,
    end_date,
    reason_for_change
)
SELECT 
    pr.prescription_id,
    m.medication_id,
    CASE 
        WHEN m.med_name = 'Metformin Hydrochloride' THEN 500.0
        WHEN m.med_name = 'Amlodipine Besylate' THEN 5.0
        WHEN m.med_name = 'Lisinopril' THEN 10.0
        WHEN m.med_name = 'Atorvastatin Calcium' THEN 20.0
        WHEN m.med_name = 'Omeprazole' THEN 20.0
        WHEN m.med_name = 'Salbutamol Sulfate' THEN 100.0
        WHEN m.med_name = 'Paracetamol' THEN 500.0
        WHEN m.med_name = 'Ibuprofen' THEN 400.0
        WHEN m.med_name = 'Amoxicillin' THEN 500.0
        WHEN m.med_name = 'Cetirizine Hydrochloride' THEN 10.0
        WHEN m.med_name = 'Losartan Potassium' THEN 50.0
        WHEN m.med_name = 'Simvastatin' THEN 20.0
        WHEN m.med_name = 'Aspirin' THEN 100.0
        WHEN m.med_name = 'Furosemide' THEN 40.0
        WHEN m.med_name = 'Levothyroxine Sodium' THEN 0.1
        ELSE 100.0
    END AS titration,
    'mg'::titration_unit_enum AS titration_unit,
    pr.created_date AS start_date,
    CASE 
        WHEN pr.status = 'Active' THEN NULL
        WHEN pr.status = 'Completed' THEN pr.created_date + (30 + random() * 60)::INTEGER * INTERVAL '1 day'
        WHEN pr.status = 'Expired' THEN pr.created_date + (30 + random() * 60)::INTEGER * INTERVAL '1 day'
        WHEN pr.status = 'Cancelled' THEN pr.created_date + (1 + random() * 13)::INTEGER * INTERVAL '1 day'
        ELSE NULL
    END AS end_date,
    CASE 
        WHEN pr.status = 'Active' THEN 'Initial prescription'
        WHEN pr.status = 'Completed' THEN 'Treatment completed successfully'
        WHEN pr.status = 'Expired' THEN 'Prescription period ended'
        WHEN pr.status = 'Cancelled' THEN 'Prescription cancelled by doctor'
        ELSE 'Status changed to ' || pr.status::TEXT
    END AS reason_for_change
FROM app.prescription pr
CROSS JOIN LATERAL (
    SELECT medication_id, med_name
    FROM app.medication 
    ORDER BY RANDOM() 
    LIMIT 1
) m
ON CONFLICT DO NOTHING;

COMMIT;

DO $$
DECLARE
    total_versions INT;
    active_versions INT;
    total_prescriptions INT;
BEGIN
    SELECT COUNT(*) INTO total_prescriptions FROM app.prescription;
    SELECT COUNT(*) INTO total_versions FROM app.prescription_version;
    SELECT COUNT(*) INTO active_versions FROM app.prescription_version WHERE end_date IS NULL;
    
    RAISE NOTICE '========================================';
    RAISE NOTICE 'Prescription Version Seed Data Loaded';
    RAISE NOTICE '========================================';
    RAISE NOTICE 'Total Prescriptions: %', total_prescriptions;
    RAISE NOTICE 'Total Versions Created: %', total_versions;
    RAISE NOTICE '  Active (no end_date): %', active_versions;
    RAISE NOTICE '';
    RAISE NOTICE 'Medications used: All 15 from 00_reference_data.sql';
    RAISE NOTICE '========================================';
END $$;