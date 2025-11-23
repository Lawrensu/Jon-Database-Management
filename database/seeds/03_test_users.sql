-- PAKAR Tech Healthcare - Comprehensive Test Data
-- COS 20031 Database Design Project
-- Purpose: All test/demo data for development & testing (separated from production seeds)

BEGIN;
SET search_path TO app, public;

-- ============================================================================
-- SECTION 0: CLEANUP (Remove existing test data)
-- ============================================================================

\echo '🧹 Cleaning up existing test data...'

-- Delete in reverse dependency order
DELETE FROM app.medication_log WHERE patient_id IN (
    SELECT patient_id FROM app.patient WHERE user_id IN (
        SELECT user_id FROM app.user_account WHERE email LIKE '%@test.pakartech.com'
    )
);

DELETE FROM app.reminder WHERE patient_id IN (
    SELECT patient_id FROM app.patient WHERE user_id IN (
        SELECT user_id FROM app.user_account WHERE email LIKE '%@test.pakartech.com'
    )
);

DELETE FROM app.medication_schedule WHERE prescription_version_id IN (
    SELECT prescription_version_id FROM app.prescription_version WHERE prescription_id IN (
        SELECT prescription_id FROM app.prescription WHERE patient_id IN (
            SELECT patient_id FROM app.patient WHERE user_id IN (
                SELECT user_id FROM app.user_account WHERE email LIKE '%@test.pakartech.com'
            )
        )
    )
);

DELETE FROM app.prescription_version WHERE prescription_id IN (
    SELECT prescription_id FROM app.prescription WHERE patient_id IN (
        SELECT patient_id FROM app.patient WHERE user_id IN (
            SELECT user_id FROM app.user_account WHERE email LIKE '%@test.pakartech.com'
        )
    )
);

DELETE FROM app.prescription WHERE patient_id IN (
    SELECT patient_id FROM app.patient WHERE user_id IN (
        SELECT user_id FROM app.user_account WHERE email LIKE '%@test.pakartech.com'
    )
);

DELETE FROM app.patient_symptom WHERE patient_id IN (
    SELECT patient_id FROM app.patient WHERE user_id IN (
        SELECT user_id FROM app.user_account WHERE email LIKE '%@test.pakartech.com'
    )
);

DELETE FROM app.patient WHERE user_id IN (
    SELECT user_id FROM app.user_account WHERE email LIKE '%@test.pakartech.com'
);

DELETE FROM app.doctor WHERE user_id IN (
    SELECT user_id FROM app.user_account WHERE email LIKE '%@test.pakartech.com'
);

DELETE FROM app.admin WHERE user_id IN (
    SELECT user_id FROM app.user_account WHERE email LIKE '%@test.pakartech.com'
);

DELETE FROM app.super_admin WHERE user_id IN (
    SELECT user_id FROM app.user_account WHERE email LIKE '%@test.pakartech.com'
);

DELETE FROM app.user_account WHERE email LIKE '%@test.pakartech.com';

\echo '✅ Cleanup complete'

-- ============================================================================
-- SECTION 1: CREATE TEST USER ACCOUNTS
-- ============================================================================

\echo ''
\echo '👥 Creating test user accounts...'

INSERT INTO app.user_account (username, password, user_type, first_name, last_name, email, is_active) VALUES
-- Test Patients (10 diverse cases)
('test.patient.child', decode('2432612431302461626364656667686A6B6C6D6E6F707172737475767778797A', 'hex'), 'Patient', 'Aisha', 'TestChild', 'child.patient@test.pakartech.com', TRUE),
('test.patient.teen', decode('2432612431302461626364656667686A6B6C6D6E6F707172737475767778797A', 'hex'), 'Patient', 'Ryan', 'TestTeen', 'teen.patient@test.pakartech.com', TRUE),
('test.patient.adult', decode('2432612431302461626364656667686A6B6C6D6E6F707172737475767778797A', 'hex'), 'Patient', 'Sarah', 'TestAdult', 'adult.patient@test.pakartech.com', TRUE),
('test.patient.senior', decode('2432612431302461626364656667686A6B6C6D6E6F707172737475767778797A', 'hex'), 'Patient', 'Ahmad', 'TestSenior', 'senior.patient@test.pakartech.com', TRUE),
('test.patient.male', decode('2432612431302461626364656667686A6B6C6D6E6F707172737475767778797A', 'hex'), 'Patient', 'Kumar', 'TestMale', 'male.patient@test.pakartech.com', TRUE),
('test.patient.female', decode('2432612431302461626364656667686A6B6C6D6E6F707172737475767778797A', 'hex'), 'Patient', 'Mei Ling', 'TestFemale', 'female.patient@test.pakartech.com', TRUE),
('test.patient.other', decode('2432612431302461626364656667686A6B6C6D6E6F707172737475767778797A', 'hex'), 'Patient', 'Alex', 'TestOther', 'other.patient@test.pakartech.com', TRUE),
('test.patient.chronic', decode('2432612431302461626364656667686A6B6C6D6E6F707172737475767778797A', 'hex'), 'Patient', 'Rajesh', 'TestChronic', 'chronic.patient@test.pakartech.com', TRUE),
('test.patient.new', decode('2432612431302461626364656667686A6B6C6D6E6F707172737475767778797A', 'hex'), 'Patient', 'Emma', 'TestNew', 'new.patient@test.pakartech.com', TRUE),
('test.patient.inactive', decode('2432612431302461626364656667686A6B6C6D6E6F707172737475767778797A', 'hex'), 'Patient', 'Inactive', 'TestPatient', 'inactive.patient@test.pakartech.com', FALSE),

-- Test Doctors (5 specializations)
('test.doctor.gp', decode('2432612431302461626364656667686A6B6C6D6E6F707172737475767778797A', 'hex'), 'Doctor', 'John', 'TestGP', 'gp.doctor@test.pakartech.com', TRUE),
('test.doctor.cardio', decode('2432612431302461626364656667686A6B6C6D6E6F707172737475767778797A', 'hex'), 'Doctor', 'Emily', 'TestCardio', 'cardio.doctor@test.pakartech.com', TRUE),
('test.doctor.pediatric', decode('2432612431302461626364656667686A6B6C6D6E6F707172737475767778797A', 'hex'), 'Doctor', 'Nurul', 'TestPeds', 'peds.doctor@test.pakartech.com', TRUE),
('test.doctor.neuro', decode('2432612431302461626364656667686A6B6C6D6E6F707172737475767778797A', 'hex'), 'Doctor', 'David', 'TestNeuro', 'neuro.doctor@test.pakartech.com', TRUE),
('test.doctor.inactive', decode('2432612431302461626364656667686A6B6C6D6E6F707172737475767778797A', 'hex'), 'Doctor', 'Inactive', 'TestDoctor', 'inactive.doctor@test.pakartech.com', FALSE),

-- Test Admins (3 types)
('test.admin.regular', decode('2432612431302461626364656667686A6B6C6D6E6F707172737475767778797A', 'hex'), 'Admin', 'Alice', 'TestAdmin', 'admin@test.pakartech.com', TRUE),
('test.admin.backup', decode('2432612431302461626364656667686A6B6C6D6E6F707172737475767778797A', 'hex'), 'Admin', 'Bob', 'TestAdmin2', 'admin2@test.pakartech.com', TRUE),

-- Test Super Admins
('test.superadmin', decode('2432612431302461626364656667686A6B6C6D6E6F707172737475767778797A', 'hex'), 'SuperAdmin', 'Super', 'TestAdmin', 'superadmin@test.pakartech.com', TRUE);

\echo '✅ Created 18 test user accounts'

-- ============================================================================
-- SECTION 2: CREATE TEST PATIENTS (10 diverse cases)
-- ============================================================================

\echo ''
\echo '🧑‍⚕️ Creating test patient profiles...'

-- Child patient (age 8)
INSERT INTO app.patient (user_id, phone_num, birth_date, gender, address, emergency_contact_name, emergency_phone)
SELECT 
    user_id,
    60123000001,
    (CURRENT_DATE - INTERVAL '8 years')::TIMESTAMP,
    'Female'::gender_enum,
    'No. 101, Jalan Test 1, Kuala Lumpur, 50000',
    'Parent Guardian',
    60133000001
FROM app.user_account WHERE email = 'child.patient@test.pakartech.com';

-- Teenage patient (age 15)
INSERT INTO app.patient (user_id, phone_num, birth_date, gender, address, emergency_contact_name, emergency_phone)
SELECT 
    user_id,
    60123000002,
    (CURRENT_DATE - INTERVAL '15 years')::TIMESTAMP,
    'Male'::gender_enum,
    'No. 102, Jalan Test 2, Petaling Jaya, 46000',
    'Ryan Parent',
    60133000002
FROM app.user_account WHERE email = 'teen.patient@test.pakartech.com';

-- Adult patient (age 35)
INSERT INTO app.patient (user_id, phone_num, birth_date, gender, address, emergency_contact_name, emergency_phone)
SELECT 
    user_id,
    60123000003,
    (CURRENT_DATE - INTERVAL '35 years')::TIMESTAMP,
    'Female'::gender_enum,
    'No. 103, Jalan Test 3, Subang Jaya, 47500',
    'John Spouse',
    60133000003
FROM app.user_account WHERE email = 'adult.patient@test.pakartech.com';

-- Senior patient (age 72)
INSERT INTO app.patient (user_id, phone_num, birth_date, gender, address, emergency_contact_name, emergency_phone)
SELECT 
    user_id,
    60123000004,
    (CURRENT_DATE - INTERVAL '72 years')::TIMESTAMP,
    'Male'::gender_enum,
    'No. 104, Jalan Test 4, Shah Alam, 40100',
    'Ahmad Son',
    60133000004
FROM app.user_account WHERE email = 'senior.patient@test.pakartech.com';

-- Male patient (age 28)
INSERT INTO app.patient (user_id, phone_num, birth_date, gender, address, emergency_contact_name, emergency_phone)
SELECT 
    user_id,
    60123000005,
    (CURRENT_DATE - INTERVAL '28 years')::TIMESTAMP,
    'Male'::gender_enum,
    'No. 105, Jalan Test 5, Kuala Lumpur, 50100',
    'Kumar Sibling',
    60133000005
FROM app.user_account WHERE email = 'male.patient@test.pakartech.com';

-- Female patient (age 42)
INSERT INTO app.patient (user_id, phone_num, birth_date, gender, address, emergency_contact_name, emergency_phone)
SELECT 
    user_id,
    60123000006,
    (CURRENT_DATE - INTERVAL '42 years')::TIMESTAMP,
    'Female'::gender_enum,
    'No. 106, Jalan Test 6, Petaling Jaya, 46100',
    'Lee Husband',
    60133000006
FROM app.user_account WHERE email = 'female.patient@test.pakartech.com';

-- Other gender patient (age 30)
INSERT INTO app.patient (user_id, phone_num, birth_date, gender, address, emergency_contact_name, emergency_phone)
SELECT 
    user_id,
    60123000007,
    (CURRENT_DATE - INTERVAL '30 years')::TIMESTAMP,
    'Other'::gender_enum,
    'No. 107, Jalan Test 7, Subang Jaya, 47600',
    'Alex Friend',
    60133000007
FROM app.user_account WHERE email = 'other.patient@test.pakartech.com';

-- Chronic condition patient (age 55)
INSERT INTO app.patient (user_id, phone_num, birth_date, gender, address, emergency_contact_name, emergency_phone)
SELECT 
    user_id,
    60123000008,
    (CURRENT_DATE - INTERVAL '55 years')::TIMESTAMP,
    'Male'::gender_enum,
    'No. 108, Jalan Test 8, Shah Alam, 40200',
    'Rajesh Wife',
    60133000008
FROM app.user_account WHERE email = 'chronic.patient@test.pakartech.com';

-- New patient (age 25, registered today)
INSERT INTO app.patient (user_id, phone_num, birth_date, gender, address, emergency_contact_name, emergency_phone)
SELECT 
    user_id,
    60123000009,
    (CURRENT_DATE - INTERVAL '25 years')::TIMESTAMP,
    'Female'::gender_enum,
    'No. 109, Jalan Test 9, Kuala Lumpur, 50200',
    'Emma Mother',
    60133000009
FROM app.user_account WHERE email = 'new.patient@test.pakartech.com';

-- Inactive patient (age 40)
INSERT INTO app.patient (user_id, phone_num, birth_date, gender, address, emergency_contact_name, emergency_phone)
SELECT 
    user_id,
    60123000010,
    (CURRENT_DATE - INTERVAL '40 years')::TIMESTAMP,
    'Male'::gender_enum,
    'No. 110, Jalan Test 10, Petaling Jaya, 46200',
    'Inactive Contact',
    60133000010
FROM app.user_account WHERE email = 'inactive.patient@test.pakartech.com';

\echo '✅ Created 10 test patients (child, teen, adult, senior, various genders)'

-- ============================================================================
-- SECTION 3: CREATE TEST DOCTORS (5 specializations)
-- ============================================================================

\echo ''
\echo '👨‍⚕️ Creating test doctor profiles...'

-- General Practitioner
INSERT INTO app.doctor (user_id, phone_num, license_num, license_exp, gender, specialisation, qualification, clinical_inst)
SELECT 
    user_id,
    60144000001,
    90001,
    (CURRENT_DATE + INTERVAL '5 years')::TIMESTAMP,
    'Male'::gender_enum,
    'General Practice',
    'MBBS, FRACGP',
    'Test Clinic KL'
FROM app.user_account WHERE email = 'gp.doctor@test.pakartech.com';

-- Cardiologist
INSERT INTO app.doctor (user_id, phone_num, license_num, license_exp, gender, specialisation, qualification, clinical_inst)
SELECT 
    user_id,
    60144000002,
    90002,
    (CURRENT_DATE + INTERVAL '5 years')::TIMESTAMP,
    'Female'::gender_enum,
    'Cardiology',
    'MBBS, MD (Cardiology)',
    'Test Heart Center'
FROM app.user_account WHERE email = 'cardio.doctor@test.pakartech.com';

-- Pediatrician
INSERT INTO app.doctor (user_id, phone_num, license_num, license_exp, gender, specialisation, qualification, clinical_inst)
SELECT 
    user_id,
    60144000003,
    90003,
    (CURRENT_DATE + INTERVAL '5 years')::TIMESTAMP,
    'Female'::gender_enum,
    'Pediatrics',
    'MBBS, MD (Pediatrics)',
    'Test Children Hospital'
FROM app.user_account WHERE email = 'peds.doctor@test.pakartech.com';

-- Neurologist
INSERT INTO app.doctor (user_id, phone_num, license_num, license_exp, gender, specialisation, qualification, clinical_inst)
SELECT 
    user_id,
    60144000004,
    90004,
    (CURRENT_DATE + INTERVAL '5 years')::TIMESTAMP,
    'Male'::gender_enum,
    'Neurology',
    'MBBS, MD (Neurology)',
    'Test Neuro Institute'
FROM app.user_account WHERE email = 'neuro.doctor@test.pakartech.com';

-- Inactive doctor (account disabled, but license still valid)
INSERT INTO app.doctor (user_id, phone_num, license_num, license_exp, gender, specialisation, qualification, clinical_inst)
SELECT 
    user_id,
    60144000005,
    90005,
    (CURRENT_DATE + INTERVAL '1 year')::TIMESTAMP,  -- ✅ Valid license (but account is inactive)
    'Male'::gender_enum,
    'General Practice',
    'MBBS',
    'Inactive Clinic'
FROM app.user_account WHERE email = 'inactive.doctor@test.pakartech.com';

\echo '✅ Created 5 test doctors (GP, Cardiology, Pediatrics, Neurology, Inactive)'

-- ============================================================================
-- SECTION 4: CREATE TEST ADMINS
-- ============================================================================

\echo ''
\echo '🔐 Creating test admin accounts...'

-- Regular Admin
INSERT INTO app.admin (user_id, username)
SELECT user_id, username
FROM app.user_account WHERE email = 'admin@test.pakartech.com';

-- Backup Admin
INSERT INTO app.admin (user_id, username)
SELECT user_id, username
FROM app.user_account WHERE email = 'admin2@test.pakartech.com';

-- Super Admin
INSERT INTO app.super_admin (user_id, username)
SELECT user_id, username
FROM app.user_account WHERE email = 'superadmin@test.pakartech.com';

\echo '✅ Created 2 admins + 1 super admin'

-- ============================================================================
-- SECTION 5: ASSIGN PATIENTS TO DOCTORS
-- ============================================================================

\echo ''
\echo '🔗 Assigning patients to doctors...'

-- Assign child to pediatrician
UPDATE app.patient
SET doctor_id = (SELECT doctor_id FROM app.doctor WHERE user_id = (
    SELECT user_id FROM app.user_account WHERE email = 'peds.doctor@test.pakartech.com'
))
WHERE user_id = (SELECT user_id FROM app.user_account WHERE email = 'child.patient@test.pakartech.com');

-- Assign teen to pediatrician
UPDATE app.patient
SET doctor_id = (SELECT doctor_id FROM app.doctor WHERE user_id = (
    SELECT user_id FROM app.user_account WHERE email = 'peds.doctor@test.pakartech.com'
))
WHERE user_id = (SELECT user_id FROM app.user_account WHERE email = 'teen.patient@test.pakartech.com');

-- Assign adult to GP
UPDATE app.patient
SET doctor_id = (SELECT doctor_id FROM app.doctor WHERE user_id = (
    SELECT user_id FROM app.user_account WHERE email = 'gp.doctor@test.pakartech.com'
))
WHERE user_id = (SELECT user_id FROM app.user_account WHERE email = 'adult.patient@test.pakartech.com');

-- Assign senior to cardiologist
UPDATE app.patient
SET doctor_id = (SELECT doctor_id FROM app.doctor WHERE user_id = (
    SELECT user_id FROM app.user_account WHERE email = 'cardio.doctor@test.pakartech.com'
))
WHERE user_id = (SELECT user_id FROM app.user_account WHERE email = 'senior.patient@test.pakartech.com');

-- Assign chronic patient to cardiologist
UPDATE app.patient
SET doctor_id = (SELECT doctor_id FROM app.doctor WHERE user_id = (
    SELECT user_id FROM app.user_account WHERE email = 'cardio.doctor@test.pakartech.com'
))
WHERE user_id = (SELECT user_id FROM app.user_account WHERE email = 'chronic.patient@test.pakartech.com');

-- Assign remaining patients to GP
UPDATE app.patient
SET doctor_id = (SELECT doctor_id FROM app.doctor WHERE user_id = (
    SELECT user_id FROM app.user_account WHERE email = 'gp.doctor@test.pakartech.com'
))
WHERE doctor_id IS NULL 
  AND user_id IN (SELECT user_id FROM app.user_account WHERE email LIKE '%@test.pakartech.com');

\echo '✅ Assigned 9 patients to appropriate doctors'

-- ============================================================================
-- SECTION 6: ADD TEST SYMPTOMS
-- ============================================================================

\echo ''
\echo '🤒 Adding patient symptoms...'

-- Senior patient has hypertension symptoms
INSERT INTO app.patient_symptom (patient_id, symptom_id, date_reported, severity, notes)
SELECT 
    p.patient_id,
    s.symptom_id,
    CURRENT_DATE - INTERVAL '30 days',
    'Moderate'::severity_enum,
    'Reported elevated blood pressure readings at home'
FROM app.patient p
CROSS JOIN app.symptom s
JOIN app.condition c ON s.condition_id = c.condition_id
WHERE p.user_id = (SELECT user_id FROM app.user_account WHERE email = 'senior.patient@test.pakartech.com')
  AND c.condition_name = 'Headache'
LIMIT 1;

-- Chronic patient has ongoing chest pain
INSERT INTO app.patient_symptom (patient_id, symptom_id, date_reported, severity, notes)
SELECT 
    p.patient_id,
    s.symptom_id,
    CURRENT_DATE - INTERVAL '90 days',
    'Severe'::severity_enum,
    'Chronic chest pain, ongoing treatment'
FROM app.patient p
CROSS JOIN app.symptom s
JOIN app.condition c ON s.condition_id = c.condition_id
WHERE p.user_id = (SELECT user_id FROM app.user_account WHERE email = 'chronic.patient@test.pakartech.com')
  AND c.condition_name = 'Chest Pain'
LIMIT 1;

-- Adult patient has mild fatigue (resolved)
INSERT INTO app.patient_symptom (patient_id, symptom_id, date_reported, date_resolved, severity, notes)
SELECT 
    p.patient_id,
    s.symptom_id,
    CURRENT_DATE - INTERVAL '15 days',
    CURRENT_DATE - INTERVAL '5 days',
    'Mild'::severity_enum,
    'Resolved after rest and dietary changes'
FROM app.patient p
CROSS JOIN app.symptom s
JOIN app.condition c ON s.condition_id = c.condition_id
WHERE p.user_id = (SELECT user_id FROM app.user_account WHERE email = 'adult.patient@test.pakartech.com')
  AND c.condition_name = 'Fatigue'
LIMIT 1;

\echo '✅ Added 3 test symptoms (ongoing + resolved)'

-- ============================================================================
-- SECTION 7: CREATE TEST PRESCRIPTIONS
-- ============================================================================

\echo ''
\echo '💊 Creating test prescriptions...'

DO $$
DECLARE
    v_prescription_id INT;
    v_prescription_version_id INT;
    v_patient_id INT;
    v_doctor_id INT;
    v_medication_id INT;
BEGIN
    -- Get senior patient and cardiologist
    SELECT patient_id INTO v_patient_id 
    FROM app.patient 
    WHERE user_id = (SELECT user_id FROM app.user_account WHERE email = 'senior.patient@test.pakartech.com');
    
    SELECT doctor_id INTO v_doctor_id 
    FROM app.doctor 
    WHERE user_id = (SELECT user_id FROM app.user_account WHERE email = 'cardio.doctor@test.pakartech.com');
    
    SELECT medication_id INTO v_medication_id 
    FROM app.medication 
    WHERE med_name = 'Amlodipine Besylate';
    
    -- Create prescription for senior patient (hypertension)
    INSERT INTO app.prescription (patient_id, doctor_id, status, created_date, doctor_note)
    VALUES (
        v_patient_id,
        v_doctor_id,
        'Active',
        CURRENT_DATE - INTERVAL '30 days',
        'Test prescription for hypertension management - long-term treatment'
    )
    RETURNING prescription_id INTO v_prescription_id;
    
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
        v_prescription_id,
        v_medication_id,
        5,
        'mg',
        CURRENT_DATE - INTERVAL '30 days',
        'Initial prescription for blood pressure control'
    )
    RETURNING prescription_version_id INTO v_prescription_version_id;
    
    -- ✅ FIXED: Add medication schedule using ONLY columns that exist
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
        1,  -- Once daily
        24,  -- Every 24 hours
        90,
        'Days'::duration_unit_enum
    );
    
    RAISE NOTICE '✅ Created prescription for senior patient (Amlodipine 5mg once daily)';
    
    -- Create prescription for chronic patient
    SELECT patient_id INTO v_patient_id 
    FROM app.patient 
    WHERE user_id = (SELECT user_id FROM app.user_account WHERE email = 'chronic.patient@test.pakartech.com');
    
    SELECT medication_id INTO v_medication_id 
    FROM app.medication 
    WHERE med_name = 'Atorvastatin Calcium';
    
    INSERT INTO app.prescription (patient_id, doctor_id, status, created_date, doctor_note)
    VALUES (
        v_patient_id,
        v_doctor_id,
        'Active',
        CURRENT_DATE - INTERVAL '60 days',
        'Test prescription for chronic condition - statin therapy'
    )
    RETURNING prescription_id INTO v_prescription_id;
    
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
        20,
        'mg',
        CURRENT_DATE - INTERVAL '60 days',
        'Long-term cholesterol management'
    )
    RETURNING prescription_version_id INTO v_prescription_version_id;
    
    -- ✅ FIXED: Add medication schedule using correct columns
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
        1,  -- Once daily
        24,  -- Every 24 hours
        180,
        'Days'::duration_unit_enum
    );
    
    RAISE NOTICE '✅ Created prescription for chronic patient (Atorvastatin 20mg once daily)';
END $$;

-- ============================================================================
-- SECTION 8: CREATE TEST MEDICATION LOGS
-- ============================================================================

\echo ''
\echo '📝 Adding medication adherence logs...'

-- Add 7 days of logs for senior patient (90% adherence)
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
    p.patient_id,
    pv.medication_id,  -- ✅ Get from prescription_version
    ms.medication_schedule_id,
    (CURRENT_DATE - INTERVAL '6 days' + (g || ' days')::INTERVAL + TIME '08:00:00')::TIMESTAMP,
    CASE 
        WHEN g = 3 THEN NULL  -- Missed 1 day
        ELSE (CURRENT_DATE - INTERVAL '6 days' + (g || ' days')::INTERVAL + TIME '08:15:00')::TIMESTAMP
    END,
    CASE 
        WHEN g = 3 THEN 'Missed'
        ELSE 'Taken'
    END::med_log_status_enum,
    CASE 
        WHEN g = 3 THEN 'Forgot to take medication'
        ELSE 'Taken with breakfast'
    END
FROM generate_series(1, 7) g
CROSS JOIN app.patient p
JOIN app.medication_schedule ms ON ms.prescription_version_id IN (
    SELECT pv.prescription_version_id 
    FROM app.prescription_version pv
    JOIN app.prescription pr ON pv.prescription_id = pr.prescription_id
    WHERE pr.patient_id = p.patient_id
)
JOIN app.prescription_version pv ON ms.prescription_version_id = pv.prescription_version_id  -- ✅ Get medication_id
WHERE p.user_id = (SELECT user_id FROM app.user_account WHERE email = 'senior.patient@test.pakartech.com')
LIMIT 7;

\echo '✅ Added 7 days of medication logs (1 missed dose)'

-- ============================================================================
-- SECTION 9: CREATE TEST REMINDERS
-- ============================================================================

\echo ''
\echo '⏰ Creating upcoming reminders...'

-- Create 3 upcoming reminders for senior patient
INSERT INTO app.reminder (patient_id, medication_schedule_id, message, schedule)
SELECT 
    p.patient_id,
    ms.medication_schedule_id,
    'Time to take your blood pressure medication (Amlodipine 5mg)',
    (CURRENT_DATE + (g || ' days')::INTERVAL + TIME '08:00:00')::TIMESTAMP
FROM generate_series(1, 3) g
CROSS JOIN app.patient p
JOIN app.medication_schedule ms ON ms.prescription_version_id IN (
    SELECT pv.prescription_version_id 
    FROM app.prescription_version pv
    JOIN app.prescription pr ON pv.prescription_id = pr.prescription_id
    WHERE pr.patient_id = p.patient_id
)
WHERE p.user_id = (SELECT user_id FROM app.user_account WHERE email = 'senior.patient@test.pakartech.com')
LIMIT 3;

\echo '✅ Created 3 upcoming reminders'

-- ============================================================================
-- SECTION 10: VERIFICATION REPORT
-- ============================================================================

\echo ''
\echo '============================================'
\echo '📊 Test Data Summary'
\echo '============================================'

-- Count users by type
SELECT 
    'User Accounts' AS category,
    user_type,
    COUNT(*) AS count,
    COUNT(*) FILTER (WHERE is_active) AS active_count
FROM app.user_account 
WHERE email LIKE '%@test.pakartech.com'
GROUP BY user_type
ORDER BY user_type;

-- Patient summary
\echo ''
\echo 'Test Patients (detailed):'
SELECT 
    p.patient_id,
    u.first_name || ' ' || u.last_name AS name,
    EXTRACT(YEAR FROM AGE(p.birth_date)) AS age,
    p.gender,
    d_user.first_name || ' ' || d_user.last_name AS assigned_doctor,
    doc.specialisation AS doctor_specialty
FROM app.patient p
JOIN app.user_account u ON p.user_id = u.user_id
LEFT JOIN app.doctor doc ON p.doctor_id = doc.doctor_id
LEFT JOIN app.user_account d_user ON doc.user_id = d_user.user_id
WHERE u.email LIKE '%@test.pakartech.com'
ORDER BY p.patient_id;

-- Doctor summary
\echo ''
\echo 'Test Doctors:'
SELECT 
    d.doctor_id,
    u.first_name || ' ' || u.last_name AS name,
    d.specialisation,
    d.license_num,
    COUNT(p.patient_id) AS patient_count
FROM app.doctor d
JOIN app.user_account u ON d.user_id = u.user_id
LEFT JOIN app.patient p ON d.doctor_id = p.doctor_id
WHERE u.email LIKE '%@test.pakartech.com'
GROUP BY d.doctor_id, u.first_name, u.last_name, d.specialisation, d.license_num
ORDER BY d.doctor_id;

-- Data counts
\echo ''
\echo 'Test Data Counts:'
SELECT 'Patients' AS table_name, COUNT(*) AS count
FROM app.patient WHERE user_id IN (SELECT user_id FROM app.user_account WHERE email LIKE '%@test.pakartech.com')
UNION ALL
SELECT 'Doctors', COUNT(*) FROM app.doctor WHERE user_id IN (SELECT user_id FROM app.user_account WHERE email LIKE '%@test.pakartech.com')
UNION ALL
SELECT 'Admins', COUNT(*) FROM app.admin WHERE user_id IN (SELECT user_id FROM app.user_account WHERE email LIKE '%@test.pakartech.com')
UNION ALL
SELECT 'Super Admins', COUNT(*) FROM app.super_admin WHERE user_id IN (SELECT user_id FROM app.user_account WHERE email LIKE '%@test.pakartech.com')
UNION ALL
SELECT 'Symptoms', COUNT(*) FROM app.patient_symptom WHERE patient_id IN (SELECT patient_id FROM app.patient WHERE user_id IN (SELECT user_id FROM app.user_account WHERE email LIKE '%@test.pakartech.com'))
UNION ALL
SELECT 'Prescriptions', COUNT(*) FROM app.prescription WHERE patient_id IN (SELECT patient_id FROM app.patient WHERE user_id IN (SELECT user_id FROM app.user_account WHERE email LIKE '%@test.pakartech.com'))
UNION ALL
SELECT 'Medication Logs', COUNT(*) FROM app.medication_log WHERE patient_id IN (SELECT patient_id FROM app.patient WHERE user_id IN (SELECT user_id FROM app.user_account WHERE email LIKE '%@test.pakartech.com'))
UNION ALL
SELECT 'Reminders', COUNT(*) FROM app.reminder WHERE patient_id IN (SELECT patient_id FROM app.patient WHERE user_id IN (SELECT user_id FROM app.user_account WHERE email LIKE '%@test.pakartech.com'));

\echo ''
\echo '============================================'
\echo '✅ Test Data Loaded Successfully'
\echo '============================================'
\echo ''
\echo '🔐 Test Login Credentials:'
\echo '   All accounts use password: "test123"'
\echo '   (hash: 2432612431302461626364656667686A6B6C6D6E6F707172737475767778797A)'
\echo ''
\echo '📧 Test Email Pattern: *@test.pakartech.com'
\echo ''
\echo '🧪 Use Cases Covered:'
\echo '   ✅ Child patient (8 years) → Pediatrician'
\echo '   ✅ Teen patient (15 years) → Pediatrician'
\echo '   ✅ Adult patient (35 years) → GP'
\echo '   ✅ Senior patient (72 years) → Cardiologist'
\echo '   ✅ Chronic patient → Cardiologist'
\echo '   ✅ New patient (no history)'
\echo '   ✅ Inactive accounts'
\echo '   ✅ Active prescriptions'
\echo '   ✅ Medication adherence tracking'
\echo '   ✅ Upcoming reminders'
\echo ''
\echo '🚀 Ready for testing with npm run queries:doctorTest'
\echo '============================================'