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
-- SECTION 1: USER MANAGEMENT (Admin, SuperAdmin, User)
-- ============================================================================

-- 1.1 Admin (from ERD top-left)
CREATE TABLE IF NOT EXISTS app.admin (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    
    -- From ERD: AdminID, UserID
    admin_id VARCHAR(50) NOT NULL UNIQUE,
    user_id VARCHAR(50) NOT NULL UNIQUE,
    
    -- From ERD: Username, Password, CreatedAt
    username VARCHAR(50) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_admin_username ON app.admin(username);
COMMENT ON TABLE app.admin IS 'Admin users - from ERD';

-- 1.2 SuperAdmin (from ERD top-center)
CREATE TABLE IF NOT EXISTS app.super_admin (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    
    -- From ERD: SuperAdminID, UserID
    super_admin_id VARCHAR(50) NOT NULL UNIQUE,
    user_id VARCHAR(50) NOT NULL UNIQUE,
    
    -- From ERD: Username, Password, CreatedAt
    username VARCHAR(50) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_super_admin_username ON app.super_admin(username);
COMMENT ON TABLE app.super_admin IS 'Super admin users - from ERD';

-- 1.3 User (from ERD top-right)
CREATE TABLE IF NOT EXISTS app.user_account (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    
    -- From ERD: UserID
    user_id VARCHAR(50) NOT NULL UNIQUE,
    
    -- From ERD: Username, Password, UserType, isActive, CreatedAt
    username VARCHAR(50) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    user_type VARCHAR(20) NOT NULL CHECK (user_type IN ('Patient', 'Doctor')),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_user_username ON app.user_account(username);
CREATE INDEX IF NOT EXISTS idx_user_type ON app.user_account(user_type);
COMMENT ON TABLE app.user_account IS 'Regular users (Patient/Doctor) - from ERD';

-- ============================================================================
-- SECTION 2: CORE ENTITIES (Reminder, Patient, Doctor)
-- ============================================================================

-- 2.1 Reminder (from ERD - links to Patient via MedicationSchedule)
CREATE TABLE IF NOT EXISTS app.reminder (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    
    -- From ERD: ReminderID, PatientID
    reminder_id VARCHAR(50) NOT NULL UNIQUE,
    patient_id UUID REFERENCES app.user_account(id) ON DELETE CASCADE,
    
    -- From ERD: MedicationScheduleID (linked later)
    medication_schedule_id UUID,
    
    -- From ERD: Message, Schedule
    message VARCHAR(500) NOT NULL,
    schedule TIMESTAMP WITH TIME ZONE NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_reminder_patient ON app.reminder(patient_id);
CREATE INDEX IF NOT EXISTS idx_reminder_schedule ON app.reminder(schedule);
COMMENT ON TABLE app.reminder IS 'Patient reminders - from ERD';

-- 2.2 Patient (from ERD center-left)
CREATE TABLE IF NOT EXISTS app.patient (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    
    -- From ERD: PatientID, UserID
    patient_id VARCHAR(50) NOT NULL UNIQUE,
    user_id UUID REFERENCES app.user_account(id) ON DELETE SET NULL,
    
    -- From ERD: PhoneNum, BirthDate, Gender, Address
    phone_num VARCHAR(20) NOT NULL,
    birth_date DATE NOT NULL,
    gender VARCHAR(20) CHECK (gender IN ('Male', 'Female', 'Other')),
    address VARCHAR(300),
    
    -- From ERD: EmergencyContactName, EmergencyContactPhone
    emergency_contact_name VARCHAR(100),
    emergency_contact_phone VARCHAR(20),
    
    -- From ERD: CreatedAt, UpdatedAt
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    CONSTRAINT ck_patient_birth_date CHECK (birth_date <= CURRENT_DATE)
);

CREATE INDEX IF NOT EXISTS idx_patient_user ON app.patient(user_id);
CREATE INDEX IF NOT EXISTS idx_patient_phone ON app.patient(phone_num);
COMMENT ON TABLE app.patient IS 'Patient information - from ERD';

-- 2.3 Doctor (from ERD center-right)
CREATE TABLE IF NOT EXISTS app.doctor (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    
    -- From ERD: DoctorID, UserID
    doctor_id VARCHAR(50) NOT NULL UNIQUE,
    user_id UUID REFERENCES app.user_account(id) ON DELETE SET NULL,
    
    -- From ERD: PhoneNum, LicenseNum, LicenseExp
    phone_num VARCHAR(20) NOT NULL,
    license_num VARCHAR(100) NOT NULL UNIQUE,
    license_exp DATE NOT NULL,
    
    -- From ERD: Gender, Specialization, Qualification
    gender VARCHAR(20) CHECK (gender IN ('Male', 'Female', 'Other')),
    specialization VARCHAR(200),
    qualification VARCHAR(300),
    
    -- From ERD: CreatedAt, UpdatedAt
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_doctor_user ON app.doctor(user_id);
CREATE INDEX IF NOT EXISTS idx_doctor_license ON app.doctor(license_num);
COMMENT ON TABLE app.doctor IS 'Doctor information - from ERD';

-- ============================================================================
-- SECTION 3: MEDICAL (Condition, Symptom, PatientSymptom)
-- ============================================================================

-- 3.1 Condition (from ERD bottom-center)
CREATE TABLE IF NOT EXISTS app.condition (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    
    -- From ERD: ConditionID
    condition_id VARCHAR(50) NOT NULL UNIQUE,
    
    -- From ERD: ConditionName, ConditionDesc
    condition_name VARCHAR(200) NOT NULL,
    condition_desc TEXT
);

CREATE INDEX IF NOT EXISTS idx_condition_name ON app.condition(condition_name);
COMMENT ON TABLE app.condition IS 'Medical conditions - from ERD';

-- 3.2 Symptom (from ERD bottom-left, linked to Condition) -- RENAMED TO SINGULAR!
CREATE TABLE IF NOT EXISTS app.symptom (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    
    -- From ERD: SymptomID, ConditionID (FK)
    symptom_id VARCHAR(50) NOT NULL UNIQUE,
    condition_id UUID REFERENCES app.condition(id) ON DELETE SET NULL,
    
    -- From ERD: Notes, Severity, DateReported
    notes TEXT,
    severity VARCHAR(20) CHECK (severity IN ('Mild', 'Moderate', 'Severe')),
    date_reported TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_symptom_condition ON app.symptom(condition_id);
CREATE INDEX IF NOT EXISTS idx_symptom_severity ON app.symptom(severity);
COMMENT ON TABLE app.symptom IS 'Symptom definitions - from ERD';

-- 3.3 PatientSymptom (from ERD - junction table Patient ↔ Symptom)
CREATE TABLE IF NOT EXISTS app.patient_symptom (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    
    -- From ERD: PatientID, SymptomID (Many-to-Many)
    patient_id UUID NOT NULL REFERENCES app.patient(id) ON DELETE CASCADE,
    symptom_id UUID NOT NULL REFERENCES app.symptom(id) ON DELETE CASCADE, -- UPDATED REFERENCE!
    
    -- From ERD: DateReported (when patient reported this symptom)
    date_reported TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    CONSTRAINT uq_patient_symptom UNIQUE(patient_id, symptom_id, date_reported)
);

CREATE INDEX IF NOT EXISTS idx_patient_symptom_patient ON app.patient_symptom(patient_id);
CREATE INDEX IF NOT EXISTS idx_patient_symptom_symptom ON app.patient_symptom(symptom_id);
COMMENT ON TABLE app.patient_symptom IS 'Patient-Symptom junction - from ERD';

-- ============================================================================
-- SECTION 4: MEDICATIONS (Medication, SideEffect, MedicationSideEffect)
-- ============================================================================

-- 4.1 Medication (from ERD right side)
CREATE TABLE IF NOT EXISTS app.medication (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    
    -- From ERD: MedicationID
    medication_id VARCHAR(50) NOT NULL UNIQUE,
    
    -- From ERD: MedName, MedBrandName, Manufacturer, MedDose
    med_name VARCHAR(200) NOT NULL,
    med_brand_name VARCHAR(200),
    manufacturer VARCHAR(200),
    med_dose VARCHAR(100)
);

CREATE INDEX IF NOT EXISTS idx_medication_name ON app.medication(med_name);
COMMENT ON TABLE app.medication IS 'Available medications - from ERD';

-- 4.2 SideEffect (from ERD right side, linked to Condition)
CREATE TABLE IF NOT EXISTS app.side_effect (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    
    -- From ERD: SideEffectID, ConditionID (FK)
    side_effect_id VARCHAR(50) NOT NULL UNIQUE,
    condition_id UUID REFERENCES app.condition(id) ON DELETE SET NULL
);

CREATE INDEX IF NOT EXISTS idx_side_effect_condition ON app.side_effect(condition_id);
COMMENT ON TABLE app.side_effect IS 'Medication side effects - from ERD';

-- 4.3 MedicationSideEffect (from ERD - junction Medication ↔ SideEffect)
CREATE TABLE IF NOT EXISTS app.medication_side_effect (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    
    -- From ERD: MedicationID, SideEffectID, Frequency
    medication_id UUID NOT NULL REFERENCES app.medication(id) ON DELETE CASCADE,
    side_effect_id UUID NOT NULL REFERENCES app.side_effect(id) ON DELETE CASCADE,
    frequency VARCHAR(100),
    
    CONSTRAINT uq_medication_side_effect UNIQUE(medication_id, side_effect_id)
);

CREATE INDEX IF NOT EXISTS idx_med_side_effect_medication ON app.medication_side_effect(medication_id);
CREATE INDEX IF NOT EXISTS idx_med_side_effect_side_effect ON app.medication_side_effect(side_effect_id);
COMMENT ON TABLE app.medication_side_effect IS 'Medication-SideEffect junction - from ERD';

-- ============================================================================
-- SECTION 5: PRESCRIPTIONS (Prescription, PrescriptionVersion)
-- ============================================================================

-- 5.1 Prescription (from ERD - links Patient, Doctor)
CREATE TABLE IF NOT EXISTS app.prescription (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    
    -- From ERD: PrescriptionID, PatientID, DoctorID
    prescription_id VARCHAR(50) NOT NULL UNIQUE,
    patient_id UUID NOT NULL REFERENCES app.patient(id) ON DELETE RESTRICT,
    doctor_id UUID NOT NULL REFERENCES app.doctor(id) ON DELETE RESTRICT,
    
    -- From ERD: CreatedDate, Status, DoctorNote
    created_date TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    status VARCHAR(50) CHECK (status IN ('Active', 'Completed', 'Cancelled', 'Expired')) DEFAULT 'Active',
    doctor_note TEXT
);

CREATE INDEX IF NOT EXISTS idx_prescription_patient ON app.prescription(patient_id);
CREATE INDEX IF NOT EXISTS idx_prescription_doctor ON app.prescription(doctor_id);
CREATE INDEX IF NOT EXISTS idx_prescription_status ON app.prescription(status);
COMMENT ON TABLE app.prescription IS 'Prescription master record - from ERD';

-- 5.2 PrescriptionVersion (from ERD - tracks prescription changes)
CREATE TABLE IF NOT EXISTS app.prescription_version (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    
    -- From ERD: PrescriptionVersionID, PrescriptionID, MedicationID
    prescription_version_id VARCHAR(50) NOT NULL UNIQUE,
    prescription_id UUID NOT NULL REFERENCES app.prescription(id) ON DELETE CASCADE,
    medication_id UUID NOT NULL REFERENCES app.medication(id) ON DELETE RESTRICT,
    
    -- From ERD: Titration, TitrationUnit, StartDate, EndDate
    titration DECIMAL(10,2),
    titration_unit VARCHAR(50) CHECK (titration_unit IN ('mg', 'ml', 'tablets', 'capsules', 'units')),
    start_date TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    end_date TIMESTAMP WITH TIME ZONE, -- NULL = active version
    
    -- From ERD: ReasonForChange
    reason_for_change TEXT
);

CREATE INDEX IF NOT EXISTS idx_prescription_version_prescription ON app.prescription_version(prescription_id);
CREATE INDEX IF NOT EXISTS idx_prescription_version_medication ON app.prescription_version(medication_id);
CREATE INDEX IF NOT EXISTS idx_prescription_version_dates ON app.prescription_version(start_date, end_date);
COMMENT ON TABLE app.prescription_version IS 'Prescription version history - from ERD (immutable audit trail)';

-- ============================================================================
-- SECTION 6: MEDICATION TRACKING (MedicationSchedule, MedicationLog)
-- ============================================================================

-- 6.1 MedicationSchedule (from ERD - defines when to take medication)
CREATE TABLE IF NOT EXISTS app.medication_schedule (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    
    -- From ERD: MedicationScheduleID, PrescriptionVersionID
    medication_schedule_id VARCHAR(50) NOT NULL UNIQUE,
    prescription_version_id UUID NOT NULL REFERENCES app.prescription_version(id) ON DELETE CASCADE,
    
    -- From ERD: MedTiming
    med_timing VARCHAR(50) CHECK (med_timing IN ('BeforeMeal', 'AfterMeal')),
    
    -- From ERD: Frequency (split into times and interval for flexibility)
    frequency_times_daily INT CHECK (frequency_times_daily >= 1 AND frequency_times_daily <= 6),
    frequency_interval_hours INT CHECK (frequency_interval_hours >= 1 AND frequency_interval_hours <= 24),
    
    -- From ERD: Duration, DurationUnit
    duration INT,
    duration_unit VARCHAR(50) CHECK (duration_unit IN ('Days', 'Weeks', 'Months')),
    
    -- From ERD: UpdatedAt
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_med_schedule_prescription_version ON app.medication_schedule(prescription_version_id);
COMMENT ON TABLE app.medication_schedule IS 'Medication schedule definition - from ERD';

-- 6.2 MedicationLog (from ERD - tracks actual medication intake)
CREATE TABLE IF NOT EXISTS app.medication_log (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    
    -- From ERD: MedicationLogID, PatientID, MedicationID, MedicationScheduleID
    medication_log_id VARCHAR(50) NOT NULL UNIQUE,
    patient_id UUID NOT NULL REFERENCES app.patient(id) ON DELETE CASCADE,
    medication_id UUID NOT NULL REFERENCES app.medication(id) ON DELETE RESTRICT,
    medication_schedule_id UUID REFERENCES app.medication_schedule(id) ON DELETE SET NULL,
    
    -- From ERD: Notes, ScheduledTime, ActualTakenTime, Status
    notes TEXT,
    scheduled_time TIMESTAMP WITH TIME ZONE NOT NULL,
    actual_taken_time TIMESTAMP WITH TIME ZONE,
    status VARCHAR(50) CHECK (status IN ('Taken', 'Missed', 'Skipped')) DEFAULT 'Missed'
);

CREATE INDEX IF NOT EXISTS idx_med_log_patient ON app.medication_log(patient_id);
CREATE INDEX IF NOT EXISTS idx_med_log_medication ON app.medication_log(medication_id);
CREATE INDEX IF NOT EXISTS idx_med_log_schedule ON app.medication_log(medication_schedule_id);
CREATE INDEX IF NOT EXISTS idx_med_log_status ON app.medication_log(status);
CREATE INDEX IF NOT EXISTS idx_med_log_scheduled_time ON app.medication_log(scheduled_time);
COMMENT ON TABLE app.medication_log IS 'Medication adherence log - from ERD';

-- Now link Reminder to MedicationSchedule (foreign key was deferred)
ALTER TABLE app.reminder 
ADD CONSTRAINT fk_reminder_medication_schedule 
FOREIGN KEY (medication_schedule_id) REFERENCES app.medication_schedule(id) ON DELETE CASCADE;

CREATE INDEX IF NOT EXISTS idx_reminder_med_schedule ON app.reminder(medication_schedule_id);

-- ============================================================================
-- SECTION 7: TRIGGERS (Auto-update timestamps)
-- ============================================================================

CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
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
-- SECTION 8: REFERENCE DATA (Common conditions and symptom)
-- ============================================================================

-- Insert common conditions
INSERT INTO app.condition (condition_id, condition_name, condition_desc) VALUES
('COND001', 'Hypertension', 'High blood pressure'),
('COND002', 'Type 2 Diabetes', 'Diabetes mellitus type 2'),
('COND003', 'Asthma', 'Chronic respiratory condition'),
('COND004', 'Migraine', 'Severe recurring headaches'),
('COND005', 'Arthritis', 'Joint inflammation and pain')
ON CONFLICT (condition_id) DO NOTHING;

-- Insert common symptoms 
INSERT INTO app.symptom (symptom_id, notes, severity) VALUES
('SYMP001', 'Headache', 'Mild'),
('SYMP002', 'Fever', 'Moderate'),
('SYMP003', 'Cough', 'Mild'),
('SYMP004', 'Chest Pain', 'Severe'),
('SYMP005', 'Nausea', 'Mild')
ON CONFLICT (symptom_id) DO NOTHING;

-- ============================================================================
-- COMPLETION MESSAGE
-- ============================================================================

DO $$
BEGIN
    RAISE NOTICE '========================================';
    RAISE NOTICE 'PAKAR Tech Schema Created';
    RAISE NOTICE '========================================';
    RAISE NOTICE 'Tables Created (16 - exactly from ERD):';
    RAISE NOTICE '  1. admin';
    RAISE NOTICE '  2. super_admin';
    RAISE NOTICE '  3. user_account';
    RAISE NOTICE '  4. reminder';
    RAISE NOTICE '  5. patient';
    RAISE NOTICE '  6. doctor';
    RAISE NOTICE '  7. symptom (singular!)';
    RAISE NOTICE '  8. patient_symptom (junction)';
    RAISE NOTICE '  9. condition';
    RAISE NOTICE '  10. medication';
    RAISE NOTICE '  11. side_effect';
    RAISE NOTICE '  12. medication_side_effect (junction)';
    RAISE NOTICE '  13. prescription';
    RAISE NOTICE '  14. prescription_version';
    RAISE NOTICE '  15. medication_schedule';
    RAISE NOTICE '  16. medication_log';
    RAISE NOTICE '========================================';
END $$;

COMMIT;