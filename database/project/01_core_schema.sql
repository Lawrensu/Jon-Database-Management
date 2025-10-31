-- PAKAR Tech Healthcare Database - Core Schema
-- COS 20031 Database Design Project
-- Authors: Lawrence, Jonathan
-- Based on ERD Version 1.0

-- ============================================================================
-- IMPORTANT: Read Before Editing
-- ============================================================================
-- This file contains the CORE database schema for PAKAR Tech Healthcare.
-- Any changes here affect the entire system!
--
-- Design Principles:
-- 1. All tables use UUID primary keys for scalability
-- 2. Every table has created_at and updated_at timestamps
-- 3. Use CITEXT for case-insensitive text (emails, usernames)
-- 4. Follow naming convention: lowercase_with_underscores
-- 5. Add indexes on foreign keys and frequently queried columns
--
-- Based on ERD: Admin, SuperAdmin, User, Reminder, Patient, Doctor,
--               PatientSymptom, Condition, Prescription, Medication,
--               SideEffect, MedicationSideEffect
-- ============================================================================

-- Set search path to use 'app' schema
SET search_path TO app, public;

-- ============================================================================
-- SECTION 1: USER MANAGEMENT & AUTHENTICATION
-- ============================================================================

-- 1.1 Admin Users
CREATE TABLE IF NOT EXISTS app.admin (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    
    -- Credentials (from ERD)
    admin_id VARCHAR(50) NOT NULL UNIQUE,
    user_id VARCHAR(50) NOT NULL UNIQUE,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    email CITEXT NOT NULL UNIQUE,
    username VARCHAR(50) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    
    -- Timestamps
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Constraints
    CONSTRAINT ck_admin_email CHECK (email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$')
);

CREATE INDEX IF NOT EXISTS idx_admin_username ON app.admin(username);
CREATE INDEX IF NOT EXISTS idx_admin_email ON app.admin(email);

COMMENT ON TABLE app.admin IS 'System administrators with full access';

-- 1.2 Super Admin Users
CREATE TABLE IF NOT EXISTS app.super_admin (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    
    -- Credentials (from ERD)
    super_admin_id VARCHAR(50) NOT NULL UNIQUE,
    user_id VARCHAR(50) NOT NULL UNIQUE,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    email CITEXT NOT NULL UNIQUE,
    username VARCHAR(50) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    
    -- Timestamps
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Constraints
    CONSTRAINT ck_super_admin_email CHECK (email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$')
);

CREATE INDEX IF NOT EXISTS idx_super_admin_username ON app.super_admin(username);
CREATE INDEX IF NOT EXISTS idx_super_admin_email ON app.super_admin(email);

COMMENT ON TABLE app.super_admin IS 'Super administrators with highest privileges';

-- 1.3 Regular Users (from ERD)
CREATE TABLE IF NOT EXISTS app.user_account (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    
    -- Credentials (from ERD)
    user_id VARCHAR(50) NOT NULL UNIQUE,
    username VARCHAR(50) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    
    -- User Type (Patient or Doctor)
    user_type VARCHAR(20) NOT NULL CHECK (user_type IN ('Patient', 'Doctor')),
    
    -- Status
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_user_username ON app.user_account(username);
CREATE INDEX IF NOT EXISTS idx_user_type ON app.user_account(user_type);

COMMENT ON TABLE app.user_account IS 'User accounts for patients and doctors login';

-- ============================================================================
-- SECTION 2: CORE ENTITIES (FROM ERD)
-- ============================================================================

-- 2.1 Reminder System (from ERD)
CREATE TABLE IF NOT EXISTS app.reminder (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    
    -- Reminder Details (from ERD)
    reminder_id VARCHAR(50) NOT NULL UNIQUE,
    message VARCHAR(500) NOT NULL,
    time TIMESTAMP WITH TIME ZONE NOT NULL,
    
    -- Timestamps
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_reminder_time ON app.reminder(time);

COMMENT ON TABLE app.reminder IS 'System reminders and notifications';

-- 2.2 Patients (from ERD)
CREATE TABLE IF NOT EXISTS app.patient (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    
    -- Identifiers (from ERD)
    patient_id VARCHAR(50) NOT NULL UNIQUE,
    user_id UUID REFERENCES app.user_account(id) ON DELETE SET NULL,
    
    -- Personal Information (from ERD)
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    email CITEXT NOT NULL UNIQUE,
    phone_num VARCHAR(20) NOT NULL,
    
    -- Additional Info (from ERD)
    address VARCHAR(300),
    birth_date DATE NOT NULL,
    gender VARCHAR(20) CHECK (gender IN ('Male', 'Female', 'Other', 'Prefer not to say')),
    
    -- Emergency Contact
    emergency_contact VARCHAR(100),
    emergency_phone VARCHAR(20),
    
    -- Insurance (from ERD)
    insurance_num VARCHAR(100),
    
    -- Status
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Constraints
    CONSTRAINT ck_patient_email CHECK (email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$'),
    CONSTRAINT ck_patient_birth_date CHECK (birth_date <= CURRENT_DATE)
);

CREATE INDEX IF NOT EXISTS idx_patient_user ON app.patient(user_id);
CREATE INDEX IF NOT EXISTS idx_patient_email ON app.patient(email);
CREATE INDEX IF NOT EXISTS idx_patient_phone ON app.patient(phone_num);

COMMENT ON TABLE app.patient IS 'Patient demographic and contact information';

-- 2.3 Doctors (from ERD)
CREATE TABLE IF NOT EXISTS app.doctor (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    
    -- Identifiers (from ERD)
    doctor_id VARCHAR(50) NOT NULL UNIQUE,
    user_id UUID REFERENCES app.user_account(id) ON DELETE SET NULL,
    
    -- Personal Information (from ERD)
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    email CITEXT NOT NULL UNIQUE,
    phone_num VARCHAR(20) NOT NULL,
    
    -- Professional Information (from ERD)
    license_num VARCHAR(100) NOT NULL UNIQUE,
    qualification VARCHAR(300),
    specialization VARCHAR(200),
    
    -- Gender
    gender VARCHAR(20) CHECK (gender IN ('Male', 'Female', 'Other', 'Prefer not to say')),
    
    -- Timestamps
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Constraints
    CONSTRAINT ck_doctor_email CHECK (email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$')
);

CREATE INDEX IF NOT EXISTS idx_doctor_user ON app.doctor(user_id);
CREATE INDEX IF NOT EXISTS idx_doctor_email ON app.doctor(email);
CREATE INDEX IF NOT EXISTS idx_doctor_license ON app.doctor(license_num);

COMMENT ON TABLE app.doctor IS 'Doctor information and credentials';

-- ============================================================================
-- SECTION 3: PATIENT SYMPTOMS (FROM ERD)
-- ============================================================================

-- 3.1 Patient Symptoms (from ERD - junction table between Patient and symptoms)
CREATE TABLE IF NOT EXISTS app.patient_symptom (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    
    -- Foreign Keys (from ERD)
    patient_id UUID NOT NULL REFERENCES app.patient(id) ON DELETE CASCADE,
    symptom_id VARCHAR(50) NOT NULL, -- Simple ID, no separate symptom table in ERD
    
    -- Symptom Details
    notes TEXT,
    severity VARCHAR(50) CHECK (severity IN ('Mild', 'Moderate', 'Severe', 'Critical')),
    
    -- Dates
    date_reported TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_patient_symptom_patient ON app.patient_symptom(patient_id);
CREATE INDEX IF NOT EXISTS idx_patient_symptom_severity ON app.patient_symptom(severity);

COMMENT ON TABLE app.patient_symptom IS 'Patient reported symptoms';

-- ============================================================================
-- SECTION 4: CONDITIONS (FROM ERD)
-- ============================================================================

-- 4.1 Conditions (from ERD - Medical Conditions/Diagnoses)
CREATE TABLE IF NOT EXISTS app.condition (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    
    -- Condition Details (from ERD)
    condition_id VARCHAR(50) NOT NULL UNIQUE,
    condition_name VARCHAR(200) NOT NULL,
    condition_desc TEXT
);

CREATE INDEX IF NOT EXISTS idx_condition_name ON app.condition(condition_name);

COMMENT ON TABLE app.condition IS 'Medical conditions and diagnoses';

-- ============================================================================
-- SECTION 5: MEDICATIONS & PRESCRIPTIONS (FROM ERD)
-- ============================================================================

-- 5.1 Medications (from ERD - Drug Database)
CREATE TABLE IF NOT EXISTS app.medication (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    
    -- Medication Details (from ERD)
    medication_id VARCHAR(50) NOT NULL UNIQUE,
    med_name VARCHAR(200) NOT NULL,
    med_dose VARCHAR(100), -- e.g., "500mg", "10ml"
    frequency VARCHAR(100), -- e.g., "Twice daily", "Every 8 hours"
    
    -- Status
    is_active BOOLEAN DEFAULT TRUE,
    
    -- Timestamps
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_medication_name ON app.medication(med_name);

COMMENT ON TABLE app.medication IS 'Available medications database';

-- 5.2 Side Effects (from ERD)
CREATE TABLE IF NOT EXISTS app.side_effect (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    
    -- Side Effect Details (from ERD)
    side_effect_id VARCHAR(50) NOT NULL UNIQUE,
    effect_name VARCHAR(200) NOT NULL,
    severity VARCHAR(50) CHECK (severity IN ('Mild', 'Moderate', 'Severe', 'Life-threatening')),
    description TEXT
);

CREATE INDEX IF NOT EXISTS idx_side_effect_name ON app.side_effect(effect_name);
CREATE INDEX IF NOT EXISTS idx_side_effect_severity ON app.side_effect(severity);

COMMENT ON TABLE app.side_effect IS 'Medication side effects database';

-- 5.3 Medication Side Effects (from ERD - Many-to-Many junction table)
CREATE TABLE IF NOT EXISTS app.medication_side_effect (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    
    -- Foreign Keys (from ERD relationship)
    medication_id UUID NOT NULL REFERENCES app.medication(id) ON DELETE CASCADE,
    side_effect_id UUID NOT NULL REFERENCES app.side_effect(id) ON DELETE CASCADE,
    
    -- Additional Info (from ERD - shows "frequency")
    frequency VARCHAR(100), -- How common is this side effect? e.g., "Common (1-10%)"
    
    -- Unique constraint (one medication can't have duplicate side effects)
    CONSTRAINT uq_medication_side_effect UNIQUE(medication_id, side_effect_id)
);

CREATE INDEX IF NOT EXISTS idx_med_side_effect_medication ON app.medication_side_effect(medication_id);
CREATE INDEX IF NOT EXISTS idx_med_side_effect_side_effect ON app.medication_side_effect(side_effect_id);

COMMENT ON TABLE app.medication_side_effect IS 'Links medications to their possible side effects (Many-to-Many)';

-- 5.4 Prescriptions (from ERD - links Patient, Doctor, Medication)
CREATE TABLE IF NOT EXISTS app.prescription (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    
    -- Identifiers (from ERD)
    prescription_id VARCHAR(50) NOT NULL UNIQUE,
    
    -- Foreign Keys (from ERD relationships)
    patient_id UUID NOT NULL REFERENCES app.patient(id) ON DELETE RESTRICT,
    medication_id UUID NOT NULL REFERENCES app.medication(id) ON DELETE RESTRICT,
    doctor_id UUID NOT NULL REFERENCES app.doctor(id) ON DELETE RESTRICT,
    
    -- Prescription Details (from ERD)
    dosage VARCHAR(100) NOT NULL,
    frequency VARCHAR(100) NOT NULL,
    duration VARCHAR(100), -- e.g., "7 days", "2 weeks"
    
    -- Dates
    prescribed_date DATE DEFAULT CURRENT_DATE,
    start_date DATE,
    end_date DATE,
    
    -- Instructions
    instructions TEXT,
    
    -- Status
    status VARCHAR(50) CHECK (status IN ('Active', 'Completed', 'Cancelled')) DEFAULT 'Active',
    
    -- Timestamps
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_prescription_patient ON app.prescription(patient_id);
CREATE INDEX IF NOT EXISTS idx_prescription_medication ON app.prescription(medication_id);
CREATE INDEX IF NOT EXISTS idx_prescription_doctor ON app.prescription(doctor_id);
CREATE INDEX IF NOT EXISTS idx_prescription_status ON app.prescription(status);

COMMENT ON TABLE app.prescription IS 'Patient medication prescriptions linking patients, doctors, and medications';

-- ============================================================================
-- SECTION 6: TRIGGERS FOR AUTOMATIC UPDATES
-- ============================================================================

-- Function to automatically update 'updated_at' timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply trigger to tables with updated_at
CREATE TRIGGER update_patient_updated_at 
    BEFORE UPDATE ON app.patient 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_doctor_updated_at 
    BEFORE UPDATE ON app.doctor 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ============================================================================
-- SECTION 7: INITIAL DATA (Reference Data/Example Data)
-- ============================================================================

-- Insert default conditions (common medical conditions)
INSERT INTO app.condition (condition_id, condition_name, condition_desc) VALUES
('COND001', 'Hypertension', 'High blood pressure'),
('COND002', 'Type 2 Diabetes', 'Diabetes mellitus type 2'),
('COND003', 'Asthma', 'Chronic respiratory condition'),
('COND004', 'Migraine', 'Severe recurring headaches'),
('COND005', 'Arthritis', 'Joint inflammation and pain'),
('COND006', 'Common Cold', 'Upper respiratory tract infection'),
('COND007', 'Flu (Influenza)', 'Viral respiratory infection'),
('COND008', 'Allergic Rhinitis', 'Hay fever')
ON CONFLICT (condition_id) DO NOTHING;

-- ============================================================================
-- COMPLETION MESSAGE
-- ============================================================================

DO $$
BEGIN
    RAISE NOTICE '========================================';
    RAISE NOTICE 'PAKAR Tech Healthcare Schema Created!';
    RAISE NOTICE '========================================';
    RAISE NOTICE 'Tables Created (following ERD):';
    RAISE NOTICE '  User Management: admin, super_admin, user_account';
    RAISE NOTICE '  Core Entities: patient, doctor, reminder';
    RAISE NOTICE '  Medical: patient_symptom, condition';
    RAISE NOTICE '  Medications: medication, side_effect';
    RAISE NOTICE '  Junction Tables: medication_side_effect';
    RAISE NOTICE '  Prescriptions: prescription';
    RAISE NOTICE '';
    RAISE NOTICE 'Entity Relationships (from ERD):';
    RAISE NOTICE '  - Patient (1) ←→ (Many) PatientSymptom';
    RAISE NOTICE '  - Patient (1) ←→ (Many) Prescription';
    RAISE NOTICE '  - Doctor (1) ←→ (Many) Prescription';
    RAISE NOTICE '  - Medication (1) ←→ (Many) Prescription';
    RAISE NOTICE '  - Medication (Many) ←→ (Many) SideEffect';
    RAISE NOTICE '';
    RAISE NOTICE 'Next Steps:';
    RAISE NOTICE '  1. Review schema in pgAdmin';
    RAISE NOTICE '  2. Load seed data: npm run seeds:run';
    RAISE NOTICE '  3. Test queries: npm run queries:test';
    RAISE NOTICE '========================================';
END $$;