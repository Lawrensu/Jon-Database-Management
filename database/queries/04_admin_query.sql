-- PAKAR Tech Healthcare - Admin Use Case Queries
-- COS 20031 Database Design Project
-- Author: Jason Hernando Kwee

SET search_path TO app, public;

\echo '========================================'
\echo 'Admin Use Case Queries'
\echo '========================================'

\echo ''
\echo 'STEP 1: Assign Patient to Doctor'
\echo '----------------------------------------'

DO $$
DECLARE
    v_patient_id INT;
    v_doctor_id INT;
    v_patient_name TEXT;
    v_doctor_name TEXT;
BEGIN
    -- Get first unassigned patient
    SELECT p.patient_id, u.first_name || ' ' || u.last_name INTO v_patient_id, v_patient_name
    FROM app.patient p
    JOIN app.user_account u ON p.user_id = u.user_id
    WHERE p.doctor_id IS NULL
    LIMIT 1;
    
    -- Get first available doctor
    SELECT d.doctor_id, u.first_name || ' ' || u.last_name INTO v_doctor_id, v_doctor_name
    FROM app.doctor d
    JOIN app.user_account u ON d.user_id = u.user_id
    LIMIT 1;
    
    -- Assign patient to doctor
    IF v_patient_id IS NOT NULL AND v_doctor_id IS NOT NULL THEN
        UPDATE app.patient
        SET doctor_id = v_doctor_id
        WHERE patient_id = v_patient_id;
        
        RAISE NOTICE 'Assigned Patient: % (ID: %) to Doctor: % (ID: %)', 
            v_patient_name, v_patient_id, v_doctor_name, v_doctor_id;
    ELSE
        RAISE NOTICE 'No unassigned patients or no doctors available';
    END IF;
END $$;

\echo ''
\echo 'STEP 2: All Patient-Doctor Assignments'
\echo '----------------------------------------'

SELECT 
    p.patient_id,
    u_patient.first_name || ' ' || u_patient.last_name AS patient_name,
    d.doctor_id,
    u_doctor.first_name || ' ' || u_doctor.last_name AS doctor_name,
    d.specialisation,
    p.created_at AS assigned_date
FROM app.patient p
JOIN app.user_account u_patient ON p.user_id = u_patient.user_id
LEFT JOIN app.doctor d ON p.doctor_id = d.doctor_id
LEFT JOIN app.user_account u_doctor ON d.user_id = u_doctor.user_id
ORDER BY d.doctor_id, p.patient_id
LIMIT 20;

\echo ''
\echo 'STEP 3: Unassigned Patients'
\echo '----------------------------------------'

SELECT 
    p.patient_id,
    u.first_name || ' ' || u.last_name AS patient_name,
    u.email,
    p.phone_num,
    p.created_at AS registration_date
FROM app.patient p
JOIN app.user_account u ON p.user_id = u.user_id
WHERE p.doctor_id IS NULL
ORDER BY p.created_at DESC
LIMIT 10;


\echo ''
\echo 'STEP 4: Doctor Workload Distribution'
\echo '----------------------------------------'

SELECT 
    d.doctor_id,
    u.first_name || ' ' || u.last_name AS doctor_name,
    d.specialisation,
    COUNT(p.patient_id) AS assigned_patients,
    COUNT(CASE WHEN pr.status = 'Active' THEN 1 END) AS active_prescriptions,
    COUNT(DISTINCT ps.patient_symptom_id) AS reported_symptoms
FROM app.doctor d
JOIN app.user_account u ON d.user_id = u.user_id
LEFT JOIN app.patient p ON d.doctor_id = p.doctor_id
LEFT JOIN app.prescription pr ON d.doctor_id = pr.doctor_id
LEFT JOIN app.patient_symptom ps ON p.patient_id = ps.patient_id
GROUP BY d.doctor_id, u.first_name, u.last_name, d.specialisation
ORDER BY assigned_patients DESC;

\echo ''
\echo 'STEP 5: System Statistics'
\echo '----------------------------------------'

SELECT 
    'Total Users' AS category,
    COUNT(*) AS count
FROM app.user_account
UNION ALL
SELECT 'Patients', COUNT(*) FROM app.patient
UNION ALL
SELECT 'Doctors', COUNT(*) FROM app.doctor
UNION ALL
SELECT 'Admins', COUNT(*) FROM app.admin
UNION ALL
SELECT 'Super Admins', COUNT(*) FROM app.super_admin
UNION ALL
SELECT 'Active Prescriptions', COUNT(*) FROM app.prescription WHERE status = 'Active'
UNION ALL
SELECT 'Total Medications', COUNT(*) FROM app.medication
UNION ALL
SELECT 'Reported Symptoms', COUNT(*) FROM app.patient_symptom
UNION ALL
SELECT 'Medication Logs', COUNT(*) FROM app.medication_log;

\echo ''
\echo 'STEP 6: Encryption Coverage'
\echo '----------------------------------------'

SELECT * FROM app.v_encryption_status;

\echo ''
\echo 'STEP 7: Recent Activity (Last 24 Hours)'
\echo '----------------------------------------'

WITH recent_activity AS (
    SELECT 
        'Patient Registered' AS activity,
        u.username,
        p.created_at AS timestamp
    FROM app.patient p
    JOIN app.user_account u ON p.user_id = u.user_id
    WHERE p.created_at > NOW() - INTERVAL '24 hours'
    
    UNION ALL
    
    SELECT 
        'Prescription Created',
        u_patient.username,
        pr.created_date
    FROM app.prescription pr
    JOIN app.patient p ON pr.patient_id = p.patient_id
    JOIN app.user_account u_patient ON p.user_id = u_patient.user_id
    WHERE pr.created_date > NOW() - INTERVAL '24 hours'
    
    UNION ALL
    
    SELECT 
        'Symptom Reported',
        u.username,
        ps.date_reported
    FROM app.patient_symptom ps
    JOIN app.patient p ON ps.patient_id = p.patient_id
    JOIN app.user_account u ON p.user_id = u.user_id
    WHERE ps.date_reported > NOW() - INTERVAL '24 hours'
)
SELECT * FROM recent_activity
ORDER BY timestamp DESC
LIMIT 20;

\echo ''
\echo '============================================'
\echo 'ADMIN SUMMARY REPORT'
\echo '============================================'

DO $$
DECLARE
    v_total_patients INT;
    v_assigned_patients INT;
    v_unassigned_patients INT;
    v_total_doctors INT;
    v_active_prescriptions INT;
    v_encrypted_records INT;
BEGIN
    SELECT COUNT(*) INTO v_total_patients FROM app.patient;
    SELECT COUNT(*) INTO v_assigned_patients FROM app.patient WHERE doctor_id IS NOT NULL;
    SELECT COUNT(*) INTO v_unassigned_patients FROM app.patient WHERE doctor_id IS NULL;
    SELECT COUNT(*) INTO v_total_doctors FROM app.doctor;
    SELECT COUNT(*) INTO v_active_prescriptions FROM app.prescription WHERE status = 'Active';
    SELECT COUNT(*) INTO v_encrypted_records FROM app.patient WHERE address_encrypted IS NOT NULL;
    
    RAISE NOTICE 'System Overview';
    RAISE NOTICE '----------------------------------------';
    RAISE NOTICE 'Total Patients: %', v_total_patients;
    RAISE NOTICE '  Assigned: %', v_assigned_patients;
    RAISE NOTICE '  Unassigned: %', v_unassigned_patients;
    RAISE NOTICE 'Total Doctors: %', v_total_doctors;
    RAISE NOTICE 'Active Prescriptions: %', v_active_prescriptions;
    RAISE NOTICE 'Encrypted Patient Records: %', v_encrypted_records;
    RAISE NOTICE '========================================';
END $$;

\echo ''
\echo 'Admin queries completed successfully!'