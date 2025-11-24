-- PAKAR Tech Healthcare - Patient Use Case Queries
-- COS 20031 Database Design Project
-- Author: Jason Hernando Kwee

SET search_path TO app, public;

\echo '========================================'
\echo 'Patient Use Case Queries'
\echo '========================================'


\echo ''
\echo 'STEP 1: Patient Assigned Doctor'
\echo '----------------------------------------'

SELECT 
    p.patient_id,
    u_patient.first_name || ' ' || u_patient.last_name AS patient_name,
    u_patient.email AS patient_email,
    d.doctor_id,
    u_doctor.first_name || ' ' || u_doctor.last_name AS doctor_name,
    u_doctor.email AS doctor_email,
    d.specialisation,
    d.qualification,
    d.phone_num AS doctor_phone
FROM app.patient p
JOIN app.user_account u_patient ON p.user_id = u_patient.user_id
LEFT JOIN app.doctor d ON p.doctor_id = d.doctor_id
LEFT JOIN app.user_account u_doctor ON d.user_id = u_doctor.user_id
WHERE p.patient_id = 1  -- First patient
LIMIT 1;


\echo ''
\echo 'STEP 2: Patient Symptoms and Conditions'
\echo '----------------------------------------'

SELECT 
    ps.patient_symptom_id,
    c.condition_name AS symptom_name,
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
WHERE ps.patient_id = 1  -- First patient
ORDER BY ps.date_reported DESC
LIMIT 10;


\echo ''
\echo 'STEP 3: Patient Prescriptions'
\echo '----------------------------------------'

SELECT 
    pr.prescription_id,
    u_doctor.first_name || ' ' || u_doctor.last_name AS prescribed_by,
    m.med_name AS medication,
    m.med_brand_name AS brand,
    pv.titration || ' ' || pv.titration_unit AS dosage,
    pr.status,
    pr.created_date,
    pv.start_date,
    pv.end_date,
    pr.doctor_note
FROM app.prescription pr
JOIN app.prescription_version pv ON pr.prescription_id = pv.prescription_id
JOIN app.medication m ON pv.medication_id = m.medication_id
JOIN app.doctor d ON pr.doctor_id = d.doctor_id
JOIN app.user_account u_doctor ON d.user_id = u_doctor.user_id
WHERE pr.patient_id = 1  -- First patient
ORDER BY pr.created_date DESC
LIMIT 5;


\echo ''
\echo 'STEP 4: Prescription History with Changes'
\echo '----------------------------------------'

SELECT 
    pr.prescription_id,
    m.med_name,
    pv.titration || ' ' || pv.titration_unit AS dosage,
    pv.start_date,
    pv.end_date,
    CASE 
        WHEN pv.end_date IS NULL THEN 'Current'
        ELSE 'Past'
    END AS version_status,
    pv.reason_for_change
FROM app.prescription pr
JOIN app.prescription_version pv ON pr.prescription_id = pv.prescription_id
JOIN app.medication m ON pv.medication_id = m.medication_id
WHERE pr.patient_id = 1  -- First patient
ORDER BY pr.prescription_id, pv.start_date DESC
LIMIT 10;


\echo ''
\echo 'STEP 5: Medication Schedule'
\echo '----------------------------------------'

SELECT 
    m.med_name,
    pv.titration || ' ' || pv.titration_unit AS dosage,
    ms.med_timing,
    ms.frequency_times_per_day || ' times per day' AS frequency,
    'Every ' || ms.frequency_interval_hours || ' hours' AS interval,
    ms.duration || ' ' || ms.duration_unit AS duration,
    pv.start_date AS schedule_start,
    pr.status AS prescription_status
FROM app.prescription pr
JOIN app.prescription_version pv ON pr.prescription_id = pv.prescription_id
JOIN app.medication_schedule ms ON pv.prescription_version_id = ms.prescription_version_id
JOIN app.medication m ON pv.medication_id = m.medication_id
WHERE pr.patient_id = 1  -- First patient
  AND pr.status = 'Active'
  AND pv.end_date IS NULL
ORDER BY m.med_name;


\echo ''
\echo 'Auto-updating missed medications...'

-- Call the function to mark missed meds
SELECT app.mark_missed_medications();


\echo ''
\echo 'STEP 6: Medication Adherence Log'
\echo '----------------------------------------'

SELECT 
    m.med_name,
    ml.scheduled_time,
    ml.actual_taken_time,
    ml.status,
    CASE 
        WHEN ml.status = 'Taken' AND ml.actual_taken_time <= ml.scheduled_time + INTERVAL '1 hour'
        THEN 'On Time'
        WHEN ml.status = 'Taken' THEN 'Late'
        WHEN ml.status = 'Missed' THEN 'Missed'
        WHEN ml.status = 'Skipped' THEN 'Skipped'
        ELSE 'Unknown'
    END AS adherence_status,
    ml.notes
FROM app.medication_log ml
JOIN app.medication m ON ml.medication_id = m.medication_id
WHERE ml.patient_id = 1  -- First patient
ORDER BY ml.scheduled_time DESC
LIMIT 15;


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
            notes = 'Marked as taken by patient via app'
        WHERE medication_log_id = v_log_id;
        
        RAISE NOTICE 'Updated log ID % to status: Taken', v_log_id;
    ELSE
        RAISE NOTICE 'No missed logs found for patient';
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

    RAISE NOTICE 'Patient reported symptom: %', v_symptom_name;
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
        THEN 'On Time'
        WHEN ml.status = 'Taken' THEN 'Late'
        WHEN ml.status = 'Missed' THEN 'Missed'
        WHEN ml.status = 'Skipped' THEN 'Skipped'
        ELSE 'Unknown'
    END AS adherence_status,
    ml.notes
FROM app.medication_log ml
JOIN app.medication m ON ml.medication_id = m.medication_id
WHERE ml.patient_id = (SELECT patient_id FROM app.patient LIMIT 1)
ORDER BY ml.scheduled_time DESC
LIMIT 10;


-- ============================================================================
-- SUMMARY REPORT
-- ============================================================================

\echo ''
\echo '============================================'
\echo 'PATIENT SUMMARY REPORT'
\echo '============================================'

DO $$
DECLARE
    v_patient_name TEXT;
    v_doctor_name TEXT;
    v_active_prescriptions INT;
    v_total_medications INT;
    v_total_logs INT;
    v_taken_count INT;
    v_missed_count INT;
    v_adherence_rate NUMERIC;
BEGIN
    -- Get patient info
    SELECT u.first_name || ' ' || u.last_name INTO v_patient_name
    FROM app.patient p
    JOIN app.user_account u ON p.user_id = u.user_id
    WHERE p.patient_id = 1;
    
    -- Get doctor info
    SELECT u.first_name || ' ' || u.last_name INTO v_doctor_name
    FROM app.patient p
    JOIN app.doctor d ON p.doctor_id = d.doctor_id
    JOIN app.user_account u ON d.user_id = u.user_id
    WHERE p.patient_id = 1;
    
    -- Count active prescriptions
    SELECT COUNT(*) INTO v_active_prescriptions
    FROM app.prescription
    WHERE patient_id = 1 AND status = 'Active';
    
    -- Count medications
    SELECT COUNT(DISTINCT medication_id) INTO v_total_medications
    FROM app.medication_log
    WHERE patient_id = 1;
    
    -- Calculate adherence
    SELECT COUNT(*) INTO v_total_logs
    FROM app.medication_log
    WHERE patient_id = 1;
    
    SELECT COUNT(*) INTO v_taken_count
    FROM app.medication_log
    WHERE patient_id = 1 AND status = 'Taken';
    
    SELECT COUNT(*) INTO v_missed_count
    FROM app.medication_log
    WHERE patient_id = 1 AND status = 'Missed';
    
    v_adherence_rate := ROUND((v_taken_count * 100.0 / NULLIF(v_total_logs, 0)), 2);
    
    RAISE NOTICE 'Patient: % (ID: 1)', v_patient_name;
    RAISE NOTICE 'Doctor: %', COALESCE(v_doctor_name, 'Not Assigned');
    RAISE NOTICE '----------------------------------------';
    RAISE NOTICE 'Active Prescriptions: %', v_active_prescriptions;
    RAISE NOTICE 'Total Medications: %', v_total_medications;
    RAISE NOTICE 'Medication Logs: %', v_total_logs;
    RAISE NOTICE '  Taken: % (%%)', v_taken_count, v_adherence_rate;
    RAISE NOTICE '  Missed: %', v_missed_count;
    RAISE NOTICE '========================================';
END $$;

\echo ''
\echo 'Patient queries completed successfully!'