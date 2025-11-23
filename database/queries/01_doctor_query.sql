-- Complete Doctor Workflow Test (Auto-executable)
SET search_path TO app, public;

BEGIN;

-- ============================================================================
-- STEP 1: Admin assigns patient to doctor
-- ============================================================================
INSERT INTO app.patient_doctor (patient_id, doctor_id, assigned_by)
SELECT 
    (SELECT patient_id FROM app.patient LIMIT 1),
    (SELECT doctor_id FROM app.doctor LIMIT 1),
    (SELECT user_id FROM app.user_account WHERE user_type = 'Admin' LIMIT 1)
WHERE EXISTS (SELECT 1 FROM app.patient)
  AND EXISTS (SELECT 1 FROM app.doctor)
ON CONFLICT (patient_id, doctor_id) DO UPDATE 
  SET assigned_at = now();

\echo '✅ Step 1: Patient assigned to doctor'

-- ============================================================================
-- STEP 2: Doctor views assigned patients
-- ============================================================================
SELECT 
    p.patient_id,
    u.first_name || ' ' || u.last_name AS patient_name,
    u.email,
    pd.assigned_at
FROM app.patient p
JOIN app.patient_doctor pd USING (patient_id)
JOIN app.user_account u ON p.user_id = u.user_id
WHERE pd.doctor_id = (SELECT doctor_id FROM app.doctor LIMIT 1)
LIMIT 5;

\echo '✅ Step 2: Doctor can see assigned patients'

-- ============================================================================
-- STEP 3: Doctor records patient symptom
-- ============================================================================
INSERT INTO app.patient_symptom (patient_id, symptom_id, date_reported, severity, notes)
SELECT 
    (SELECT patient_id FROM app.patient LIMIT 1),
    (SELECT symptom_id FROM app.symptom LIMIT 1),
    NOW(),
    'Moderate',
    'Persistent headache for 3 days'
WHERE EXISTS (SELECT 1 FROM app.patient)
  AND EXISTS (SELECT 1 FROM app.symptom)
ON CONFLICT (patient_id, symptom_id, date_reported) DO NOTHING;

\echo '✅ Step 3: Patient symptom recorded'

-- ============================================================================
-- STEP 4: Create prescription → prescription_version → schedule → reminders
-- ============================================================================
DO $$
DECLARE
    v_prescription_id INT;
    v_patient_id INT;
    v_doctor_id INT;
    v_medication_id INT;
    v_version_id INT;
    v_schedule_id INT;
BEGIN
    -- Get IDs
    SELECT patient_id INTO v_patient_id FROM app.patient LIMIT 1;
    SELECT doctor_id INTO v_doctor_id FROM app.doctor LIMIT 1;
    SELECT medication_id INTO v_medication_id FROM app.medication LIMIT 1;
    
    -- Step 4a: Create prescription
    INSERT INTO app.prescription (patient_id, doctor_id, status, created_date, doctor_note)
    VALUES (v_patient_id, v_doctor_id, 'Active', NOW(), 'Prescribed for headache relief')
    RETURNING prescription_id INTO v_prescription_id;
    
    RAISE NOTICE '✅ Step 4a: Prescription created (ID: %)', v_prescription_id;
    
    -- Step 4b: Create prescription version
    INSERT INTO app.prescription_version (
        prescription_id, 
        medication_id, 
        titration, 
        titration_unit, 
        start_date, 
        end_date, 
        reason_for_change
    ) VALUES (
        v_prescription_id,
        v_medication_id,
        500,
        'mg',
        NOW(),
        NOW() + INTERVAL '30 days',
        'Initial prescription'
    ) RETURNING prescription_version_id INTO v_version_id;
    
    RAISE NOTICE '✅ Step 4b: Prescription version created (ID: %)', v_version_id;
    
    -- Step 4c: Create medication schedule
    INSERT INTO app.medication_schedule (
        prescription_version_id,
        med_timing,
        frequency_times_per_day,
        frequency_interval_hours,
        duration,
        duration_unit
    ) VALUES (
        v_version_id,
        'AfterMeal',
        2,  -- Twice daily
        12, -- Every 12 hours
        30,
        'Days'
    ) RETURNING medication_schedule_id INTO v_schedule_id;
    
    RAISE NOTICE '✅ Step 4c: Medication schedule created (ID: %)', v_schedule_id;
    
    -- Step 4d: Create reminders (always in the future)
INSERT INTO app.reminder (patient_id, medication_schedule_id, message, schedule)
VALUES 
    -- Tomorrow morning 8 AM
    (v_patient_id, v_schedule_id, 'Morning dose: Take with breakfast', 
     (CURRENT_DATE + INTERVAL '1 day')::timestamp + TIME '08:00'),
    
    -- Tomorrow evening 8 PM
    (v_patient_id, v_schedule_id, 'Evening dose: Take with dinner', 
     (CURRENT_DATE + INTERVAL '1 day')::timestamp + TIME '20:00'),
    
    -- Day after tomorrow morning 8 AM
    (v_patient_id, v_schedule_id, 'Morning dose: Take with breakfast', 
     (CURRENT_DATE + INTERVAL '2 days')::timestamp + TIME '08:00'),
    
    -- Day after tomorrow evening 8 PM
    (v_patient_id, v_schedule_id, 'Evening dose: Take with dinner', 
     (CURRENT_DATE + INTERVAL '2 days')::timestamp + TIME '20:00');
    
    RAISE NOTICE '✅ Step 4d: Reminders created (2 reminders)';
END $$;

-- ============================================================================
-- STEP 5: Patient logs medication as "Taken"
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
    'Took with breakfast'
WHERE EXISTS (SELECT 1 FROM app.medication_schedule);

\echo '✅ Step 5: Patient logged medication as TAKEN'

-- ============================================================================
-- STEP 6: View upcoming reminders
-- ============================================================================
SELECT 
    r.reminder_id,
    r.schedule,
    r.message,
    m.med_name,
    ms.frequency_times_per_day,
    ms.duration || ' ' || ms.duration_unit AS duration
FROM app.reminder r
JOIN app.medication_schedule ms ON r.medication_schedule_id = ms.medication_schedule_id
JOIN app.prescription_version pv ON ms.prescription_version_id = pv.prescription_version_id
JOIN app.medication m ON pv.medication_id = m.medication_id
WHERE r.schedule >= NOW()
ORDER BY r.schedule;

\echo '✅ Step 6: Upcoming reminders displayed'

COMMIT;

-- ============================================================================
-- SUMMARY
-- ============================================================================
\echo ''
\echo '============================================'
\echo '📊 Workflow Summary'
\echo '============================================'

SELECT 
    'Patient-Doctor Assignments' AS metric,
    COUNT(*)::text AS value
FROM app.patient_doctor
UNION ALL
SELECT 'Patient Symptoms', COUNT(*)::text FROM app.patient_symptom
UNION ALL
SELECT 'Active Prescriptions', COUNT(*)::text FROM app.prescription WHERE status = 'Active'
UNION ALL
SELECT 'Prescription Versions', COUNT(*)::text FROM app.prescription_version
UNION ALL
SELECT 'Medication Schedules', COUNT(*)::text FROM app.medication_schedule
UNION ALL
SELECT 'Upcoming Reminders', COUNT(*)::text FROM app.reminder WHERE schedule >= NOW()
UNION ALL
SELECT 'Medications Logged', COUNT(*)::text FROM app.medication_log;