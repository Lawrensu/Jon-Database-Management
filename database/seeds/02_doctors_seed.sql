-- PAKAR Tech Healthcare - Doctor Sample Data
-- COS 20031 Database Design Project
-- Author: [Cherylynn]

SET search_path TO app, public;

BEGIN;

-- ============================================================================
-- STEP 1: CREATE USER ACCOUNTS FOR DOCTORS
-- ============================================================================

WITH doctor_data AS (
  SELECT * FROM (VALUES
    ('Rajesh', 'Menon', 'dr.rajesh.menon@pakartech.com', 'Male', 60122345001, 1, 'MBBS, MD (Cardiology)', 'Cardiologist', '2010-03-15'::timestamp),
    ('Amira', 'Hassan', 'dr.amira.hassan@pakartech.com', 'Female', 60122345002, 2, 'MBBS, MD (Pediatrics)', 'Pediatrician', '2012-09-01'::timestamp),
    ('Lim', 'Wei Chong', 'dr.lim.wei.chong@pakartech.com', 'Male', 60122345003, 3, 'MBBS', 'General Practitioner', '2018-01-10'::timestamp),
    ('Suresh', 'Nair', 'dr.suresh.nair@pakartech.com', 'Male', 60122345004, 4, 'MBBS, MS (Orthopedics)', 'Orthopedic Surgeon', '2009-06-20'::timestamp),
    ('Tan', 'Siew Ling', 'dr.tan.siew.ling@pakartech.com', 'Female', 60122345005, 5, 'MBBS, DDerm', 'Dermatologist', '2014-11-05'::timestamp),
    ('Farid', 'Ismail', 'dr.farid.ismail@pakartech.com', 'Male', 60122345006, 6, 'MBBS, MD (Neurology)', 'Neurologist', '2008-02-28'::timestamp),
    ('Nurul', 'Aziz', 'dr.nurul.aziz@pakartech.com', 'Female', 60122345007, 7, 'MBBS', 'General Practitioner', '2020-05-12'::timestamp),
    ('David', 'Tan', 'dr.david.tan@pakartech.com', 'Male', 60122345008, 8, 'MBBS, MD (Cardiology)', 'Cardiologist', '2016-07-01'::timestamp),
    ('Aisha', 'Rahim', 'dr.aisha.rahim@pakartech.com', 'Female', 60122345009, 9, 'MBBS, MD (OBGYN)', 'Obstetrician/Gynecologist', '2013-04-10'::timestamp),
    ('Hannah', 'Lee', 'dr.hannah.lee@pakartech.com', 'Female', 60122345010, 10, 'MBBS, MRCEM', 'Emergency Medicine', '2019-10-01'::timestamp),
    ('Chong', 'Ming', 'dr.chong.ming@pakartech.com', 'Male', 60122345011, 11, 'MBBS, MMed (Pediatrics)', 'Pediatrician', '2015-08-15'::timestamp),
    ('Mohd', 'Azlan', 'dr.mohd.azlan@pakartech.com', 'Male', 60122345012, 12, 'MBBS', 'General Practitioner', '2021-01-20'::timestamp),
    ('Priya', 'Menon', 'dr.priya.menon@pakartech.com', 'Female', 60122345013, 13, 'MBBS, MS (Orthopedics)', 'Orthopedic Surgeon', '2012-12-01'::timestamp),
    ('Wong', 'Liang', 'dr.wong.liang@pakartech.com', 'Female', 60122345014, 14, 'MBBS, DDerm', 'Dermatologist', '2017-03-25'::timestamp),
    ('Siti', 'Noor', 'dr.siti.noor@pakartech.com', 'Female', 60122345015, 15, 'MBBS, MD (Neurology)', 'Neurologist', '2011-09-05'::timestamp),
    ('Leong', 'May', 'dr.leong.may@pakartech.com', 'Female', 60122345016, 16, 'MBBS, MOG (Obstetrics & Gyn)', 'Obstetrician/Gynecologist', '2014-06-30'::timestamp),
    ('Rakesh', 'Singh', 'dr.rakesh.singh@pakartech.com', 'Male', 60122345017, 17, 'MBBS, MRCEM', 'Emergency Medicine', '2016-11-10'::timestamp),
    ('Jason', 'Tan', 'dr.jason.tan@pakartech.com', 'Male', 60122345018, 18, 'MBBS', 'General Practitioner', '2022-04-01'::timestamp),
    ('Elena', 'Gomez', 'dr.elena.gomez@pakartech.com', 'Female', 60122345019, 19, 'MBBS, MD (Cardiology)', 'Cardiologist', '2005-02-07'::timestamp),
    ('Nur', 'Laila', 'dr.nur.laila@pakartech.com', 'Female', 60122345020, 20, 'MBBS, MMed (Pediatrics)', 'Pediatrician', '2019-02-01'::timestamp)
  ) AS t(first_name, last_name, email, gender, phone_num, license_num, qualification, specialisation, created_at)
),
doctor_data_with_id AS (
  SELECT 
    'D' || LPAD(license_num::text, 6, '0') AS user_id,
    *
  FROM doctor_data
),
user_inserts AS (
  INSERT INTO app.user_account (
    user_id,
    username, 
    password_hash, 
    user_type, 
    is_active, 
    created_at
  )
  SELECT
    user_id,
    LOWER(REPLACE(email, '@pakartech.com', '')) AS username,
    '$2a$10$abcdefghijklmnopqrstuv' AS password_hash,
    'Doctor' AS user_type,
    TRUE AS is_active,
    created_at
  FROM doctor_data_with_id
  ON CONFLICT (username) DO NOTHING
  RETURNING id, username
)
-- ============================================================================
-- STEP 2: INSERT DOCTORS
-- ============================================================================
INSERT INTO app.doctor (
  user_id,
  phone_num,
  license_num,
  license_exp,
  gender,
  specialization,
  qualification,
  created_at,
  updated_at
)
SELECT
  ui.id AS user_id,
  dd.phone_num::text AS phone_num,
  dd.license_num::text AS license_num,
  (CURRENT_DATE + INTERVAL '2 years' + (dd.license_num || ' days')::INTERVAL)::timestamp AS license_exp,
  dd.gender,
  dd.specialisation AS specialization,
  dd.qualification,
  dd.created_at,
  dd.created_at AS updated_at
FROM doctor_data_with_id dd
JOIN user_inserts ui ON ui.username = LOWER(REPLACE(dd.email, '@pakartech.com', ''));

COMMIT;

-- ============================================================================
-- VERIFICATION
-- ============================================================================

DO $$
DECLARE
    doctor_count INT;
    user_count INT;
BEGIN
    SELECT COUNT(*) INTO doctor_count FROM app.doctor;
    SELECT COUNT(*) INTO user_count FROM app.user_account WHERE user_type = 'Doctor';
    
    RAISE NOTICE '========================================';
    RAISE NOTICE 'Doctor Seed Data Loaded';
    RAISE NOTICE '========================================';
    RAISE NOTICE 'Doctors: % records', doctor_count;
    RAISE NOTICE 'User Accounts (Doctor): % records', user_count;
    RAISE NOTICE '========================================';
END $$;