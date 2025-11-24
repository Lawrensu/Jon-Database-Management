-- PAKAR Tech Healthcare - Doctor Use Case Queries
-- COS 20031 Database Design Project
-- Author: Jason Hernando Kwee

SET search_path TO app, public;

\echo '========================================'
\echo '👨‍⚕️ Doctor Use Case Queries'
\echo '========================================'


\echo ''
\echo 'STEP 1: Doctor Profile'
\echo '----------------------------------------'

-- Get the first doctor who has assigned patients
WITH doctor_with_patients AS (
    SELECT DISTINCT p.doctor_id
    FROM app.patient p
    WHERE p.doctor_id IS NOT NULL
    LIMIT 1
)
SELECT 
    d.doctor_id,
    u.username,
    u.first_name || ' ' || u.last_name AS doctor_name,
    u.email,
    d.phone_num,
    d.specialisation,
    d.qualification,
    d.license_num,
    d.license_exp
FROM app.doctor d
JOIN app.user_account u ON d.user_id = u.user_id
WHERE d.doctor_id IN (SELECT doctor_id FROM doctor_with_patients);


\echo ''
\echo 'STEP 2: Assigned Patients'
\echo '----------------------------------------'

-- Get patients for the first doctor with patients
WITH selected_doctor AS (
    SELECT DISTINCT p.doctor_id
    FROM app.patient p
    WHERE p.doctor_id IS NOT NULL
    LIMIT 1
)
SELECT 
    p.patient_id,
    u.first_name || ' ' || u.last_name AS patient_name,
    u.email AS patient_email,
    p.phone_num AS patient_phone,
    p.birth_date,
    EXTRACT(YEAR FROM AGE(p.birth_date)) AS age,
    p.gender,
    p.emergency_contact_name,
    p.emergency_phone
FROM app.patient p
JOIN app.user_account u ON p.user_id = u.user_id
WHERE p.doctor_id IN (SELECT doctor_id FROM selected_doctor)
ORDER BY u.last_name, u.first_name;


\echo ''
\echo 'STEP 3: Patient Symptoms'
\echo '----------------------------------------'

-- Get symptoms for patients assigned to first doctor
WITH selected_doctor AS (
    SELECT DISTINCT p.doctor_id
    FROM app.patient p
    WHERE p.doctor_id IS NOT NULL
    LIMIT 1
)
SELECT 
    p.patient_id,
    u.first_name || ' ' || u.last_name AS patient_name,
    c.condition_name AS symptom_name,
    c.condition_desc AS symptom_description,
    ps.severity,
    ps.date_reported,
    ps.date_resolved,
    ps.notes
FROM app.patient_symptom ps
JOIN app.patient p ON ps.patient_id = p.patient_id
JOIN app.user_account u ON p.user_id = u.user_id
JOIN app.symptom s ON ps.symptom_id = s.symptom_id
JOIN app.condition c ON s.condition_id = c.condition_id
WHERE p.doctor_id IN (SELECT doctor_id FROM selected_doctor)
ORDER BY ps.date_reported DESC
LIMIT 10;


\echo ''
\echo 'STEP 4: Doctor Creates Prescription'
\echo '----------------------------------------'

DO $$
DECLARE
    new_prescription_id INT;
    v_patient_id INT;
    v_doctor_id INT;
    v_medication_id INT;
    v_prescription_version_id INT;
BEGIN
    -- Get first patient with assigned doctor
    SELECT patient_id, doctor_id INTO v_patient_id, v_doctor_id
    FROM app.patient
    WHERE doctor_id IS NOT NULL
    LIMIT 1;
    
    -- Check if we found a patient
    IF v_patient_id IS NULL THEN
        RAISE NOTICE '❌ No patients found with assigned doctors';
        RAISE NOTICE 'Run this first: npm run db:connect';
        RAISE NOTICE 'Then paste the assignment SQL from previous messages';
        RETURN;
    END IF;
    
    -- Get first medication
    SELECT medication_id INTO v_medication_id
    FROM app.medication
    LIMIT 1;
    
    -- Create prescription
    INSERT INTO app.prescription (patient_id, doctor_id, created_date, status, doctor_note)
    VALUES (
        v_patient_id,
        v_doctor_id,
        NOW(),
        'Active',
        'Test prescription created by doctor query'
    )
    RETURNING prescription_id INTO new_prescription_id;
    
    -- Add medication version
    INSERT INTO app.prescription_version (
        prescription_id,
        medication_id,
        titration,
        titration_unit,
        start_date,
        reason_for_change
    )
    VALUES (
        new_prescription_id,
        v_medication_id,
        500,
        'mg',
        NOW(),
        'Initial prescription for testing'
    )
    RETURNING prescription_version_id INTO v_prescription_version_id;
    
    -- Add medication schedule
    INSERT INTO app.medication_schedule (
        prescription_version_id,
        med_timing,
        frequency_times_per_day,
        frequency_interval_hours,
        duration,
        duration_unit
    )
    VALUES (
        v_prescription_version_id,
        'AfterMeal'::med_timing_enum,
        1,
        24,
        30,
        'Days'::duration_unit_enum
    );
    
    RAISE NOTICE '✅ Created prescription ID: %', new_prescription_id;
    RAISE NOTICE '✅ Patient ID: %, Doctor ID: %, Medication ID: %', 
        v_patient_id, v_doctor_id, v_medication_id;
    RAISE NOTICE '✅ Prescription version: %, Schedule added', v_prescription_version_id;
END $$;


\echo ''
\echo 'STEP 5: Assign Symptom to Patient'
\echo '----------------------------------------'

DO $$
DECLARE
    v_patient_id INT;
    v_symptom_id INT;
    v_patient_name TEXT;
    v_symptom_name TEXT;
BEGIN
    -- Get first patient with assigned doctor
    SELECT p.patient_id, u.first_name || ' ' || u.last_name INTO v_patient_id, v_patient_name
    FROM app.patient p
    JOIN app.user_account u ON p.user_id = u.user_id
    WHERE p.doctor_id IS NOT NULL
    LIMIT 1;
    
    -- Get first symptom
    SELECT s.symptom_id, c.condition_name INTO v_symptom_id, v_symptom_name
    FROM app.symptom s
    JOIN app.condition c ON s.condition_id = c.condition_id
    LIMIT 1;
    
    -- Assign symptom to patient
    INSERT INTO app.patient_symptom (patient_id, symptom_id, date_reported, severity, notes)
    VALUES (
        v_patient_id,
        v_symptom_id,
        NOW(),
        'Moderate',
        'Reported by doctor during consultation'
    )
    ON CONFLICT (patient_id, symptom_id, date_reported) DO NOTHING;
    
    RAISE NOTICE '✅ Assigned symptom "%" to patient "%"', v_symptom_name, v_patient_name;
END $$;


\echo ''
\echo 'STEP 6: Complete Prescription Workflow'
\echo '----------------------------------------'

DO $$
DECLARE
    v_prescription_id INT;
    v_prescription_version_id INT;
    v_medication_schedule_id INT;
    v_patient_id INT;
    v_doctor_id INT;
    v_medication_id INT;
BEGIN
    -- Get patient and doctor
    SELECT patient_id, doctor_id INTO v_patient_id, v_doctor_id
    FROM app.patient
    WHERE doctor_id IS NOT NULL
    LIMIT 1;
    
    -- Get medication
    SELECT medication_id INTO v_medication_id
    FROM app.medication
    LIMIT 1;
    
    -- Step 1: Create prescription
    INSERT INTO app.prescription (patient_id, doctor_id, created_date, status, doctor_note)
    VALUES (v_patient_id, v_doctor_id, NOW(), 'Active', 'Complete workflow test')
    RETURNING prescription_id INTO v_prescription_id;
    
    RAISE NOTICE '✅ Step 1: Created prescription ID: %', v_prescription_id;
    
    -- Step 2: Create prescription version
    INSERT INTO app.prescription_version (
        prescription_id,
        medication_id,
        titration,
        titration_unit,
        start_date,
        reason_for_change
    )
    VALUES (
        v_prescription_id,
        v_medication_id,
        500,
        'mg',
        NOW(),
        'Initial prescription'
    )
    RETURNING prescription_version_id INTO v_prescription_version_id;
    
    RAISE NOTICE '✅ Step 2: Created prescription version ID: %', v_prescription_version_id;
    
    -- Step 3: Create medication schedule
    INSERT INTO app.medication_schedule (
        prescription_version_id,
        med_timing,
        frequency_times_per_day,
        frequency_interval_hours,
        duration,
        duration_unit
    )
    VALUES (
        v_prescription_version_id,
        'AfterMeal',
        2,
        12,
        30,
        'Days'
    )
    RETURNING medication_schedule_id INTO v_medication_schedule_id;
    
    RAISE NOTICE '✅ Step 3: Created medication schedule ID: %', v_medication_schedule_id;
    
    -- Step 4: Create reminders (next 3 doses)
    INSERT INTO app.reminder (patient_id, medication_schedule_id, message, schedule)
    SELECT 
        v_patient_id,
        v_medication_schedule_id,
        'Time to take your medication!',
        NOW() + (g * INTERVAL '12 hours')
    FROM generate_series(1, 3) g;
    
    RAISE NOTICE '✅ Step 4: Created 3 reminders for patient';
    
    -- Step 5: Create initial medication log entries
    INSERT INTO app.medication_log (patient_id, medication_id, medication_schedule_id, scheduled_time, status, notes)
    SELECT 
        v_patient_id,
        v_medication_id,
        v_medication_schedule_id,
        NOW() + (g * INTERVAL '12 hours'),
        'Missed',
        'Auto-created log entry'
    FROM generate_series(0, 2) g;
    
    RAISE NOTICE '✅ Step 5: Created 3 medication log entries';
    RAISE NOTICE '========================================';
    RAISE NOTICE '✅ Complete workflow created successfully!';
END $$;


\echo ''
\echo 'STEP 7: Complete Prescription Details'
\echo '----------------------------------------'

WITH latest_prescription AS (
    SELECT prescription_id FROM app.prescription ORDER BY created_date DESC LIMIT 1
)
SELECT 
    pr.prescription_id,
    u_patient.first_name || ' ' || u_patient.last_name AS patient_name,
    u_doctor.first_name || ' ' || u_doctor.last_name AS doctor_name,
    m.med_name,
    pv.titration || ' ' || pv.titration_unit AS dosage,
    ms.med_timing,
    ms.frequency_times_per_day || ' times per day' AS frequency,
    ms.duration || ' ' || ms.duration_unit AS duration,
    pr.status,
    pr.created_date
FROM app.prescription pr
JOIN latest_prescription lp ON pr.prescription_id = lp.prescription_id
JOIN app.prescription_version pv ON pr.prescription_id = pv.prescription_id
JOIN app.medication_schedule ms ON pv.prescription_version_id = ms.prescription_version_id
JOIN app.patient p ON pr.patient_id = p.patient_id
JOIN app.user_account u_patient ON p.user_id = u_patient.user_id
JOIN app.doctor d ON pr.doctor_id = d.doctor_id
JOIN app.user_account u_doctor ON d.user_id = u_doctor.user_id
JOIN app.medication m ON pv.medication_id = m.medication_id
WHERE pv.end_date IS NULL;


\echo ''
\echo '============================================'
\echo '📊 SUMMARY REPORT'
\echo '============================================'

DO $$
DECLARE
    v_doctor_id INT;
    v_doctor_name TEXT;
    v_patient_count INT;
    v_prescription_count INT;
    v_symptom_count INT;
BEGIN
    -- Get selected doctor
    SELECT DISTINCT p.doctor_id INTO v_doctor_id
    FROM app.patient p
    WHERE p.doctor_id IS NOT NULL
    LIMIT 1;
    
    IF v_doctor_id IS NULL THEN
        RAISE NOTICE '❌ NO DATA: No patients assigned to doctors!';
        RAISE NOTICE '';
        RAISE NOTICE '🔧 FIX: Run patient-doctor assignment:';
        RAISE NOTICE '   npm run db:connect';
        RAISE NOTICE '   (then paste assignment SQL)';
        RETURN;
    END IF;
    
    -- Get doctor name
    SELECT u.first_name || ' ' || u.last_name INTO v_doctor_name
    FROM app.doctor d
    JOIN app.user_account u ON d.user_id = u.user_id
    WHERE d.doctor_id = v_doctor_id;
    
    -- Count patients
    SELECT COUNT(*) INTO v_patient_count
    FROM app.patient
    WHERE doctor_id = v_doctor_id;
    
    -- Count prescriptions
    SELECT COUNT(*) INTO v_prescription_count
    FROM app.prescription
    WHERE doctor_id = v_doctor_id;
    
    -- Count symptoms
    SELECT COUNT(*) INTO v_symptom_count
    FROM app.patient_symptom ps
    JOIN app.patient p ON ps.patient_id = p.patient_id
    WHERE p.doctor_id = v_doctor_id;
    
    RAISE NOTICE 'Doctor: % (ID: %)', v_doctor_name, v_doctor_id;
    RAISE NOTICE '----------------------------------------';
    RAISE NOTICE 'Assigned Patients: %', v_patient_count;
    RAISE NOTICE 'Active Prescriptions: %', v_prescription_count;
    RAISE NOTICE 'Reported Symptoms: %', v_symptom_count;
    RAISE NOTICE '========================================';
END $$;

\echo ''
\echo '✅ Doctor queries completed successfully!'