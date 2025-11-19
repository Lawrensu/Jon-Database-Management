-- PAKAR Tech Healthcare Database - Core Schema
-- COS 20031 Database Design Project
-- Authors: Lawrence, Jonathan
-- Version 2.0 

-- ============================================================================
-- Tables in ERD (16 total):
-- 1. Admin
-- 2. SuperAdmin  
-- 3. User
-- 4. Reminder
-- 5. Patient
-- 6. Doctor
-- 7. Symptom 
-- 8. PatientSymptom 
-- 9. Condition
-- 10. Medication
-- 11. SideEffect
-- 12. MedicationSideEffect 
-- 13. Prescription
-- 14. PrescriptionVersion
-- 15. MedicationSchedule
-- 16. MedicationLog
-- ============================================================================

BEGIN;

SET search_path TO app, public;

-- ============================================================================
-- SECTION 0: CUSTOM TYPES (PostgreSQL requires these)
-- ============================================================================

CREATE TYPE user_type_enum AS ENUM ('Patient', 'Doctor', 'Admin', 'SuperAdmin');
CREATE TYPE gender_enum AS ENUM ('Male', 'Female', 'Other');
CREATE TYPE severity_enum AS ENUM ('Mild', 'Moderate', 'Severe');
CREATE TYPE prescription_status_enum AS ENUM ('Active', 'Completed', 'Cancelled', 'Expired');
CREATE TYPE titration_unit_enum AS ENUM ('mg', 'ml', 'tablets', 'capsules', 'units');
CREATE TYPE med_timing_enum AS ENUM ('BeforeMeal', 'AfterMeal');
CREATE TYPE duration_unit_enum AS ENUM ('Days', 'Weeks', 'Months');
CREATE TYPE med_log_status_enum AS ENUM ('Taken', 'Missed', 'Skipped');

-- ============================================================================
-- SECTION 1: USER MANAGEMENT (Admin, SuperAdmin, User)
-- ============================================================================

-- 1.1 User (center, parent table)
CREATE TABLE app.user_account (
    user_id SERIAL PRIMARY KEY,  
    
    username VARCHAR(100) NOT NULL UNIQUE,
    password BYTEA NOT NULL,  
    user_type user_type_enum NOT NULL,
    
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    email VARCHAR(100) NOT NULL UNIQUE,
    
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP  
);

CREATE INDEX idx_user_username ON app.user_account(username);
CREATE INDEX idx_user_email ON app.user_account(email);
CREATE INDEX idx_user_type ON app.user_account(user_type);

COMMENT ON TABLE app.user_account IS 'Parent table for all user types (Admin, SuperAdmin, Patient, Doctor)';

-- 1.2 Admin 
CREATE TABLE app.admin (
    admin_id SERIAL PRIMARY KEY,
    user_id INT NOT NULL UNIQUE,
    username VARCHAR(100) NOT NULL UNIQUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT fk_admin_user FOREIGN KEY (user_id) 
        REFERENCES app.user_account(user_id) ON DELETE CASCADE
);

CREATE INDEX idx_admin_user ON app.admin(user_id);

-- 1.3 SuperAdmin 
CREATE TABLE app.super_admin (
    super_admin_id SERIAL PRIMARY KEY,
    user_id INT NOT NULL UNIQUE,
    username VARCHAR(100) NOT NULL UNIQUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT fk_super_admin_user FOREIGN KEY (user_id) 
        REFERENCES app.user_account(user_id) ON DELETE CASCADE
);

CREATE INDEX idx_super_admin_user ON app.super_admin(user_id);

-- ============================================================================
-- SECTION 2: CORE ENTITIES (Doctor, Patient)
-- ============================================================================

-- 2.1 Doctor 
CREATE TABLE app.doctor (
    doctor_id SERIAL PRIMARY KEY,
    user_id INT NOT NULL UNIQUE,
    
    phone_num BIGINT NOT NULL,
    license_num INT NOT NULL UNIQUE,
    license_exp TIMESTAMP NOT NULL,
    
    gender gender_enum NOT NULL,
    specialisation VARCHAR(60),
    qualification VARCHAR(60),
    clinical_inst VARCHAR(40),
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT fk_doctor_user FOREIGN KEY (user_id) 
        REFERENCES app.user_account(user_id) ON DELETE CASCADE,

    CONSTRAINT ck_doctor_license_exp CHECK (license_exp > CURRENT_TIMESTAMP)
);

CREATE INDEX idx_doctor_user ON app.doctor(user_id);
CREATE INDEX idx_doctor_license ON app.doctor(license_num);
CREATE INDEX idx_doctor_specialisation ON app.doctor(specialisation);

-- 2.2 Patient 
CREATE TABLE app.patient (
    patient_id SERIAL PRIMARY KEY,
    user_id INT NOT NULL UNIQUE,
    doctor_id INT, 
    
    phone_num BIGINT NOT NULL,
    birth_date TIMESTAMP NOT NULL,
    gender gender_enum NOT NULL,
    address VARCHAR(200),
    
    emergency_contact_name VARCHAR(100),
    emergency_phone BIGINT,
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT fk_patient_user FOREIGN KEY (user_id) 
        REFERENCES app.user_account(user_id) ON DELETE CASCADE,
    
    CONSTRAINT fk_patient_doctor FOREIGN KEY (doctor_id) 
        REFERENCES app.doctor(doctor_id) ON DELETE SET NULL,
    
    CONSTRAINT ck_patient_birth_date CHECK (birth_date <= CURRENT_TIMESTAMP),
    CONSTRAINT ck_patient_age CHECK (EXTRACT(YEAR FROM AGE(birth_date)) <= 150)
);

CREATE INDEX idx_patient_user ON app.patient(user_id);
CREATE INDEX idx_patient_doctor ON app.patient(doctor_id);
CREATE INDEX idx_patient_phone ON app.patient(phone_num);
CREATE INDEX idx_patient_birth_date ON app.patient(birth_date);

-- ============================================================================
-- SECTION 3: MEDICAL DATA
-- ============================================================================

-- 3.1 Condition (parent for symptom and side-effect)
CREATE TABLE app.condition (
    condition_id SERIAL PRIMARY KEY,

    condition_name VARCHAR(100) NOT NULL UNIQUE,
    condition_desc TEXT
);

CREATE INDEX idx_condition_name ON app.condition(condition_name);

COMMENT ON TABLE app.condition IS 'Parent table for Symptoms and SideEffects - represents medical conditions';

-- 3.2 Symptom 
CREATE TABLE app.symptom (
    symptom_id SERIAL PRIMARY KEY,
    condition_id INT NOT NULL, 
    
    CONSTRAINT fk_symptom_condition FOREIGN KEY (condition_id)
        REFERENCES app.condition(condition_id) ON DELETE SET NULL
);

CREATE INDEX idx_symptom_condition ON app.symptom(condition_id);

COMMENT ON TABLE app.symptom IS 
'Symptoms that patients can report. Links to condition table. E.g., "Headache" can be both a symptom AND a side effect.';

-- 3.3 PatientSymptom 
CREATE TABLE app.patient_symptom (
    patient_symptom_id SERIAL PRIMARY KEY,
    patient_id INT NOT NULL,
    symptom_id INT NOT NULL,
    
    date_reported TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    notes TEXT,
    severity severity_enum,
    date_resolved TIMESTAMP,
    
    CONSTRAINT fk_patient_symptom_patient FOREIGN KEY (patient_id)
        REFERENCES app.patient(patient_id) ON DELETE CASCADE,
    
    CONSTRAINT fk_patient_symptom_symptom FOREIGN KEY (symptom_id)
        REFERENCES app.symptom(symptom_id) ON DELETE CASCADE,
    
    CONSTRAINT uq_patient_symptom UNIQUE(patient_id, symptom_id, date_reported),
    
    CONSTRAINT ck_patient_symptom_dates CHECK (
        date_resolved IS NULL OR date_resolved >= date_reported
    )
);

CREATE INDEX idx_patient_symptom_patient ON app.patient_symptom(patient_id);
CREATE INDEX idx_patient_symptom_symptom ON app.patient_symptom(symptom_id);
CREATE INDEX idx_patient_symptom_date ON app.patient_symptom(date_reported);
CREATE INDEX idx_patient_symptom_unresolved ON app.patient_symptom(patient_id) 
    WHERE date_resolved IS NULL;

-- ============================================================================
-- SECTION 4: MEDICATIONS 
-- ============================================================================

-- 4.1 Medication 
CREATE TABLE app.medication (
    medication_id SERIAL PRIMARY KEY,

    med_name VARCHAR(100) NOT NULL,
    med_brand_name VARCHAR(100),
    med_manufacturer VARCHAR(100),
    med_desc TEXT NOT NULL
);

CREATE INDEX idx_medication_name ON app.medication(med_name);
CREATE INDEX idx_medication_brand ON app.medication(med_brand_name) WHERE med_brand_name IS NOT NULL;
CREATE INDEX idx_medication_manufacturer ON app.medication(med_manufacturer) WHERE med_manufacturer IS NOT NULL;

-- 4.2 SideEffect 
CREATE TABLE app.side_effect (
    side_effect_id SERIAL PRIMARY KEY,
    condition_id INT NOT NULL,  
    
    CONSTRAINT fk_side_effect_condition FOREIGN KEY (condition_id)
        REFERENCES app.condition(condition_id) ON DELETE SET NULL
);

CREATE INDEX idx_side_effect_condition ON app.side_effect(condition_id);

COMMENT ON TABLE app.side_effect IS 
'Side effects caused by medications. Links to condition table. E.g., "Nausea" can be both a symptom AND a side effect.';

-- 4.3 MedicationSideEffect (junction Medication ↔ SideEffect)
CREATE TABLE app.medication_side_effect (
    medication_side_effect_id SERIAL PRIMARY KEY,
    medication_id INT NOT NULL,
    side_effect_id INT NOT NULL,
    
    frequency VARCHAR(16), 
    
    CONSTRAINT fk_med_side_effect_medication FOREIGN KEY (medication_id)
        REFERENCES app.medication(medication_id) ON DELETE CASCADE,
    
    CONSTRAINT fk_med_side_effect_side_effect FOREIGN KEY (side_effect_id)
        REFERENCES app.side_effect(side_effect_id) ON DELETE CASCADE,
    
    CONSTRAINT uq_medication_side_effect UNIQUE(medication_id, side_effect_id)
);

CREATE INDEX idx_med_side_effect_medication ON app.medication_side_effect(medication_id);
CREATE INDEX idx_med_side_effect_side_effect ON app.medication_side_effect(side_effect_id);

-- ============================================================================
-- SECTION 5: PRESCRIPTIONS 
-- ============================================================================

-- 5.1 Prescription 
CREATE TABLE app.prescription (
    prescription_id SERIAL PRIMARY KEY,  
    patient_id INT NOT NULL,
    doctor_id INT NOT NULL,
    
    created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    status prescription_status_enum DEFAULT 'Active',
    doctor_note TEXT,
    
    CONSTRAINT fk_prescription_patient FOREIGN KEY (patient_id)
        REFERENCES app.patient(patient_id) ON DELETE RESTRICT,
    
    CONSTRAINT fk_prescription_doctor FOREIGN KEY (doctor_id)
        REFERENCES app.doctor(doctor_id) ON DELETE RESTRICT
);

CREATE INDEX idx_prescription_patient ON app.prescription(patient_id);
CREATE INDEX idx_prescription_doctor ON app.prescription(doctor_id);
CREATE INDEX idx_prescription_status ON app.prescription(status);

-- 5.2 PrescriptionVersion 
CREATE TABLE app.prescription_version (
    prescription_version_id SERIAL PRIMARY KEY, 
    prescription_id INT NOT NULL,  
    medication_id INT NOT NULL,    
    
    titration FLOAT,
    titration_unit titration_unit_enum,
    start_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    end_date TIMESTAMP,
    reason_for_change VARCHAR(256),
    
    CONSTRAINT fk_prescription_version_prescription FOREIGN KEY (prescription_id)
        REFERENCES app.prescription(prescription_id) ON DELETE CASCADE,
    
    CONSTRAINT fk_prescription_version_medication FOREIGN KEY (medication_id)
        REFERENCES app.medication(medication_id) ON DELETE RESTRICT
);

CREATE INDEX idx_prescription_version_prescription ON app.prescription_version(prescription_id);
CREATE INDEX idx_prescription_version_medication ON app.prescription_version(medication_id);
CREATE INDEX idx_prescription_version_dates ON app.prescription_version(start_date, end_date);

-- ============================================================================
-- SECTION 6: MEDICATION TRACKING 
-- ============================================================================

-- 6.1 MedicationSchedule
CREATE TABLE app.medication_schedule (
    medication_schedule_id SERIAL PRIMARY KEY,  
    prescription_version_id INT NOT NULL,  
    
    med_timing med_timing_enum,
    frequency_times_per_day INT CHECK (frequency_times_per_day >= 1 AND frequency_times_per_day <= 6),
    frequency_interval_hours INT CHECK (frequency_interval_hours >= 1 AND frequency_interval_hours <= 24),
    
    duration INT,
    duration_unit duration_unit_enum,
    
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT fk_med_schedule_prescription_version FOREIGN KEY (prescription_version_id)
        REFERENCES app.prescription_version(prescription_version_id) ON DELETE CASCADE
);

CREATE INDEX idx_med_schedule_prescription_version ON app.medication_schedule(prescription_version_id);

-- 6.2 MedicationLog
CREATE TABLE app.medication_log (
    medication_log_id SERIAL PRIMARY KEY,  
    patient_id INT NOT NULL,
    medication_id INT NOT NULL,         
    medication_schedule_id INT,          
    
    notes VARCHAR(128),
    scheduled_time TIMESTAMP NOT NULL,
    actual_taken_time TIMESTAMP,
    status med_log_status_enum DEFAULT 'Missed',
    
    CONSTRAINT fk_med_log_patient FOREIGN KEY (patient_id)
        REFERENCES app.patient(patient_id) ON DELETE CASCADE,
    
    CONSTRAINT fk_med_log_medication FOREIGN KEY (medication_id)
        REFERENCES app.medication(medication_id) ON DELETE RESTRICT,
    
    CONSTRAINT fk_med_log_schedule FOREIGN KEY (medication_schedule_id)
        REFERENCES app.medication_schedule(medication_schedule_id) ON DELETE SET NULL
);

CREATE INDEX idx_med_log_patient ON app.medication_log(patient_id);
CREATE INDEX idx_med_log_medication ON app.medication_log(medication_id);
CREATE INDEX idx_med_log_schedule ON app.medication_log(medication_schedule_id);
CREATE INDEX idx_med_log_status ON app.medication_log(status);
CREATE INDEX idx_med_log_scheduled_time ON app.medication_log(scheduled_time);

-- 6.3 Reminder
CREATE TABLE app.reminder (
    reminder_id SERIAL PRIMARY KEY,  
    patient_id INT NOT NULL,
    medication_schedule_id INT,  
    
    message VARCHAR(128),
    schedule TIMESTAMP NOT NULL,
    
    CONSTRAINT fk_reminder_patient FOREIGN KEY (patient_id)
        REFERENCES app.patient(patient_id) ON DELETE CASCADE,
    
    CONSTRAINT fk_reminder_schedule FOREIGN KEY (medication_schedule_id)
        REFERENCES app.medication_schedule(medication_schedule_id) ON DELETE CASCADE
);

CREATE INDEX idx_reminder_patient ON app.reminder(patient_id);
CREATE INDEX idx_reminder_schedule ON app.reminder(schedule);
CREATE INDEX idx_reminder_med_schedule ON app.reminder(medication_schedule_id);


-- ============================================================================
-- SECTION 7: TRIGGERS 
-- ============================================================================

CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_patient_updated_at 
    BEFORE UPDATE ON app.patient 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_doctor_updated_at 
    BEFORE UPDATE ON app.doctor 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_med_schedule_updated_at 
    BEFORE UPDATE ON app.medication_schedule 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ============================================================================
-- SECTION 8: SCHEMA VALIDATION
-- ============================================================================

-- Verify all tables were created
DO $$
DECLARE
    table_count INT;
BEGIN
    SELECT COUNT(*) INTO table_count 
    FROM information_schema.tables 
    WHERE table_schema = 'app';
    
    IF table_count = 16 THEN
        RAISE NOTICE '✅ All 16 tables created successfully';
    ELSE
        RAISE WARNING '⚠️  Expected 16 tables, found %', table_count;
    END IF;
END $$;

-- ============================================================================
-- COMPLETION MESSAGE
-- ============================================================================

DO $$
BEGIN
    RAISE NOTICE '========================================';
    RAISE NOTICE 'PAKAR Tech Schema Created (PostgreSQL)';
    RAISE NOTICE '========================================';
    RAISE NOTICE 'Tables: 16 core tables';
    RAISE NOTICE 'ENUMs: 8 custom types';
    RAISE NOTICE 'Triggers: 3 auto-update';
    RAISE NOTICE 'Indexes: 32 performance indexes';
    RAISE NOTICE '========================================';
END $$;

COMMIT;