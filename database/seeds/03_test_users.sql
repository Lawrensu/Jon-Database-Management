-- PAKAR Tech Healthcare - Test Users Seed Data
-- COS 20031 Database Design Project

BEGIN;
SET search_path TO app, public;

-- ============================================================================
-- SECTION 1: Clean Up Existing Test Data
-- ============================================================================
DELETE FROM app.patient WHERE user_id IN (
    SELECT user_id FROM app.user_account WHERE email LIKE '%@pakartech.com'
);
DELETE FROM app.doctor WHERE user_id IN (
    SELECT user_id FROM app.user_account WHERE email LIKE '%@pakartech.com'
);
DELETE FROM app.admin WHERE user_id IN (
    SELECT user_id FROM app.user_account WHERE email LIKE '%@pakartech.com'
);
DELETE FROM app.super_admin WHERE user_id IN (
    SELECT user_id FROM app.user_account WHERE email LIKE '%@pakartech.com'
);
DELETE FROM app.user_account WHERE email LIKE '%@pakartech.com';

-- ============================================================================
-- SECTION 2: Create Test User Accounts
-- ============================================================================
INSERT INTO app.user_account (username, password, user_type, first_name, last_name, email, is_active) VALUES
('patient_test1', decode('2432612431302461626364656667686A6B6C6D6E6F707172737475767778797A', 'hex'), 'Patient', 'John', 'TestPatient', 'patient.test1@pakartech.com', TRUE),
('patient_test2', decode('2432612431302461626364656667686A6B6C6D6E6F707172737475767778797A', 'hex'), 'Patient', 'Mary', 'TestPatient', 'patient.test2@pakartech.com', TRUE),
('doctor_test1', decode('2432612431302461626364656667686A6B6C6D6E6F707172737475767778797A', 'hex'), 'Doctor', 'Sarah', 'Johnson', 'doctor.test1@pakartech.com', TRUE),
('doctor_test2', decode('2432612431302461626364656667686A6B6C6D6E6F707172737475767778797A', 'hex'), 'Doctor', 'Ahmad', 'Rahman', 'doctor.test2@pakartech.com', TRUE),
('admin_test1', decode('2432612431302461626364656667686A6B6C6D6E6F707172737475767778797A', 'hex'), 'Admin', 'Admin', 'TestUser', 'admin.test1@pakartech.com', TRUE);

-- ============================================================================
-- SECTION 3: Create Test Patients
-- ============================================================================
INSERT INTO app.patient (
    user_id, 
    phone_num, 
    birth_date, 
    gender, 
    address, 
    emergency_contact_name, 
    emergency_phone
)
SELECT 
    user_id,
    60123456789,
    '1985-03-15 00:00:00'::TIMESTAMP,
    'Male'::gender_enum,
    '123 Test Street, Kuala Lumpur',
    'Jane Doe',
    60198765432
FROM app.user_account 
WHERE email = 'patient.test1@pakartech.com';

INSERT INTO app.patient (
    user_id, 
    phone_num, 
    birth_date, 
    gender, 
    address, 
    emergency_contact_name, 
    emergency_phone
)
SELECT 
    user_id,
    60133334444,
    '1990-07-22 00:00:00'::TIMESTAMP,
    'Female'::gender_enum,
    '456 Sample Road, Penang',
    'Peter Smith',
    60177778888
FROM app.user_account 
WHERE email = 'patient.test2@pakartech.com';

-- ============================================================================
-- SECTION 4: Create Test Doctors
-- ============================================================================
INSERT INTO app.doctor (
    user_id, 
    phone_num, 
    license_num, 
    license_exp, 
    gender, 
    specialisation, 
    qualification, 
    clinical_inst
)
SELECT 
    user_id,
    60122223333,
    12345,
    '2030-12-31 23:59:59'::TIMESTAMP,
    'Female'::gender_enum,
    'General Practice',
    'MBBS, FRACGP',
    'Pakar Clinic KLCC'
FROM app.user_account 
WHERE email = 'doctor.test1@pakartech.com';

INSERT INTO app.doctor (
    user_id, 
    phone_num, 
    license_num, 
    license_exp, 
    gender, 
    specialisation, 
    qualification, 
    clinical_inst
)
SELECT 
    user_id,
    60144445555,
    67890,
    '2029-06-30 23:59:59'::TIMESTAMP,
    'Male'::gender_enum,
    'Internal Medicine',
    'MBBS, MRCP',
    'Pakar Medical Center JB'
FROM app.user_account 
WHERE email = 'doctor.test2@pakartech.com';

-- ============================================================================
-- SECTION 5: Create Test Admin
-- ============================================================================
INSERT INTO app.admin (user_id, username)
SELECT user_id, username
FROM app.user_account 
WHERE email = 'admin.test1@pakartech.com';

COMMIT;

-- ============================================================================
-- VERIFICATION REPORT
-- ============================================================================
\echo '============================================'
\echo '✅ Test Users Seed Data Loaded'
\echo '============================================'

SELECT 
    'User Accounts' AS table_name,
    COUNT(*) AS total_count,
    COUNT(*) FILTER (WHERE user_type = 'Patient') AS patients,
    COUNT(*) FILTER (WHERE user_type = 'Doctor') AS doctors,
    COUNT(*) FILTER (WHERE user_type = 'Admin') AS admins
FROM app.user_account 
WHERE email LIKE '%@pakartech.com';

SELECT 'Patients' AS table_name, COUNT(*) AS count
FROM app.patient 
WHERE user_id IN (SELECT user_id FROM app.user_account WHERE email LIKE '%@pakartech.com');

SELECT 'Doctors' AS table_name, COUNT(*) AS count
FROM app.doctor 
WHERE user_id IN (SELECT user_id FROM app.user_account WHERE email LIKE '%@pakartech.com');

SELECT 'Admins' AS table_name, COUNT(*) AS count
FROM app.admin 
WHERE user_id IN (SELECT user_id FROM app.user_account WHERE email LIKE '%@pakartech.com');

\echo ''
\echo 'Test Patients:'
SELECT 
    p.patient_id, 
    u.first_name || ' ' || u.last_name AS full_name,
    p.gender, 
    p.birth_date::DATE AS birth_date
FROM app.patient p
JOIN app.user_account u ON p.user_id = u.user_id
WHERE u.email LIKE '%@pakartech.com'
ORDER BY p.patient_id;

\echo ''
\echo 'Test Doctors:'
SELECT 
    d.doctor_id, 
    u.first_name || ' ' || u.last_name AS full_name,
    d.specialisation, 
    d.license_num,
    d.license_exp::DATE AS license_exp
FROM app.doctor d
JOIN app.user_account u ON d.user_id = u.user_id
WHERE u.email LIKE '%@pakartech.com'
ORDER BY d.doctor_id;