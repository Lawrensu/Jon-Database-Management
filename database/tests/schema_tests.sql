-- Simple schema test to check if key tables exist
-- Replace 'patients', 'doctors', 'appointments' with your actual table names
DO $$     BEGIN
    -- Check for the existence of the 'app' schema
    IF NOT EXISTS (SELECT 1 FROM information_schema.schemata WHERE schema_name = 'app') THEN
        RAISE EXCEPTION 'Schema "app" does not exist.';
    END IF;

    -- Check for the existence of tables within the 'app' schema
    IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'app' AND table_name = 'patients') THEN
        RAISE EXCEPTION 'Table "app.patients" does not exist.';
    END IF;

    IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'app' AND table_name = 'doctors') THEN
        RAISE EXCEPTION 'Table "app.doctors" does not exist.';
    END IF;

    IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'app' AND table_name = 'appointments') THEN
        RAISE EXCEPTION 'Table "app.appointments" does not exist.';
    END IF;

    RAISE NOTICE 'All schema tests passed successfully!';
END $$;