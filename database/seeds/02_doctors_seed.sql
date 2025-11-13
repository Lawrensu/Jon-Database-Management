-- PAKAR Tech Healthcare - Doctor & Staff Sample Data
-- COS 20031 Database Design Project
-- Author: [Cherylynn]

-- ============================================================================
-- DOCTOR & STAFF SAMPLE DATA
-- ============================================================================
-- This file contains realistic sample data for doctors and staff.
-- Data includes: 20+ doctors with specializations, schedules, and departments
-- ============================================================================

-- Set search path to use 'app' schema
SET search_path TO app, public;

-- 1) Doctors: map seed to core schema `app.doctor` (singular)
-- Approach:
--  - Create a minimal `app.user_account` row per doctor so we can preserve email/username from seeds.md
--  - Insert into `app.doctor` using the required columns: doctor_id, user_id (UUID ref), phone_num, license_num, license_exp, qualification, specialization, gender, created_at
--  - Keep inserts idempotent with ON CONFLICT DO NOTHING

-- Insert minimal user_account rows (username stores the doctor's email)
INSERT INTO app.user_account (user_id, username, password_hash, user_type, is_active, created_at)
VALUES
('USER_DR2024001','dr.rajesh.menon@pakartech.com','seed-password-hash','Doctor', TRUE, '2010-03-15'::timestamp),
('USER_DR2024002','dr.amira.hassan@pakartech.com','seed-password-hash','Doctor', TRUE, '2012-09-01'::timestamp),
('USER_DR2024003','dr.lim.wei.chong@pakartech.com','seed-password-hash','Doctor', TRUE, '2018-01-10'::timestamp),
('USER_DR2024004','dr.suresh.nair@pakartech.com','seed-password-hash','Doctor', TRUE, '2009-06-20'::timestamp),
('USER_DR2024005','dr.tan.siew.ling@pakartech.com','seed-password-hash','Doctor', TRUE, '2014-11-05'::timestamp),
('USER_DR2024006','dr.farid.ismail@pakartech.com','seed-password-hash','Doctor', TRUE, '2008-02-28'::timestamp),
('USER_DR2024007','dr.nurul.aziz@pakartech.com','seed-password-hash','Doctor', TRUE, '2020-05-12'::timestamp),
('USER_DR2024008','dr.david.tan@pakartech.com','seed-password-hash','Doctor', TRUE, '2016-07-01'::timestamp),
('USER_DR2024009','dr.aisha.rahim@pakartech.com','seed-password-hash','Doctor', TRUE, '2013-04-10'::timestamp),
('USER_DR2024010','dr.hannah.lee@pakartech.com','seed-password-hash','Doctor', TRUE, '2019-10-01'::timestamp),
('USER_DR2024011','dr.chong.ming@pakartech.com','seed-password-hash','Doctor', TRUE, '2015-08-15'::timestamp),
('USER_DR2024012','dr.mohd.azlan@pakartech.com','seed-password-hash','Doctor', TRUE, '2021-01-20'::timestamp),
('USER_DR2024013','dr.priya.menon@pakartech.com','seed-password-hash','Doctor', TRUE, '2012-12-01'::timestamp),
('USER_DR2024014','dr.wong.liang@pakartech.com','seed-password-hash','Doctor', TRUE, '2017-03-25'::timestamp),
('USER_DR2024015','dr.siti.noor@pakartech.com','seed-password-hash','Doctor', TRUE, '2011-09-05'::timestamp),
('USER_DR2024016','dr.leong.may@pakartech.com','seed-password-hash','Doctor', TRUE, '2014-06-30'::timestamp),
('USER_DR2024017','dr.rakesh.singh@pakartech.com','seed-password-hash','Doctor', TRUE, '2016-11-10'::timestamp),
('USER_DR2024018','dr.jason.tan@pakartech.com','seed-password-hash','Doctor', TRUE, '2022-04-01'::timestamp),
('USER_DR2024019','dr.elena.gomez@pakartech.com','seed-password-hash','Doctor', TRUE, '2005-02-07'::timestamp),
('USER_DR2024020','dr.nur.laila@pakartech.com','seed-password-hash','Doctor', TRUE, '2019-02-01'::timestamp)
ON CONFLICT (user_id) DO NOTHING;

-- Insert doctors into app.doctor using required columns; link to user_account via user_id (UUID id)
INSERT INTO app.doctor (doctor_id, user_id, phone_num, license_num, license_exp, qualification, specialization, gender, created_at)
VALUES
('DR2024001', (SELECT id FROM app.user_account WHERE user_id = 'USER_DR2024001'), '+60-12-2345-0001','MMC-CARD-00001','2030-03-15'::date,'MBBS, MD (Cardiology)','Cardiologist','Male','2010-03-15'::timestamp),
('DR2024002', (SELECT id FROM app.user_account WHERE user_id = 'USER_DR2024002'), '+60-12-2345-0002','MMC-PEDI-00002','2028-09-01'::date,'MBBS, MD (Pediatrics)','Pediatrician','Female','2012-09-01'::timestamp),
('DR2024003', (SELECT id FROM app.user_account WHERE user_id = 'USER_DR2024003'), '+60-12-2345-0003','MMC-GP-00003','2027-01-10'::date,'MBBS','General Practitioner','Male','2018-01-10'::timestamp),
('DR2024004', (SELECT id FROM app.user_account WHERE user_id = 'USER_DR2024004'), '+60-12-2345-0004','MMC-ORTHO-00004','2029-06-20'::date,'MBBS, MS (Orthopedics)','Orthopedic Surgeon','Male','2009-06-20'::timestamp),
('DR2024005', (SELECT id FROM app.user_account WHERE user_id = 'USER_DR2024005'), '+60-12-2345-0005','MMC-DERM-00005','2026-11-05'::date,'MBBS, DDerm','Dermatologist','Female','2014-11-05'::timestamp),
('DR2024006', (SELECT id FROM app.user_account WHERE user_id = 'USER_DR2024006'), '+60-12-2345-0006','MMC-NEURO-00006','2028-02-28'::date,'MBBS, MD (Neurology)','Neurologist','Male','2008-02-28'::timestamp),
('DR2024007', (SELECT id FROM app.user_account WHERE user_id = 'USER_DR2024007'), '+60-12-2345-0007','MMC-GP-00007','2028-05-12'::date,'MBBS','General Practitioner','Female','2020-05-12'::timestamp),
('DR2024008', (SELECT id FROM app.user_account WHERE user_id = 'USER_DR2024008'), '+60-12-2345-0008','MMC-CARD-00008','2027-07-01'::date,'MBBS, MD (Cardiology)','Cardiologist','Male','2016-07-01'::timestamp),
('DR2024009', (SELECT id FROM app.user_account WHERE user_id = 'USER_DR2024009'), '+60-12-2345-0009','MMC-OBG-00009','2029-04-10'::date,'MBBS, MD (OBGYN)','Obstetrician/Gynecologist','Female','2013-04-10'::timestamp),
('DR2024010', (SELECT id FROM app.user_account WHERE user_id = 'USER_DR2024010'), '+60-12-2345-0010','MMC-EMER-00010','2026-10-01'::date,'MBBS, MRCEM','Emergency Medicine','Female','2019-10-01'::timestamp),
('DR2024011', (SELECT id FROM app.user_account WHERE user_id = 'USER_DR2024011'), '+60-12-2345-0011','MMC-PEDI-00011','2028-08-15'::date,'MBBS, MMed (Pediatrics)','Pediatrician','Male','2015-08-15'::timestamp),
('DR2024012', (SELECT id FROM app.user_account WHERE user_id = 'USER_DR2024012'), '+60-12-2345-0012','MMC-GP-00012','2031-01-20'::date,'MBBS','General Practitioner','Male','2021-01-20'::timestamp),
('DR2024013', (SELECT id FROM app.user_account WHERE user_id = 'USER_DR2024013'), '+60-12-2345-0013','MMC-ORTHO-00013','2027-12-01'::date,'MBBS, MS (Orthopedics)','Orthopedic Surgeon','Female','2012-12-01'::timestamp),
('DR2024014', (SELECT id FROM app.user_account WHERE user_id = 'USER_DR2024014'), '+60-12-2345-0014','MMC-DERM-00014','2028-03-25'::date,'MBBS, DDerm','Dermatologist','Female','2017-03-25'::timestamp),
('DR2024015', (SELECT id FROM app.user_account WHERE user_id = 'USER_DR2024015'), '+60-12-2345-0015','MMC-NEURO-00015','2026-09-05'::date,'MBBS, MD (Neurology)','Neurologist','Female','2011-09-05'::timestamp),
('DR2024016', (SELECT id FROM app.user_account WHERE user_id = 'USER_DR2024016'), '+60-12-2345-0016','MMC-OBG-00016','2029-06-30'::date,'MBBS, MOG (Obstetrics & Gyn)','Obstetrician/Gynecologist','Female','2014-06-30'::timestamp),
('DR2024017', (SELECT id FROM app.user_account WHERE user_id = 'USER_DR2024017'), '+60-12-2345-0017','MMC-EMER-00017','2027-11-10'::date,'MBBS, MRCEM','Emergency Medicine','Male','2016-11-10'::timestamp),
('DR2024018', (SELECT id FROM app.user_account WHERE user_id = 'USER_DR2024018'), '+60-12-2345-0018','MMC-GP-00018','2032-04-01'::date,'MBBS','General Practitioner','Male','2022-04-01'::timestamp),
('DR2024019', (SELECT id FROM app.user_account WHERE user_id = 'USER_DR2024019'), '+60-12-2345-0019','MMC-CARD-00019','2025-02-07'::date,'MBBS, MD (Cardiology)','Cardiologist','Female','2005-02-07'::timestamp),
('DR2024020', (SELECT id FROM app.user_account WHERE user_id = 'USER_DR2024020'), '+60-12-2345-0020','MMC-PEDI-00020','2028-02-01'::date,'MBBS, MMed (Pediatrics)','Pediatrician','Female','2019-02-01'::timestamp)
ON CONFLICT (doctor_id) DO NOTHING;

-- Success message (non-blocking for psql scripts)
RAISE NOTICE '02_doctors_seed completed: user_account and doctor records inserted into app.user_account and app.doctor.';