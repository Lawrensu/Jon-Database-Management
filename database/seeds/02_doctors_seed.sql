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
-- The project core schema defines `app.doctor` with columns:
-- doctor_id, user_id, first_name, last_name, email, phone_num, license_num,
-- qualification, specialization, gender, created_at, updated_at
-- We'll insert a representative set of doctors and keep it idempotent.

INSERT INTO app.doctor (doctor_id, first_name, last_name, email, phone_num, license_num, qualification, specialization, gender, created_at)
VALUES
('DR2024001','Rajesh','Menon','dr.rajesh.menon@pakartech.com','+60-12-2345-0001','MMC-CARD-00001','MBBS, MD (Cardiology)','Cardiologist','Male','2010-03-15'::timestamp),
('DR2024002','Amira','Hassan','dr.amira.hassan@pakartech.com','+60-12-2345-0002','MMC-PEDI-00002','MBBS, MD (Pediatrics)','Pediatrician','Female','2012-09-01'::timestamp),
('DR2024003','Lim','Chong','dr.lim.wei.chong@pakartech.com','+60-12-2345-0003','MMC-GP-00003','MBBS','General Practitioner','Male','2018-01-10'::timestamp),
('DR2024004','Suresh','Nair','dr.suresh.nair@pakartech.com','+60-12-2345-0004','MMC-ORTHO-00004','MBBS, MS (Orthopedics)','Orthopedic Surgeon','Male','2009-06-20'::timestamp),
('DR2024005','Tan','Ling','dr.tan.siew.ling@pakartech.com','+60-12-2345-0005','MMC-DERM-00005','MBBS, DDerm','Dermatologist','Female','2014-11-05'::timestamp),
('DR2024006','Farid','Ismail','dr.farid.ismail@pakartech.com','+60-12-2345-0006','MMC-NEURO-00006','MBBS, MD (Neurology)','Neurologist','Male','2008-02-28'::timestamp),
('DR2024007','Nurul','Aziz','dr.nurul.aziz@pakartech.com','+60-12-2345-0007','MMC-GP-00007','MBBS','General Practitioner','Female','2020-05-12'::timestamp),
('DR2024008','David','Tan','dr.david.tan@pakartech.com','+60-12-2345-0008','MMC-CARD-00008','MBBS, MD (Cardiology)','Cardiologist','Male','2016-07-01'::timestamp),
('DR2024009','Aisha','Rahim','dr.aisha.rahim@pakartech.com','+60-12-2345-0009','MMC-OBG-00009','MBBS, MD (OBGYN)','Obstetrician/Gynecologist','Female','2013-04-10'::timestamp),
('DR2024010','Hannah','Lee','dr.hannah.lee@pakartech.com','+60-12-2345-0010','MMC-EMER-00010','MBBS, MRCEM','Emergency Medicine','Female','2019-10-01'::timestamp),
('DR2024011','Chong','Ming','dr.chong.ming@pakartech.com','+60-12-2345-0011','MMC-PEDI-00011','MBBS, MMed (Pediatrics)','Pediatrician','Male','2015-08-15'::timestamp),
('DR2024012','Mohd','Azlan','dr.mohd.azlan@pakartech.com','+60-12-2345-0012','MMC-GP-00012','MBBS','General Practitioner','Male','2021-01-20'::timestamp),
('DR2024013','Priya','Menon','dr.priya.menon@pakartech.com','+60-12-2345-0013','MMC-ORTHO-00013','MBBS, MS (Orthopedics)','Orthopedic Surgeon','Female','2012-12-01'::timestamp),
('DR2024014','Wong','Liang','dr.wong.liang@pakartech.com','+60-12-2345-0014','MMC-DERM-00014','MBBS, DDerm','Dermatologist','Female','2017-03-25'::timestamp),
('DR2024015','Siti','Noor','dr.siti.noor@pakartech.com','+60-12-2345-0015','MMC-NEURO-00015','MBBS, MD (Neurology)','Neurologist','Female','2011-09-05'::timestamp),
('DR2024016','Leong','May','dr.leong.may@pakartech.com','+60-12-2345-0016','MMC-OBG-00016','MBBS, MOG (Obstetrics & Gyn)','Obstetrician/Gynecologist','Female','2014-06-30'::timestamp),
('DR2024017','Rakesh','Singh','dr.rakesh.singh@pakartech.com','+60-12-2345-0017','MMC-EMER-00017','MBBS, MRCEM','Emergency Medicine','Male','2016-11-10'::timestamp),
('DR2024018','Jason','Tan','dr.jason.tan@pakartech.com','+60-12-2345-0018','MMC-GP-00018','MBBS','General Practitioner','Male','2022-04-01'::timestamp),
('DR2024019','Elena','Gomez','dr.elena.gomez@pakartech.com','+60-12-2345-0019','MMC-CARD-00019','MBBS, MD (Cardiology)','Cardiologist','Female','2005-02-07'::timestamp),
('DR2024020','Nur','Badrul','dr.nur.laila@pakartech.com','+60-12-2345-0020','MMC-PEDI-00020','MBBS, MMed (Pediatrics)','Pediatrician','Female','2019-02-01'::timestamp)
ON CONFLICT (doctor_id) DO NOTHING;

-- Success message (non-blocking for psql scripts)
RAISE NOTICE '02_doctors_seed completed: mapped doctors inserted into app.doctor.';