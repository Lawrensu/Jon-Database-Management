-- PAKAR Tech Healthcare - Medication Schedules
-- COS 20031 Database Design Project
-- Purpose: Define when and how often patients should take medications
-- Author: [Cherylynn]

SET search_path TO app, public;

BEGIN;

-- ============================================================================
-- CREATE MEDICATION SCHEDULES
-- Only for active prescription versions (end_date IS NULL)
-- ============================================================================

INSERT INTO app.medication_schedule (
    prescription_version_id,
    med_timing,
    frequency_times_per_day,
    frequency_interval_hours,
    duration,
    duration_unit
)
SELECT 
    pv.prescription_version_id,
    -- Timing based on medication type
    CASE 
        WHEN m.med_name IN ('Metformin Hydrochloride', 'Omeprazole', 'Paracetamol', 'Ibuprofen') 
        THEN 'AfterMeal'::med_timing_enum  -- GI medications after meals
        ELSE 'BeforeMeal'::med_timing_enum -- Others before meals
    END AS med_timing,
    -- Frequency based on medication type
    CASE 
        WHEN m.med_name IN ('Amlodipine Besylate', 'Lisinopril', 'Atorvastatin Calcium', 
                             'Levothyroxine Sodium', 'Cetirizine Hydrochloride')
        THEN 1  -- Once daily (cardiac, thyroid, allergy meds)
        
        WHEN m.med_name IN ('Metformin Hydrochloride', 'Losartan Potassium', 'Furosemide')
        THEN 2  -- Twice daily (diabetes, BP meds)
        
        WHEN m.med_name IN ('Paracetamol', 'Ibuprofen', 'Amoxicillin', 'Omeprazole')
        THEN 3  -- Three times daily (pain relief, antibiotics, acid reflux)
        
        ELSE 2  -- Default: twice daily
    END AS frequency_times_per_day,
    -- Interval hours based on frequency
    CASE 
        WHEN m.med_name IN ('Amlodipine Besylate', 'Lisinopril', 'Atorvastatin Calcium', 
                             'Levothyroxine Sodium', 'Cetirizine Hydrochloride')
        THEN 24  -- Every 24 hours (once daily)
        
        WHEN m.med_name IN ('Metformin Hydrochloride', 'Losartan Potassium', 'Furosemide')
        THEN 12  -- Every 12 hours (twice daily)
        
        WHEN m.med_name IN ('Paracetamol', 'Ibuprofen', 'Amoxicillin', 'Omeprazole')
        THEN 8   -- Every 8 hours (three times daily)
        
        ELSE 12  -- Default: every 12 hours
    END AS frequency_interval_hours,
    -- Duration based on medication type
    CASE 
        WHEN m.med_name IN ('Amoxicillin', 'Cetirizine Hydrochloride', 'Salbutamol Sulfate')
        THEN 14  -- Antibiotics, short-term: 14 days
        
        WHEN m.med_name IN ('Paracetamol', 'Ibuprofen', 'Omeprazole')
        THEN 30  -- Pain relief, acid reflux: 30 days
        
        WHEN m.med_name IN ('Metformin Hydrochloride', 'Amlodipine Besylate', 'Lisinopril', 
                             'Atorvastatin Calcium', 'Losartan Potassium', 'Simvastatin', 
                             'Aspirin', 'Furosemide', 'Levothyroxine Sodium')
        THEN 90  -- Chronic conditions: 90 days
        
        ELSE 30  -- Default: 30 days
    END AS duration,
    'Days'::duration_unit_enum AS duration_unit
FROM app.prescription_version pv
JOIN app.medication m ON pv.medication_id = m.medication_id
WHERE pv.end_date IS NULL  -- Only active prescription versions
ON CONFLICT DO NOTHING;

COMMIT;

-- ============================================================================
-- VERIFICATION
-- ============================================================================

DO $$
DECLARE
    total_schedules INT;
    once_daily INT;
    twice_daily INT;
    three_times_daily INT;
    short_term INT;  -- 14 days
    medium_term INT; -- 30 days
    long_term INT;   -- 90 days
BEGIN
    SELECT COUNT(*) INTO total_schedules FROM app.medication_schedule;
    SELECT COUNT(*) INTO once_daily FROM app.medication_schedule WHERE frequency_times_per_day = 1;
    SELECT COUNT(*) INTO twice_daily FROM app.medication_schedule WHERE frequency_times_per_day = 2;
    SELECT COUNT(*) INTO three_times_daily FROM app.medication_schedule WHERE frequency_times_per_day = 3;
    
    SELECT COUNT(*) INTO short_term FROM app.medication_schedule WHERE duration = 14;
    SELECT COUNT(*) INTO medium_term FROM app.medication_schedule WHERE duration = 30;
    SELECT COUNT(*) INTO long_term FROM app.medication_schedule WHERE duration = 90;
    
    RAISE NOTICE '========================================';
    RAISE NOTICE 'Medication Schedule Seed Data Loaded';
    RAISE NOTICE '========================================';
    RAISE NOTICE 'Total Schedules: %', total_schedules;
    RAISE NOTICE '';
    RAISE NOTICE 'Frequency Distribution:';
    RAISE NOTICE '  Once Daily (24h interval): %', once_daily;
    RAISE NOTICE '  Twice Daily (12h interval): %', twice_daily;
    RAISE NOTICE '  Three Times Daily (8h interval): %', three_times_daily;
    RAISE NOTICE '';
    RAISE NOTICE 'Duration Distribution:';
    RAISE NOTICE '  Short-term (14 days): %', short_term;
    RAISE NOTICE '  Medium-term (30 days): %', medium_term;
    RAISE NOTICE '  Long-term (90 days): %', long_term;
    RAISE NOTICE '';
    RAISE NOTICE 'Note: Only active prescriptions (end_date IS NULL) have schedules';
    RAISE NOTICE '========================================';
END $$;