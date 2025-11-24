-- PAKAR Tech Healthcare - Medication Reminders
-- COS 20031 Database Design Project
-- Purpose: Create upcoming medication reminders
-- Author: [Cherylynn]

SET search_path TO app, public;

BEGIN;

-- ============================================================================
-- CREATE REMINDERS
-- For next 7 days, only for active prescriptions
-- ============================================================================

INSERT INTO app.reminder (
    patient_id,
    medication_schedule_id,
    message,
    schedule
)
SELECT 
    pr.patient_id,
    ms.medication_schedule_id,
    '⏰ Reminder: Take your ' || m.med_name || ' (' || pv.titration || pv.titration_unit || ') ' ||
    CASE 
        WHEN ms.med_timing = 'BeforeMeal' THEN 'before your meal'
        ELSE 'after your meal'
    END AS message,
    -- Reminders for next 7 days
    CURRENT_TIMESTAMP + (random() * 7)::INTEGER * INTERVAL '1 day' + 
    (random() * 24)::INTEGER * INTERVAL '1 hour' AS schedule
FROM app.prescription pr
JOIN app.prescription_version pv ON pr.prescription_id = pv.prescription_id
JOIN app.medication_schedule ms ON pv.prescription_version_id = ms.prescription_version_id
JOIN app.medication m ON pv.medication_id = m.medication_id
WHERE pr.status = 'Active'
AND pv.end_date IS NULL
AND random() < 0.3  -- Only 30% of active prescriptions get reminders
LIMIT 150  -- Limit to 150 reminders
ON CONFLICT DO NOTHING;

COMMIT;

-- ============================================================================
-- VERIFICATION
-- ============================================================================

DO $$
DECLARE
    total_reminders INT;
    upcoming_reminders INT;
    unique_patients INT;
    unique_medications INT;
BEGIN
    SELECT COUNT(*) INTO total_reminders FROM app.reminder;
    SELECT COUNT(*) INTO upcoming_reminders FROM app.reminder WHERE schedule > CURRENT_TIMESTAMP;
    SELECT COUNT(DISTINCT patient_id) INTO unique_patients FROM app.reminder;
    SELECT COUNT(DISTINCT ms.medication_schedule_id) INTO unique_medications 
    FROM app.reminder r
    JOIN app.medication_schedule ms ON r.medication_schedule_id = ms.medication_schedule_id;
    
    RAISE NOTICE '========================================';
    RAISE NOTICE 'Reminder Seed Data Loaded';
    RAISE NOTICE '========================================';
    RAISE NOTICE 'Total Reminders: %', total_reminders;
    RAISE NOTICE '  Upcoming (next 7 days): %', upcoming_reminders;
    RAISE NOTICE '';
    RAISE NOTICE 'Unique Patients: %', unique_patients;
    RAISE NOTICE 'Unique Medication Schedules: %', unique_medications;
    RAISE NOTICE '';
    RAISE NOTICE 'Time Period: Next 7 days';
    RAISE NOTICE 'Note: 30%% of active patients receive reminders';
    RAISE NOTICE '========================================';
END $$;