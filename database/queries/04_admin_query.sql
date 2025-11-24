-- PAKAR Tech Healthcare - Admin Use Case Queries
-- COS 20031 Database Design Project
-- Author: Jason Hernando Kwee

SET search_path TO app, public;

\echo '========================================'
\echo '👨‍💼 Admin Use Case Queries'
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
    SELECT patient_id, first_name || ' ' || last_name INTO v_patient_id, v_patient_name
    FROM app.patient p
    JOIN app.user_account u ON p.user_id = u.user_id
    WHERE p.doctor_id IS NULL
    LIMIT 1;
    
    -- Get first available doctor
    SELECT doctor_id, first_name || ' ' || last_name INTO v_doctor_id, v_doctor_name
    FROM app.doctor d
    JOIN app.user_account u ON d.user_id = u.user_id
    LIMIT 1;
    
    -- Assign patient to doctor
    IF v_patient_id IS NOT NULL AND v_doctor_id IS NOT NULL THEN
        UPDATE app.patient
        SET doctor_id = v_doctor_id
        WHERE patient_id = v_patient_id;
        
        RAISE NOTICE '✅ Assigned Patient: % (ID: %) to Doctor: % (ID: %)', 
            v_patient_name, v_patient_id, v_doctor_name, v_doctor_id;
    ELSE
        RAISE NOTICE '❌ No unassigned patients or no doctors available';
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
\echo '✅ Admin queries completed successfully!'