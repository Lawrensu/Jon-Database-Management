-- Simple data integrity test to check if seed data was loaded
-- Replace with your actual table names and expected counts
DO $$     DECLARE
    patient_count INTEGER;
    doctor_count INTEGER;
BEGIN
    -- Check if seed data exists in the 'patients' table
    SELECT COUNT(*) INTO patient_count FROM app.patients;
    IF patient_count = 0 THEN
        RAISE EXCEPTION 'No seed data found in "app.patients" table.';
    END IF;

    -- Check if seed data exists in the 'doctors' table
    SELECT COUNT(*) INTO doctor_count FROM app.doctors;
    IF doctor_count = 0 THEN
        RAISE EXCEPTION 'No seed data found in "app.doctors" table.';
    END IF;

    RAISE NOTICE 'Data integrity tests passed! Found % patients and % doctors.', patient_count, doctor_count;
END $$;