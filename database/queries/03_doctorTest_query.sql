-- PAKAR Tech Healthcare - Doctor Workflow Test Script
-- COS 20031 Database Design Project
-- This version uses REAL test data and can be executed directly

SET search_path TO app, public;

BEGIN;

-- ============================================================================
-- SETUP: Create patient-doctor assignment table
-- ============================================================================
CREATE TABLE IF NOT EXISTS app.patient_doctor (
    patient_id       INT               NOT NULL REFERENCES app.patient(patient_id),
    doctor_id        INT               NOT NULL REFERENCES app.doctor(doctor_id),
    assigned_by      INT               NULL,
    assigned_at      TIMESTAMPTZ       NOT NULL DEFAULT now(),
    PRIMARY KEY (patient_id, doctor_id)
);

-- ============================================================================
-- TEST 1: Assign first patient to first doctor
-- ============================================================================
INSERT INTO app.patient_doctor (patient_id, doctor_id, assigned_by)
SELECT 
    (SELECT patient_id FROM app.patient LIMIT 1) AS patient_id,
    (SELECT doctor_id FROM app.doctor LIMIT 1) AS doctor_id,
    (SELECT user_id FROM app.user_account WHERE user_type = 'Admin' LIMIT 1) AS assigned_by
WHERE EXISTS (SELECT 1 FROM app.patient)
  AND EXISTS (SELECT 1 FROM app.doctor)
ON CONFLICT (patient_id, doctor_id) DO UPDATE 
  SET assigned_at = now();

-- ============================================================================
-- TEST 2: List patients for first doctor
-- ============================================================================
SELECT p.patient_id,
       u.email,
       p.birth_date,
       pd.assigned_at
FROM app.patient p
JOIN app.patient_doctor pd USING (patient_id)
JOIN app.user_account u ON p.user_id = u.user_id
WHERE pd.doctor_id = (SELECT doctor_id FROM app.doctor LIMIT 1)
ORDER BY pd.assigned_at DESC;

-- ============================================================================
-- TEST 3: Record a symptom for first patient
-- ============================================================================
INSERT INTO app.patient_symptom (patient_id, symptom_id, date_reported, severity, notes)
SELECT 
    (SELECT patient_id FROM app.patient LIMIT 1),
    (SELECT symptom_id FROM app.symptom LIMIT 1),
    now(),
    'Moderate',
    'Test symptom entry'
WHERE EXISTS (SELECT 1 FROM app.patient)
  AND EXISTS (SELECT 1 FROM app.symptom);

-- ============================================================================
-- TEST 4: Create prescription with schedule (simplified version)
-- ============================================================================
DO $$
DECLARE
    v_prescription_id INT;
    v_patient_id INT;
    v_doctor_id INT;
    v_medication_id INT;
    v_version_id INT;
    v_schedule_id INT;
BEGIN
    -- Get test data IDs
    SELECT patient_id INTO v_patient_id FROM app.patient LIMIT 1;
    SELECT doctor_id INTO v_doctor_id FROM app.doctor LIMIT 1;
    SELECT medication_id INTO v_medication_id FROM app.medication LIMIT 1;
    
    IF v_patient_id IS NOT NULL AND v_doctor_id IS NOT NULL AND v_medication_id IS NOT NULL THEN
        -- Create prescription if none exists
        IF NOT EXISTS (SELECT 1 FROM app.prescription LIMIT 1) THEN
            INSERT INTO app.prescription (patient_id, doctor_id, status, created_date, doctor_note)
            VALUES (v_patient_id, v_doctor_id, 'Active', now(), 'Test prescription for workflow testing')
            RETURNING prescription_id INTO v_prescription_id;
        ELSE
            SELECT prescription_id INTO v_prescription_id FROM app.prescription LIMIT 1;
        END IF;
        
        -- Create prescription version
        INSERT INTO app.prescription_version (
            prescription_id, 
            medication_id, 
            titration, 
            titration_unit, 
            start_date, 
            end_date, 
            reason_for_change
        ) VALUES (
            v_prescription_id,
            v_medication_id,
            500,
            'mg',
            CURRENT_TIMESTAMP,
            CURRENT_TIMESTAMP + INTERVAL '30 days',
            'Initial prescription - test workflow'
        ) RETURNING prescription_version_id INTO v_version_id;
        
        -- Create medication schedule
        INSERT INTO app.medication_schedule (
            prescription_version_id,
            med_timing,
            frequency_times_per_day,
            frequency_interval_hours,
            duration,
            duration_unit
        ) VALUES (
            v_version_id,
            'AfterMeal',
            2,
            12,
            30,
            'Days'
        ) RETURNING medication_schedule_id INTO v_schedule_id;
        
        -- Create reminders
        INSERT INTO app.reminder (patient_id, medication_schedule_id, message, schedule)
        VALUES 
            (v_patient_id, v_schedule_id, 'Morning medication reminder', CURRENT_DATE + INTERVAL '1 day' + TIME '08:00'),
            (v_patient_id, v_schedule_id, 'Evening medication reminder', CURRENT_DATE + INTERVAL '1 day' + TIME '20:00');
        
        RAISE NOTICE 'Created prescription version: %, schedule: %', v_version_id, v_schedule_id;
    ELSE
        RAISE NOTICE 'Skipping prescription test: missing patient, doctor, or medication data';
    END IF;
END $$;

-- ============================================================================
-- TEST 5: Show created reminders
-- ============================================================================
SELECT r.reminder_id,
       r.schedule AS remind_at,
       r.message,
       p.patient_id,
       ms.medication_schedule_id
FROM app.reminder r
JOIN app.medication_schedule ms ON r.medication_schedule_id = ms.medication_schedule_id
JOIN app.patient p ON r.patient_id = p.patient_id
ORDER BY r.schedule DESC
LIMIT 10;

COMMIT;

-- ============================================================================
-- SUMMARY REPORT
-- ============================================================================
SELECT 
    'Patient-Doctor Assignments' AS metric,
    COUNT(*)::text AS count
FROM app.patient_doctor
UNION ALL
SELECT 
    'Patient Symptoms Recorded',
    COUNT(*)::text
FROM app.patient_symptom
UNION ALL
SELECT 
    'Active Prescriptions',
    COUNT(*)::text
FROM app.prescription WHERE status = 'Active'
UNION ALL
SELECT 
    'Medication Schedules',
    COUNT(*)::text
FROM app.medication_schedule
UNION ALL
SELECT 
    'Upcoming Reminders',
    COUNT(*)::text
FROM app.reminder WHERE schedule >= now();