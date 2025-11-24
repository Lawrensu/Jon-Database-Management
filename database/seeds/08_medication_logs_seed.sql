-- PAKAR Tech Healthcare - Medication Logs (Adherence Tracking)
-- COS 20031 Database Design Project
-- Purpose: Track if patients actually took their medications

SET search_path TO app, public;

BEGIN;

-- ============================================================================
-- CREATE MEDICATION LOGS
-- Track medication adherence for past 30 days
-- ============================================================================

INSERT INTO app.medication_log (
    patient_id,
    medication_id,
    medication_schedule_id,
    scheduled_time,
    actual_taken_time,
    status,
    notes
)
SELECT 
    pr.patient_id,
    pv.medication_id,
    ms.medication_schedule_id,
    scheduled_time,
    CASE 
        WHEN random() < 0.7 THEN 
            scheduled_time + (random() * 30)::INTEGER * INTERVAL '1 minute'
        ELSE NULL
    END AS actual_taken_time,
    CASE 
        WHEN random() < 0.7 THEN 'Taken'::med_log_status_enum
        WHEN random() < 0.9 THEN 'Missed'::med_log_status_enum
        ELSE 'Skipped'::med_log_status_enum
    END AS status,
    CASE 
        WHEN random() < 0.7 THEN NULL
        WHEN random() < 0.9 THEN 'Forgot to take medication'
        ELSE 'Intentionally skipped - felt unwell'
    END AS notes
FROM app.prescription pr
JOIN app.prescription_version pv ON pr.prescription_id = pv.prescription_id
JOIN app.medication_schedule ms ON pv.prescription_version_id = ms.prescription_version_id
CROSS JOIN LATERAL (
    SELECT generate_series(
        CURRENT_TIMESTAMP - INTERVAL '30 days',
        CURRENT_TIMESTAMP,
        (ms.frequency_interval_hours || ' hours')::INTERVAL
    ) AS scheduled_time
) times
WHERE pr.status = 'Active'
AND pv.end_date IS NULL
LIMIT 2000;

COMMIT;

-- ============================================================================
-- VERIFICATION
-- ============================================================================

DO $$
DECLARE
    total_logs INT;
    taken_count INT;
    missed_count INT;
    skipped_count INT;
    adherence_rate NUMERIC;
    unique_patients INT;
    unique_medications INT;
BEGIN
    SELECT COUNT(*) INTO total_logs FROM app.medication_log;
    SELECT COUNT(*) INTO taken_count FROM app.medication_log WHERE status = 'Taken';
    SELECT COUNT(*) INTO missed_count FROM app.medication_log WHERE status = 'Missed';
    SELECT COUNT(*) INTO skipped_count FROM app.medication_log WHERE status = 'Skipped';
    
    SELECT COUNT(DISTINCT patient_id) INTO unique_patients FROM app.medication_log;
    SELECT COUNT(DISTINCT medication_id) INTO unique_medications FROM app.medication_log;
    
    adherence_rate := ROUND((taken_count * 100.0 / NULLIF(total_logs, 0)), 2);
    
    RAISE NOTICE '========================================';
    RAISE NOTICE 'Medication Log Seed Data Loaded';
    RAISE NOTICE '========================================';
    RAISE NOTICE 'Total Log Entries: %', total_logs;
    RAISE NOTICE '  Taken: % (%%)', taken_count, adherence_rate;
    RAISE NOTICE '  Missed: %', missed_count;
    RAISE NOTICE '  Skipped: %', skipped_count;
    RAISE NOTICE '';
    RAISE NOTICE 'Overall Adherence Rate: %%', adherence_rate;
    RAISE NOTICE 'Unique Patients: %', unique_patients;
    RAISE NOTICE 'Unique Medications: %', unique_medications;
    RAISE NOTICE '';
    RAISE NOTICE 'Time Period: Past 30 days';
    RAISE NOTICE 'Note: Only active prescriptions tracked';
    RAISE NOTICE '========================================';
END $$;