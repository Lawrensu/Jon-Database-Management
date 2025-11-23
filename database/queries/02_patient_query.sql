-- PAKAR Tech Healthcare - Patient Workflow Queries
-- COS 20031 Database Design Project
-- Patient can: view info, report symptoms, check schedule, log medications

SET search_path TO app, public;

BEGIN;

-- ============================================================================
-- STEP 1: Patient views their assigned doctor(s)
-- ============================================================================
\echo '============================================'
\echo '👨‍⚕️ STEP 1: My Assigned Doctor(s)'
\echo '============================================'

SELECT 
    d.doctor_id,
    u.first_name || ' ' || u.last_name AS doctor_name,
    u.email AS doctor_email,
    d.specialisation,
    d.phone_num,
    d.clinical_inst AS clinic_address,
    pd.assigned_at
FROM app.patient_doctor pd
JOIN app.doctor d ON pd.doctor_id = d.doctor_id
JOIN app.user_account u ON d.user_id = u.user_id
WHERE pd.patient_id = (SELECT patient_id FROM app.patient LIMIT 1)
ORDER BY pd.assigned_at DESC;

-- ============================================================================
-- STEP 2: Patient views their symptoms and conditions
-- ============================================================================
\echo ''
\echo '============================================'
\echo '🩺 STEP 2: My Symptoms & Conditions'
\echo '============================================'

SELECT 
    ps.patient_symptom_id,
    c.condition_name,
    ps.severity,
    ps.notes,
    ps.date_reported::DATE AS reported_date,
    CASE 
        WHEN ps.date_resolved IS NOT NULL THEN 'Resolved'
        ELSE 'Active'
    END AS status,
    ps.date_resolved::DATE AS resolved_date
FROM app.patient_symptom ps
JOIN app.symptom s ON ps.symptom_id = s.symptom_id
JOIN app.condition c ON s.condition_id = c.condition_id
WHERE ps.patient_id = (SELECT patient_id FROM app.patient LIMIT 1)
ORDER BY ps.date_reported DESC;

-- ============================================================================
-- STEP 3: Patient reports a new symptom (from symptom table)
-- ============================================================================
\echo ''
\echo '============================================'
\echo '📝 STEP 3: Report New Symptom'
\echo '============================================'

-- Show available symptoms to choose from
\echo 'Available symptoms in system:'
SELECT 
    s.symptom_id,
    c.condition_name AS related_condition
FROM app.symptom s
JOIN app.condition c ON s.condition_id = c.condition_id
ORDER BY c.condition_name
LIMIT 10;

-- Patient reports a symptom (pick symptom_id from above list)
INSERT INTO app.patient_symptom (patient_id, symptom_id, date_reported, severity, notes)
SELECT 
    (SELECT patient_id FROM app.patient LIMIT 1),
    (SELECT symptom_id FROM app.symptom WHERE symptom_id = 2 LIMIT 1), -- Example: symptom_id = 2
    NOW(),
    'Mild',
    'Started experiencing this symptom today'
WHERE EXISTS (SELECT 1 FROM app.patient)
  AND EXISTS (SELECT 1 FROM app.symptom WHERE symptom_id = 2)
ON CONFLICT DO NOTHING;

\echo '✅ New symptom reported successfully'

-- ============================================================================
-- STEP 4: Patient views their medication schedule
-- ============================================================================
\echo ''
\echo '============================================'
\echo '💊 STEP 4: My Medication Schedule'
\echo '============================================'

SELECT 
    ms.medication_schedule_id,
    m.med_name,
    m.med_brand_name,
    pv.titration || ' ' || pv.titration_unit AS dose,
    ms.med_timing,
    ms.frequency_times_per_day || ' times per day' AS frequency,
    'Every ' || ms.frequency_interval_hours || ' hours' AS interval,
    ms.duration || ' ' || ms.duration_unit AS duration,
    pv.start_date::DATE AS start_date,
    pv.end_date::DATE AS end_date,
    CASE 
        WHEN pv.end_date < CURRENT_TIMESTAMP THEN '✅ Completed'
        WHEN pv.start_date > CURRENT_TIMESTAMP THEN '⏰ Upcoming'
        ELSE '🔄 Active'
    END AS schedule_status,
    u.first_name || ' ' || u.last_name AS prescribed_by
FROM app.medication_schedule ms
JOIN app.prescription_version pv ON ms.prescription_version_id = pv.prescription_version_id
JOIN app.prescription p ON pv.prescription_id = p.prescription_id
JOIN app.medication m ON pv.medication_id = m.medication_id
JOIN app.doctor d ON p.doctor_id = d.doctor_id
JOIN app.user_account u ON d.user_id = u.user_id
WHERE p.patient_id = (SELECT patient_id FROM app.patient LIMIT 1)
ORDER BY pv.start_date DESC, ms.medication_schedule_id;

-- ============================================================================
-- STEP 5: Patient views upcoming reminders
-- ============================================================================
\echo ''
\echo '============================================'
\echo '⏰ STEP 5: My Upcoming Reminders'
\echo '============================================'

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
  AND r.schedule >= NOW()
ORDER BY r.schedule ASC
LIMIT 10;

-- ============================================================================
-- STEP 6: Patient views their medication log history
-- ============================================================================
\echo ''
\echo '============================================'
\echo '📋 STEP 6: My Medication Log History'
\echo '============================================'

SELECT 
    ml.medication_log_id,
    ml.scheduled_time::DATE AS log_date,                    -- ✅ Fixed: log_time → scheduled_time
    ml.scheduled_time::TIME AS scheduled_time,
    ml.actual_taken_time::TIME AS actual_taken_time,
    m.med_name,
    ml.status,
    ml.notes,
    CASE 
        WHEN ml.status = 'Taken' THEN '✅'
        WHEN ml.status = 'Missed' THEN '❌'
        WHEN ml.status = 'Skipped' THEN '⏭️'
        ELSE '❓'
    END AS status_icon
FROM app.medication_log ml
JOIN app.medication m ON ml.medication_id = m.medication_id
WHERE ml.patient_id = (SELECT patient_id FROM app.patient LIMIT 1)
ORDER BY ml.scheduled_time DESC                              -- ✅ Fixed: log_time → scheduled_time
LIMIT 20;

-- ============================================================================
-- STEP 7: Patient logs medication intake (Update status)
-- ============================================================================
\echo ''
\echo '============================================'
\echo '✏️ STEP 7: Log Medication Intake'
\echo '============================================'

-- Option A: Log new medication as "Taken"
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
    'Took medication with breakfast as scheduled'
WHERE EXISTS (SELECT 1 FROM app.patient)
    AND EXISTS (SELECT 1 FROM app.medication)
    AND EXISTS (SELECT 1 FROM app.medication_schedule)
ON CONFLICT DO NOTHING;

\echo '✅ Medication logged as TAKEN'

-- Option B: Update existing log status (if patient forgot to log earlier)
-- Example: Update most recent "Missed" to "Taken" (late logging)
UPDATE app.medication_log
SET 
    status = 'Taken',
    actual_taken_time = NOW(),
    notes = 'Logged late - took medication but forgot to record it'
    -- ❌ REMOVED: log_time = NOW() (column doesn't exist)
WHERE medication_log_id = (
    SELECT medication_log_id 
    FROM app.medication_log 
    WHERE patient_id = (SELECT patient_id FROM app.patient LIMIT 1)
        AND status = 'Missed'
    ORDER BY scheduled_time DESC 
    LIMIT 1
)
RETURNING medication_log_id, status, notes;

\echo '✅ Medication log status updated'

-- ============================================================================
-- STEP 8: Patient manually marks medication as "Skipped"
-- ============================================================================
\echo ''
\echo '============================================'
\echo '⏭️ STEP 8: Mark Medication as Skipped'
\echo '============================================'

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
    NOW() + INTERVAL '12 hours', -- Next scheduled dose
    NULL, -- Not taken
    'Skipped',
    'Will take next dose - feeling better today'
WHERE EXISTS (SELECT 1 FROM app.patient)
  AND EXISTS (SELECT 1 FROM app.medication)
  AND EXISTS (SELECT 1 FROM app.medication_schedule)
ON CONFLICT DO NOTHING;

\echo '✅ Medication marked as SKIPPED'

COMMIT;

-- ============================================================================
-- SUMMARY REPORT
-- ============================================================================
\echo ''
\echo '============================================'
\echo '📊 Patient Workflow Summary'
\echo '============================================'

SELECT 
    'My Assigned Doctors' AS metric,
    COUNT(*)::text AS value
FROM app.patient_doctor
WHERE patient_id = (SELECT patient_id FROM app.patient LIMIT 1)
UNION ALL
SELECT 
    'My Active Symptoms',
    COUNT(*)::text
FROM app.patient_symptom
WHERE patient_id = (SELECT patient_id FROM app.patient LIMIT 1)
  AND date_resolved IS NULL
UNION ALL
SELECT 
    'My Total Symptoms Reported',
    COUNT(*)::text
FROM app.patient_symptom
WHERE patient_id = (SELECT patient_id FROM app.patient LIMIT 1)
UNION ALL
SELECT 
    'My Active Medication Schedules',
    COUNT(*)::text
FROM app.medication_schedule ms
JOIN app.prescription_version pv ON ms.prescription_version_id = pv.prescription_version_id
JOIN app.prescription p ON pv.prescription_id = p.prescription_id
WHERE p.patient_id = (SELECT patient_id FROM app.patient LIMIT 1)
  AND pv.end_date >= CURRENT_TIMESTAMP
UNION ALL
SELECT 
    'My Upcoming Reminders',
    COUNT(*)::text
FROM app.reminder
WHERE patient_id = (SELECT patient_id FROM app.patient LIMIT 1)
  AND schedule >= NOW()
UNION ALL
SELECT 
    'My Total Medication Logs',
    COUNT(*)::text
FROM app.medication_log
WHERE patient_id = (SELECT patient_id FROM app.patient LIMIT 1)
UNION ALL
SELECT 
    'Medications Taken',
    COUNT(*)::text
FROM app.medication_log
WHERE patient_id = (SELECT patient_id FROM app.patient LIMIT 1)
  AND status = 'Taken'
UNION ALL
SELECT 
    'Medications Missed',
    COUNT(*)::text
FROM app.medication_log
WHERE patient_id = (SELECT patient_id FROM app.patient LIMIT 1)
  AND status = 'Missed'
UNION ALL
SELECT 
    'Medications Skipped',
    COUNT(*)::text
FROM app.medication_log
WHERE patient_id = (SELECT patient_id FROM app.patient LIMIT 1)
  AND status = 'Skipped';

\echo ''
\echo '✅ Patient workflow test completed successfully!'