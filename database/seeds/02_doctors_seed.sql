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
-- Insert minimal user_account rows (username stores the doctor's email)
-- Insert user_account rows, match schema: do not insert into SERIAL PK, use password (BYTEA), add missing columns
INSERT INTO app.user_account (username, password, user_type, is_active, created_at)
SELECT v.username,
	decode('736565642d70617373776f7264','hex') AS password, -- 'seed-password' as BYTEA
	v.user_type,
	v.is_active,
	v.created_at
FROM (
	VALUES
		('dr.rajesh.menon@pakartech.com','Doctor', TRUE, '2010-03-15'::timestamp),
		('dr.amira.hassan@pakartech.com','Doctor', TRUE, '2012-09-01'::timestamp),
		('dr.lim.wei.chong@pakartech.com','Doctor', TRUE, '2018-01-10'::timestamp),
		('dr.suresh.nair@pakartech.com','Doctor', TRUE, '2009-06-20'::timestamp),
		('dr.tan.siew.ling@pakartech.com','Doctor', TRUE, '2014-11-05'::timestamp),
		('dr.farid.ismail@pakartech.com','Doctor', TRUE, '2008-02-28'::timestamp),
		('dr.nurul.aziz@pakartech.com','Doctor', TRUE, '2020-05-12'::timestamp),
		('dr.david.tan@pakartech.com','Doctor', TRUE, '2016-07-01'::timestamp),
		('dr.aisha.rahim@pakartech.com','Doctor', TRUE, '2013-04-10'::timestamp),
		('dr.hannah.lee@pakartech.com','Doctor', TRUE, '2019-10-01'::timestamp),
		('dr.chong.ming@pakartech.com','Doctor', TRUE, '2015-08-15'::timestamp),
		('dr.mohd.azlan@pakartech.com','Doctor', TRUE, '2021-01-20'::timestamp),
		('dr.priya.menon@pakartech.com','Doctor', TRUE, '2012-12-01'::timestamp),
		('dr.wong.liang@pakartech.com','Doctor', TRUE, '2017-03-25'::timestamp),
		('dr.siti.noor@pakartech.com','Doctor', TRUE, '2011-09-05'::timestamp),
		('dr.leong.may@pakartech.com','Doctor', TRUE, '2014-06-30'::timestamp),
		('dr.rakesh.singh@pakartech.com','Doctor', TRUE, '2016-11-10'::timestamp),
		('dr.jason.tan@pakartech.com','Doctor', TRUE, '2022-04-01'::timestamp),
		('dr.elena.gomez@pakartech.com','Doctor', TRUE, '2005-02-07'::timestamp),
		('dr.nur.laila@pakartech.com','Doctor', TRUE, '2019-02-01'::timestamp)
) AS v(username, user_type, is_active, created_at)
ON CONFLICT (username) DO NOTHING;

-- Insert doctors into app.doctor using required columns; link to user_account via user_id (UUID id)
-- Insert doctors, match schema: do not insert into SERIAL PK, fix datatypes, ensure license_exp is future, correct linkage
INSERT INTO app.doctor (doctor_id, user_account_id, phone_num, license_num, license_exp, qualification, specialization, gender, created_at)
SELECT v.doctor_id,
	(SELECT id FROM app.user_account WHERE username = v.username) AS user_account_id,
	v.phone_num,
	v.license_num::INT,
	(CURRENT_DATE + (365 * 2 + v.idx) * INTERVAL '1 day')::date AS license_exp, -- always future
	v.qualification,
	v.specialization,
	v.gender,
	v.created_at
FROM (
	VALUES
		('DR2024001','dr.rajesh.menon@pakartech.com','+60-12-2345-0001',1,'MBBS, MD (Cardiology)','Cardiologist','Male','2010-03-15'::timestamp,1),
		('DR2024002','dr.amira.hassan@pakartech.com','+60-12-2345-0002',2,'MBBS, MD (Pediatrics)','Pediatrician','Female','2012-09-01'::timestamp,2),
		('DR2024003','dr.lim.wei.chong@pakartech.com','+60-12-2345-0003',3,'MBBS','General Practitioner','Male','2018-01-10'::timestamp,3),
		('DR2024004','dr.suresh.nair@pakartech.com','+60-12-2345-0004',4,'MBBS, MS (Orthopedics)','Orthopedic Surgeon','Male','2009-06-20'::timestamp,4),
		('DR2024005','dr.tan.siew.ling@pakartech.com','+60-12-2345-0005',5,'MBBS, DDerm','Dermatologist','Female','2014-11-05'::timestamp,5),
		('DR2024006','dr.farid.ismail@pakartech.com','+60-12-2345-0006',6,'MBBS, MD (Neurology)','Neurologist','Male','2008-02-28'::timestamp,6),
		('DR2024007','dr.nurul.aziz@pakartech.com','+60-12-2345-0007',7,'MBBS','General Practitioner','Female','2020-05-12'::timestamp,7),
		('DR2024008','dr.david.tan@pakartech.com','+60-12-2345-0008',8,'MBBS, MD (Cardiology)','Cardiologist','Male','2016-07-01'::timestamp,8),
		('DR2024009','dr.aisha.rahim@pakartech.com','+60-12-2345-0009',9,'MBBS, MD (OBGYN)','Obstetrician/Gynecologist','Female','2013-04-10'::timestamp,9),
		('DR2024010','dr.hannah.lee@pakartech.com','+60-12-2345-0010',10,'MBBS, MRCEM','Emergency Medicine','Female','2019-10-01'::timestamp,10),
		('DR2024011','dr.chong.ming@pakartech.com','+60-12-2345-0011',11,'MBBS, MMed (Pediatrics)','Pediatrician','Male','2015-08-15'::timestamp,11),
		('DR2024012','dr.mohd.azlan@pakartech.com','+60-12-2345-0012',12,'MBBS','General Practitioner','Male','2021-01-20'::timestamp,12),
		('DR2024013','dr.priya.menon@pakartech.com','+60-12-2345-0013',13,'MBBS, MS (Orthopedics)','Orthopedic Surgeon','Female','2012-12-01'::timestamp,13),
		('DR2024014','dr.wong.liang@pakartech.com','+60-12-2345-0014',14,'MBBS, DDerm','Dermatologist','Female','2017-03-25'::timestamp,14),
		('DR2024015','dr.siti.noor@pakartech.com','+60-12-2345-0015',15,'MBBS, MD (Neurology)','Neurologist','Female','2011-09-05'::timestamp,15),
		('DR2024016','dr.leong.may@pakartech.com','+60-12-2345-0016',16,'MBBS, MOG (Obstetrics & Gyn)','Obstetrician/Gynecologist','Female','2014-06-30'::timestamp,16),
		('DR2024017','dr.rakesh.singh@pakartech.com','+60-12-2345-0017',17,'MBBS, MRCEM','Emergency Medicine','Male','2016-11-10'::timestamp,17),
		('DR2024018','dr.jason.tan@pakartech.com','+60-12-2345-0018',18,'MBBS','General Practitioner','Male','2022-04-01'::timestamp,18),
		('DR2024019','dr.elena.gomez@pakartech.com','+60-12-2345-0019',19,'MBBS, MD (Cardiology)','Cardiologist','Female','2005-02-07'::timestamp,19),
		('DR2024020','dr.nur.laila@pakartech.com','+60-12-2345-0020',20,'MBBS, MMed (Pediatrics)','Pediatrician','Female','2019-02-01'::timestamp,20)
) AS v(doctor_id, username, phone_num, license_num, qualification, specialization, gender, created_at, idx)
ON CONFLICT (doctor_id) DO NOTHING;

-- Success message (non-blocking for psql scripts)
RAISE NOTICE '02_doctors_seed completed: user_account and doctor records inserted, columns and linkage fixed.';