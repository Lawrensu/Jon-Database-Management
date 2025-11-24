-- PAKAR Tech Healthcare - Patient Use Case Queries
-- COS 20031 Database Design Project
-- Author: Jason Hernando Kwee

SET search_path TO app, public;


\echo '========================================'
\echo '🧑‍⚕️ Patient Use Case Queries'
\echo '========================================'

\echo ''
\echo 'STEP 1: Patient Assigned Doctor'
\echo '----------------------------------------'

SELECT 
    d.doctor_id,
    u.first_name || ' ' || u.last_name AS doctor_name,
    u.email AS doctor_email,
    d.phone_num AS doctor_phone,
    d.specialisation,
    d.qualification,
    d.created_at AS assigned_date
FROM app.patient p
JOIN app.doctor d ON p.doctor_id = d.doctor_id
JOIN app.user_account u ON d.user_id = u.user_id
WHERE p.patient_id = (SELECT patient_id FROM app.patient LIMIT 1);


\echo ''
\echo 'STEP 2: Patient Symptoms'
\echo '----------------------------------------'

SELECT 
    c.condition_name AS symptom,
    c.condition_desc AS description,
    ps.severity,
    ps.date_reported,
    ps.date_resolved,
    CASE 
        WHEN ps.date_resolved IS NULL THEN 'Ongoing'
        ELSE 'Resolved'
    END AS status,
    ps.notes
FROM app.patient_symptom ps
JOIN app.symptom s ON ps.symptom_id = s.symptom_id
JOIN app.condition c ON s.condition_id = c.condition_id
WHERE ps.patient_id = (SELECT patient_id FROM app.patient LIMIT 1)
ORDER BY ps.date_reported DESC;


\echo ''
\echo 'STEP 3: Patient Prescriptions'
\echo '----------------------------------------'

SELECT 
    pr.prescription_id,
    m.med_name,
    m.med_brand_name,
    pv.titration || ' ' || pv.titration_unit AS dosage,
    pr.created_date,
    pr.status,
    u_doctor.first_name || ' ' || u_doctor.last_name AS prescribed_by,
    pr.doctor_note
FROM app.prescription pr
JOIN app.prescription_version pv ON pr.prescription_id = pv.prescription_id
JOIN app.medication m ON pv.medication_id = m.medication_id
JOIN app.doctor d ON pr.doctor_id = d.doctor_id
JOIN app.user_account u_doctor ON d.user_id = u_doctor.user_id
WHERE pr.patient_id = (SELECT patient_id FROM app.patient LIMIT 1)
  AND pv.end_date IS NULL  -- Current version only
ORDER BY pr.created_date DESC;


\echo ''
\echo 'STEP 4: Medication Side Effects'
\echo '----------------------------------------'

SELECT 
    m.med_name,
    m.med_brand_name,
    c.condition_name AS side_effect,
    c.condition_desc AS description,
    mse.frequency
FROM app.prescription pr
JOIN app.prescription_version pv ON pr.prescription_id = pv.prescription_id
JOIN app.medication m ON pv.medication_id = m.medication_id
JOIN app.medication_side_effect mse ON m.medication_id = mse.medication_id
JOIN app.side_effect se ON mse.side_effect_id = se.side_effect_id
JOIN app.condition c ON se.condition_id = c.condition_id
WHERE pr.patient_id = (SELECT patient_id FROM app.patient LIMIT 1)
  AND pr.status = 'Active'
  AND pv.end_date IS NULL
ORDER BY m.med_name, mse.frequency;


\echo ''
\echo 'STEP 5: Medication Schedule'
\echo '----------------------------------------'

SELECT 
    m.med_name,
    pv.titration || ' ' || pv.titration_unit AS dosage,  -- ✅ Get from prescription_version
    ms.frequency_times_per_day || ' times per day' AS frequency,  -- ✅ Fixed column name
    ms.med_timing AS timing,
    pv.start_date,  -- ✅ Get from prescription_version
    pv.end_date,  -- ✅ Get from prescription_version
    CASE 
        WHEN pv.end_date IS NULL THEN 'Ongoing'
        WHEN pv.end_date > NOW() THEN 'Active'
        ELSE 'Completed'
    END AS status
FROM app.medication_schedule ms
JOIN app.prescription_version pv ON ms.prescription_version_id = pv.prescription_version_id  -- ✅ Get dosage/dates from here
JOIN app.prescription pr ON pv.prescription_id = pr.prescription_id  -- ✅ Get patient_id from here
JOIN app.medication m ON pv.medication_id = m.medication_id  -- ✅ Get med_name from here
WHERE pr.patient_id = (SELECT patient_id FROM app.patient LIMIT 1)  -- ✅ Filter by patient
ORDER BY pv.start_date DESC
LIMIT 10;


\echo ''
\echo '🔄 Auto-updating missed medications...'

-- Call the function to mark missed meds
SELECT app.mark_missed_medications();


\echo ''
\echo 'STEP 6: Medication Adherence Log'
\echo '----------------------------------------'

SELECT 
    m.med_name,
    ml.scheduled_time,
    ml.actual_taken_time,
    ml.status,  -- ✅ Show actual ENUM value (Taken/Missed/Skipped)
    CASE   -- ✅ Separate column for display text
        WHEN ml.status = 'Taken' AND ml.actual_taken_time <= ml.scheduled_time + INTERVAL '1 hour'
        THEN '✅ On Time'
        WHEN ml.status = 'Taken' THEN '⏰ Late'
        WHEN ml.status = 'Missed' THEN '❌ Missed'
        WHEN ml.status = 'Skipped' THEN '⏭️ Skipped'
        ELSE '❓ Unknown'
    END AS adherence_status,  -- ✅ New display column
    ml.notes
FROM app.medication_log ml
JOIN app.medication m ON ml.medication_id = m.medication_id
WHERE ml.patient_id = (SELECT patient_id FROM app.patient LIMIT 1)
ORDER BY ml.scheduled_time DESC
LIMIT 10;


\echo ''
\echo 'STEP 7: Patient Updates Medication Log'
\echo '----------------------------------------'

DO $$
DECLARE
    v_log_id INT;
    v_patient_id INT;
BEGIN
    -- Get first patient
    SELECT patient_id INTO v_patient_id FROM app.patient LIMIT 1;
    
    -- Get first 'Missed' log entry for this patient
    SELECT medication_log_id INTO v_log_id
    FROM app.medication_log
    WHERE patient_id = v_patient_id
      AND status = 'Missed'
    LIMIT 1;
    
    IF v_log_id IS NOT NULL THEN
        -- Update status to 'Taken'
        UPDATE app.medication_log
        SET 
            status = 'Taken',
            actual_taken_time = NOW(),
            notes = 'Marked as taken by patient'
        WHERE medication_log_id = v_log_id;
        
        RAISE NOTICE '✅ Updated log ID % to status: Taken', v_log_id;
    ELSE
        RAISE NOTICE '❌ No missed logs found for patient';
    END IF;
END $$;


\echo ''
\echo 'STEP 8: Patient Reports Symptom'
\echo '----------------------------------------'

DO $$
DECLARE
    v_patient_id INT;
    v_symptom_id INT;
    v_symptom_name TEXT;
BEGIN
    -- Get first patient
    SELECT patient_id INTO v_patient_id FROM app.patient LIMIT 1;
    
    -- Get a symptom (e.g., Headache)
    SELECT s.symptom_id, c.condition_name INTO v_symptom_id, v_symptom_name
    FROM app.symptom s
    JOIN app.condition c ON s.condition_id = c.condition_id
    WHERE c.condition_name = 'Headache'
    LIMIT 1;
    
    -- Patient reports symptom
    INSERT INTO app.patient_symptom (patient_id, symptom_id, date_reported, severity, notes)
    VALUES (
        v_patient_id,
        v_symptom_id,
        NOW(),
        'Mild',
        'Self-reported by patient via app'
    )
    ON CONFLICT (patient_id, symptom_id, date_reported) DO NOTHING;
    
    RAISE NOTICE '✅ Patient reported symptom: %', v_symptom_name;
END $$;


\echo ''
\echo 'STEP 9: Updated Medication Log'
\echo '----------------------------------------'

SELECT 
    m.med_name,
    ml.scheduled_time,
    ml.actual_taken_time,
    ml.status,
    CASE 
        WHEN ml.status = 'Taken' AND ml.actual_taken_time <= ml.scheduled_time + INTERVAL '1 hour'
        THEN '✅ On Time'
        WHEN ml.status = 'Taken' THEN '⏰ Late'
        WHEN ml.status = 'Missed' THEN '❌ Missed'
        WHEN ml.status = 'Skipped' THEN '⏭️ Skipped'
        ELSE '❓ Unknown'
    END AS adherence_status,
    ml.notes
FROM app.medication_log ml
JOIN app.medication m ON ml.medication_id = m.medication_id
WHERE ml.patient_id = (SELECT patient_id FROM app.patient LIMIT 1)
ORDER BY ml.scheduled_time DESC
LIMIT 10;

\echo ''
\echo '✅ Patient queries completed successfully!'