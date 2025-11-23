-- PAKAR Tech Healthcare - Patient Workflow Test Script
-- COS 20031 Database Design Project

SET search_path TO app, public;

BEGIN;

-- ============================================================================
-- TEST 1: View my prescriptions
-- ============================================================================
SELECT 
    p.prescription_id,
    p.status,
    p.created_date,
    u_doctor.first_name || ' ' || u_doctor.last_name AS doctor_name,
    doc.specialisation,
    m.med_name,
    m.med_brand_name,
    pv.titration,
    pv.titration_unit,
    pv.start_date::DATE,
    pv.end_date::DATE
FROM app.prescription p
JOIN app.prescription_version pv ON p.prescription_id = pv.prescription_id
JOIN app.doctor doc ON p.doctor_id = doc.doctor_id
JOIN app.user_account u_doctor ON doc.user_id = u_doctor.user_id
JOIN app.medication m ON pv.medication_id = m.medication_id
WHERE p.patient_id = (SELECT patient_id FROM app.patient LIMIT 1)
ORDER BY p.created_date DESC;

-- ============================================================================
-- TEST 2: View my medication schedule
-- ============================================================================
SELECT 
    ms.medication_schedule_id,
    m.med_name,
    m.med_brand_name,
    pv.titration || ' ' || pv.titration_unit AS dose,
    ms.med_timing,
    ms.frequency_times_per_day,
    ms.frequency_interval_hours,
    ms.duration,
    ms.duration_unit,
    pv.start_date::DATE,
    pv.end_date::DATE,
    CASE 
        WHEN pv.end_date < CURRENT_TIMESTAMP THEN 'Completed'
        WHEN pv.start_date > CURRENT_TIMESTAMP THEN 'Upcoming'
        ELSE 'Active'
    END AS schedule_status
FROM app.medication_schedule ms
JOIN app.prescription_version pv ON ms.prescription_version_id = pv.prescription_version_id
JOIN app.prescription p ON pv.prescription_id = p.prescription_id
JOIN app.medication m ON pv.medication_id = m.medication_id
WHERE p.patient_id = (SELECT patient_id FROM app.patient LIMIT 1)
ORDER BY pv.start_date DESC;

-- ============================================================================
-- TEST 3: View upcoming reminders (next 7 days)
-- ============================================================================
SELECT 
    r.reminder_id,
    r.schedule::DATE AS reminder_date,
    r.schedule::TIME AS reminder_time,
    r.message,
    m.med_name,
    pv.titration || ' ' || pv.titration_unit AS dose,
    ms.med_timing
FROM app.reminder r
JOIN app.medication_schedule ms ON r.medication_schedule_id = ms.medication_schedule_id
JOIN app.prescription_version pv ON ms.prescription_version_id = pv.prescription_version_id
JOIN app.medication m ON pv.medication_id = m.medication_id
WHERE r.patient_id = (SELECT patient_id FROM app.patient LIMIT 1)
  AND r.schedule BETWEEN NOW() AND NOW() + INTERVAL '7 days'
ORDER BY r.schedule ASC;

-- ============================================================================
-- TEST 4: Log medication intake
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
    (SELECT patient_id FROM app.patient LIMIT 1),
    (SELECT medication_id FROM app.medication LIMIT 1),
    (SELECT medication_schedule_id FROM app.medication_schedule LIMIT 1),
    NOW(),
    NOW(),
    'Taken',
    'Took medication with breakfast - automated test entry'
WHERE EXISTS (SELECT 1 FROM app.patient)
  AND EXISTS (SELECT 1 FROM app.medication)
  AND EXISTS (SELECT 1 FROM app.medication_schedule);

-- ============================================================================
-- TEST 5: View my medication log history
-- ============================================================================
SELECT 
    ml.medication_log_id,
    ml.log_time::DATE AS log_date,
    ml.actual_taken_time::TIME AS taken_time,
    m.med_name,
    ms.frequency_times_per_day,
    ml.status,
    ml.notes
FROM app.medication_log ml
JOIN app.medication m ON ml.medication_id = m.medication_id
JOIN app.medication_schedule ms ON ml.medication_schedule_id = ms.medication_schedule_id
WHERE ml.patient_id = (SELECT patient_id FROM app.patient LIMIT 1)
ORDER BY ml.log_time DESC
LIMIT 10;

COMMIT;

-- ============================================================================
-- SUMMARY REPORT
-- ============================================================================
\echo '============================================'
\echo '📊 Patient Workflow Test Summary'
\echo '============================================'

SELECT 
    'My Prescriptions' AS metric,
    COUNT(DISTINCT p.prescription_id)::text AS count
FROM app.prescription p
WHERE p.patient_id = (SELECT patient_id FROM app.patient LIMIT 1)
UNION ALL
SELECT 
    'My Medication Schedules',
    COUNT(*)::text
FROM app.medication_schedule ms
JOIN app.prescription_version pv ON ms.prescription_version_id = pv.prescription_version_id
JOIN app.prescription p ON pv.prescription_id = p.prescription_id
WHERE p.patient_id = (SELECT patient_id FROM app.patient LIMIT 1)
UNION ALL
SELECT 
    'My Upcoming Reminders',
    COUNT(*)::text
FROM app.reminder r
WHERE r.patient_id = (SELECT patient_id FROM app.patient LIMIT 1)
  AND r.schedule >= NOW()
UNION ALL
SELECT 
    'My Medication Logs',
    COUNT(*)::text
FROM app.medication_log ml
WHERE ml.patient_id = (SELECT patient_id FROM app.patient LIMIT 1)
UNION ALL
SELECT 
    'Medications Taken',
    COUNT(*)::text
FROM app.medication_log ml
WHERE ml.patient_id = (SELECT patient_id FROM app.patient LIMIT 1)
  AND ml.status = 'Taken';