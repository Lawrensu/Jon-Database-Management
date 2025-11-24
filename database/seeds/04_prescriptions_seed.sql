-- PAKAR Tech Healthcare - Admin Accounts
-- COS 20031 Database Design Project
-- Author: [Cherylynn]

SET search_path TO app, public;

BEGIN;

-- ============================================================================
-- CREATE SAMPLE PRESCRIPTIONS
-- ============================================================================

INSERT INTO app.prescription (patient_id, doctor_id, status, doctor_note, created_date)
SELECT 
    p.patient_id,
    d.doctor_id,
    CASE 
        WHEN random() < 0.6 THEN 'Active'::prescription_status_enum      -- 60% Active
        WHEN random() < 0.8 THEN 'Completed'::prescription_status_enum   -- 20% Completed
        WHEN random() < 0.95 THEN 'Expired'::prescription_status_enum    -- 15% Expired
        ELSE 'Cancelled'::prescription_status_enum                        -- 5% Cancelled
    END AS status,
    'Sample prescription for performance testing' AS doctor_note,
    CURRENT_TIMESTAMP - (random() * 90 || ' days')::INTERVAL AS created_date
FROM app.patient p
CROSS JOIN LATERAL (
    SELECT doctor_id 
    FROM app.doctor 
    ORDER BY RANDOM() 
    LIMIT 1
) d
WHERE p.patient_id <= 150  -- Create prescriptions for first 150 patients
ON CONFLICT DO NOTHING;

COMMIT;

-- ============================================================================
-- VERIFICATION
-- ============================================================================

DO $$
DECLARE
    total_count INT;
    active_count INT;
    completed_count INT;
    expired_count INT;
    cancelled_count INT;
BEGIN
    SELECT COUNT(*) INTO total_count FROM app.prescription;
    SELECT COUNT(*) INTO active_count FROM app.prescription WHERE status = 'Active';
    SELECT COUNT(*) INTO completed_count FROM app.prescription WHERE status = 'Completed';
    SELECT COUNT(*) INTO expired_count FROM app.prescription WHERE status = 'Expired';
    SELECT COUNT(*) INTO cancelled_count FROM app.prescription WHERE status = 'Cancelled';
    
    RAISE NOTICE '========================================';
    RAISE NOTICE 'Prescription Seed Data Loaded';
    RAISE NOTICE '========================================';
    RAISE NOTICE 'Total Prescriptions: %', total_count;
    RAISE NOTICE '  Active: % (%)', active_count, ROUND(active_count * 100.0 / total_count, 1) || '%'; 
    RAISE NOTICE '  Completed: % (%)', completed_count, ROUND(completed_count * 100.0 / total_count, 1) || '%'; 
    RAISE NOTICE '  Expired: % (%)', expired_count, ROUND(expired_count * 100.0 / total_count, 1) || '%';  
    RAISE NOTICE '  Cancelled: % (%)', cancelled_count, ROUND(cancelled_count * 100.0 / total_count, 1) || '%';  
    RAISE NOTICE '========================================';
END $$;