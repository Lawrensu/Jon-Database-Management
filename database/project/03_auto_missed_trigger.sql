-- PAKAR Tech Healthcare - Auto-Mark Missed Medications
-- COS 20031 Database Design Project

SET search_path TO app, public;

BEGIN;

-- Function to mark missed medications
CREATE OR REPLACE FUNCTION app.mark_missed_medications()
RETURNS void AS $$
BEGIN
    UPDATE app.medication_log
    SET status = 'Missed'
    WHERE scheduled_time < NOW() - INTERVAL '2 hours'
      AND actual_taken_time IS NULL
      AND status != 'Skipped';
    
    RAISE NOTICE '✅ Marked % medications as Missed', FOUND;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION app.mark_missed_medications() IS 
'Call this function periodically to auto-mark missed medications';

COMMIT;