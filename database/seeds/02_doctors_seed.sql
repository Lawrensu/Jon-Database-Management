-- PAKAR Tech Healthcare - Doctor & Staff Sample Data
-- COS 20031 Database Design Project
-- Author: [Cherrylyn something i forgot to spell ur name]

-- ============================================================================
-- DOCTOR & STAFF SAMPLE DATA
-- ============================================================================
-- This file contains realistic sample data for doctors and staff.
-- Data includes: 20+ doctors with specializations, schedules, and departments
-- ============================================================================

SET search_path TO app, public;

-- 1) Departments
INSERT INTO app.departments (name, code, description, phone, email, location, is_active) VALUES
('Cardiology', 'CARD', 'Heart and cardiovascular specialists', '+60-3-2345-1001', 'cardiology@pakartech.com', 'Block A, Level 2', TRUE),
('Pediatrics', 'PEDI', 'Child and adolescent healthcare', '+60-3-2345-1002', 'pediatrics@pakartech.com', 'Block B, Level 1', TRUE),
('General Practice', 'GP', 'General medical consultation', '+60-3-2345-1004', 'gp@pakartech.com', 'Block C, Level 1', TRUE),
('Orthopedics', 'ORTHO', 'Bone, joint and muscle specialists', '+60-3-2345-1005', 'orthopedics@pakartech.com', 'Block D, Level 3', TRUE),
('Dermatology', 'DERM', 'Skin specialists', '+60-3-2345-1006', 'derm@pakartech.com', 'Block E, Level 2', TRUE),
('Neurology', 'NEURO', 'Nervous system specialists', '+60-3-2345-1007', 'neuro@pakartech.com', 'Block F, Level 4', TRUE),
('Obstetrics & Gynecology', 'OBGYN', 'Women''s health and childbirth', '+60-3-2345-1008', 'obgyn@pakartech.com', 'Block G, Level 2', TRUE),
('Emergency', 'EMER', 'Emergency medicine and trauma', '+60-3-2345-1009', 'emergency@pakartech.com', 'Emergency Wing, Ground Floor', TRUE)
ON CONFLICT (code) DO NOTHING;

-- 2) Specializations
INSERT INTO app.specializations (name, code, description, requires_certification, years_training_required) VALUES
('General Practitioner', 'GP', 'General medical practice', TRUE, 3),
('Cardiologist', 'CARD', 'Heart specialist', TRUE, 5),
('Pediatrician', 'PEDI', 'Children''s doctor', TRUE, 4),
('Orthopedic Surgeon', 'ORTHO', 'Surgical care for musculoskeletal system', TRUE, 6),
('Dermatologist', 'DERM', 'Skin, hair and nail disorders', TRUE, 4),
('Neurologist', 'NEURO', 'Brain and nervous system specialist', TRUE, 5),
('Obstetrician/Gynecologist', 'OBGYN', 'Pregnancy and women''s reproductive health', TRUE, 5),
('Emergency Medicine', 'EMER', 'Acute and emergency care', TRUE, 3)
ON CONFLICT (code) DO NOTHING;

-- 3) Doctors (20 sample doctors)
INSERT INTO app.doctors (
    doctor_number, license_number,
    first_name, middle_name, last_name,
    department_id, specialization_id,
    qualification, years_of_experience,
    email, phone, office_location,
    hire_date, employment_type,
    consultation_fee,
    is_active, is_accepting_patients
) VALUES
(
 'DR2024001','MMC-CARD-00001','Rajesh','Kumar','Menon',
 (SELECT id FROM app.departments WHERE code='CARD'),
 (SELECT id FROM app.specializations WHERE code='CARD'),
 'MBBS, MD (Cardiology)', 18,
 'dr.rajesh.menon@pakartech.com', '+60-12-2345-0001', 'Block A, Level 2, Room 201',
 '2010-03-15','Full-time', 300.00, TRUE, TRUE
),
(
 'DR2024002','MMC-PEDI-00002','Amira','binti','Hassan',
 (SELECT id FROM app.departments WHERE code='PEDI'),
 (SELECT id FROM app.specializations WHERE code='PEDI'),
 'MBBS, MD (Pediatrics)', 12,
 'dr.amira.hassan@pakartech.com', '+60-12-2345-0002', 'Block B, Level 1, Room 101',
 '2012-09-01','Full-time', 250.00, TRUE, TRUE
),
(
 'DR2024003','MMC-GP-00003','Lim','Wei','Chong',
 (SELECT id FROM app.departments WHERE code='GP'),
 (SELECT id FROM app.specializations WHERE code='GP'),
 'MBBS', 6,
 'dr.lim.wei.chong@pakartech.com', '+60-12-2345-0003', 'Block C, Level 1, Room 12',
 '2018-01-10','Full-time', 150.00, TRUE, TRUE
),
(
 'DR2024004','MMC-ORTHO-00004','Suresh','Kumar','Nair',
 (SELECT id FROM app.departments WHERE code='ORTHO'),
 (SELECT id FROM app.specializations WHERE code='ORTHO'),
 'MBBS, MS (Orthopedics)', 14,
 'dr.suresh.nair@pakartech.com', '+60-12-2345-0004', 'Block D, Level 3, OR 2',
 '2009-06-20','Full-time', 320.00, TRUE, TRUE
),
(
 'DR2024005','MMC-DERM-00005','Tan','Siew','Ling',
 (SELECT id FROM app.departments WHERE code='DERM'),
 (SELECT id FROM app.specializations WHERE code='DERM'),
 'MBBS, DDerm', 9,
 'dr.tan.siew.ling@pakartech.com', '+60-12-2345-0005', 'Block E, Level 2, Room 5',
 '2014-11-05','Part-time', 200.00, TRUE, TRUE
),
(
 'DR2024006','MMC-NEURO-00006','Farid','bin','Ismail',
 (SELECT id FROM app.departments WHERE code='NEURO'),
 (SELECT id FROM app.specializations WHERE code='NEURO'),
 'MBBS, MD (Neurology)', 16,
 'dr.farid.ismail@pakartech.com', '+60-12-2345-0006', 'Block F, Level 4, Room 3',
 '2008-02-28','Full-time', 350.00, TRUE, TRUE
),
(
 'DR2024007','MMC-GP-00007','Nurul','binti','Aziz',
 (SELECT id FROM app.departments WHERE code='GP'),
 (SELECT id FROM app.specializations WHERE code='GP'),
 'MBBS', 4,
 'dr.nurul.aziz@pakartech.com', '+60-12-2345-0007', 'Block C, Level 1, Room 15',
 '2020-05-12','Part-time', 120.00, TRUE, TRUE
),
(
 'DR2024008','MMC-CARD-00008','David','','Tan',
 (SELECT id FROM app.departments WHERE code='CARD'),
 (SELECT id FROM app.specializations WHERE code='CARD'),
 'MBBS, MD (Cardiology)', 7,
 'dr.david.tan@pakartech.com', '+60-12-2345-0008', 'Block A, Level 2, Room 205',
 '2016-07-01','Full-time', 280.00, TRUE, TRUE
),
(
 'DR2024009','MMC-OBG-00009','Aisha','binti','Rahim',
 (SELECT id FROM app.departments WHERE code='OBGYN'),
 (SELECT id FROM app.specializations WHERE code='OBGYN'),
 'MBBS, MD (OBGYN)', 11,
 'dr.aisha.rahim@pakartech.com', '+60-12-2345-0009', 'Block G, Level 2, Room 10',
 '2013-04-10','Full-time', 270.00, TRUE, TRUE
),
(
 'DR2024010','MMC-EMER-00010','Hannah','','Lee',
 (SELECT id FROM app.departments WHERE code='EMER'),
 (SELECT id FROM app.specializations WHERE code='EMER'),
 'MBBS, MRCEM', 5,
 'dr.hannah.lee@pakartech.com', '+60-12-2345-0010', 'Emergency Wing, Shift A',
 '2019-10-01','Full-time', 180.00, TRUE, TRUE
),
(
 'DR2024011','MMC-PEDI-00011','Chong','','Ming',
 (SELECT id FROM app.departments WHERE code='PEDI'),
 (SELECT id FROM app.specializations WHERE code='PEDI'),
 'MBBS, MMed (Pediatrics)', 8,
 'dr.chong.ming@pakartech.com', '+60-12-2345-0011', 'Block B, Level 1, Room 103',
 '2015-08-15','Full-time', 240.00, TRUE, TRUE
),
(
 'DR2024012','MMC-GP-00012','Mohd','','Azlan',
 (SELECT id FROM app.departments WHERE code='GP'),
 (SELECT id FROM app.specializations WHERE code='GP'),
 'MBBS', 3,
 'dr.mohd.azlan@pakartech.com', '+60-12-2345-0012', 'Block C, Level 1, Room 20',
 '2021-01-20','Part-time', 110.00, TRUE, TRUE
),
(
 'DR2024013','MMC-ORTHO-00013','Priya','','Menon',
 (SELECT id FROM app.departments WHERE code='ORTHO'),
 (SELECT id FROM app.specializations WHERE code='ORTHO'),
 'MBBS, MS (Orthopedics)', 10,
 'dr.priya.menon@pakartech.com', '+60-12-2345-0013', 'Block D, Level 3, OR 1',
 '2012-12-01','Full-time', 330.00, TRUE, TRUE
),
(
 'DR2024014','MMC-DERM-00014','Wong','','Liang',
 (SELECT id FROM app.departments WHERE code='DERM'),
 (SELECT id FROM app.specializations WHERE code='DERM'),
 'MBBS, DDerm', 6,
 'dr.wong.liang@pakartech.com', '+60-12-2345-0014', 'Block E, Level 2, Room 6',
 '2017-03-25','Part-time', 190.00, TRUE, TRUE
),
(
 'DR2024015','MMC-NEURO-00015','Siti','','Noor',
 (SELECT id FROM app.departments WHERE code='NEURO'),
 (SELECT id FROM app.specializations WHERE code='NEURO'),
 'MBBS, MD (Neurology)', 13,
 'dr.siti.noor@pakartech.com', '+60-12-2345-0015', 'Block F, Level 4, Room 5',
 '2011-09-05','Full-time', 360.00, TRUE, TRUE
),
(
 'DR2024016','MMC-OBG-00016','Leong','','May',
 (SELECT id FROM app.departments WHERE code='OBGYN'),
 (SELECT id FROM app.specializations WHERE code='OBGYN'),
 'MBBS, MOG (Obstetrics & Gyn)', 9,
 'dr.leong.may@pakartech.com', '+60-12-2345-0016', 'Block G, Level 2, Room 12',
 '2014-06-30','Full-time', 260.00, TRUE, TRUE
),
(
 'DR2024017','MMC-EMER-00017','Rakesh','','Singh',
 (SELECT id FROM app.departments WHERE code='EMER'),
 (SELECT id FROM app.specializations WHERE code='EMER'),
 'MBBS, MRCEM', 7,
 'dr.rakesh.singh@pakartech.com', '+60-12-2345-0017', 'Emergency Wing, Shift B',
 '2016-11-10','Full-time', 190.00, TRUE, TRUE
),
(
 'DR2024018','MMC-GP-00018','Jason','','Tan',
 (SELECT id FROM app.departments WHERE code='GP'),
 (SELECT id FROM app.specializations WHERE code='GP'),
 'MBBS', 2,
 'dr.jason.tan@pakartech.com', '+60-12-2345-0018', 'Block C, Level 1, Room 22',
 '2022-04-01','Part-time', 100.00, TRUE, TRUE
),
(
 'DR2024019','MMC-CARD-00019','Elena','','Gomez',
 (SELECT id FROM app.departments WHERE code='CARD'),
 (SELECT id FROM app.specializations WHERE code='CARD'),
 'MBBS, MD (Cardiology)', 20,
 'dr.elena.gomez@pakartech.com', '+60-12-2345-0019', 'Block A, Level 2, Room 202',
 '2005-02-07','Full-time', 340.00, TRUE, TRUE
),
(
 'DR2024020','MMC-PEDI-00020','Nur','Laila','Badrul',
 (SELECT id FROM app.departments WHERE code='PEDI'),
 (SELECT id FROM app.specializations WHERE code='PEDI'),
 'MBBS, MMed (Pediatrics)', 5,
 'dr.nur.laila@pakartech.com', '+60-12-2345-0020', 'Block B, Level 1, Room 110',
 '2019-02-01','Part-time', 220.00, TRUE, TRUE
)
ON CONFLICT (doctor_number) DO NOTHING;

-- 4) Doctor schedules
-- Full-time: Mon (1) - Fri (5) 09:00 - 17:00 with lunch 13:00-14:00
INSERT INTO app.doctor_schedules (doctor_id, day_of_week, start_time, end_time, break_start_time, break_end_time, is_active)
SELECT d.id, dow.day, '09:00:00'::time, '17:00:00'::time, '13:00:00'::time, '14:00:00'::time, TRUE
FROM app.doctors d
CROSS JOIN (VALUES (1),(2),(3),(4),(5)) AS dow(day)
WHERE d.employment_type = 'Full-time'
ON CONFLICT DO NOTHING;

-- Part-time example: Tue (2) & Thu (4) 14:00 - 20:00 no formal break
INSERT INTO app.doctor_schedules (doctor_id, day_of_week, start_time, end_time, break_start_time, break_end_time, is_active)
SELECT d.id, dow.day, '14:00:00'::time, '20:00:00'::time, NULL, NULL, TRUE
FROM app.doctors d
CROSS JOIN (VALUES (2),(4)) AS dow(day)
WHERE d.employment_type = 'Part-time'
ON CONFLICT DO NOTHING;

-- Success message (non-blocking for psql scripts)
RAISE NOTICE '02_doctors_seed completed: departments, specializations, doctors and schedules attempted.';