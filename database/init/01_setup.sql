-- PostgreSQL 18 Database Initialization 
-- Note: This script runs automatically when the database is first created

-- Essential extensions 
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";     -- UUID generation
CREATE EXTENSION IF NOT EXISTS "pgcrypto";      -- Cryptographic functions
CREATE EXTENSION IF NOT EXISTS "citext";        -- Case-insensitive text

-- Database configuration
ALTER DATABASE jon_database_dev SET timezone TO 'UTC';
ALTER DATABASE jon_database_dev SET datestyle TO 'ISO, MDY';

-- Create application schema (keeps things organized)
CREATE SCHEMA IF NOT EXISTS app;
CREATE SCHEMA IF NOT EXISTS logs;

-- Create a dedicated application user (recommended for production-like setup)
DO $$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = 'app_user') THEN
        CREATE USER app_user WITH PASSWORD 'JonathanBangerDatabase26!';
        GRANT CONNECT ON DATABASE jon_database_dev TO app_user;
        GRANT USAGE ON SCHEMA app TO app_user;
        GRANT USAGE ON SCHEMA public TO app_user;
        GRANT CREATE ON SCHEMA app TO app_user;
    END IF;
END
$$;

-- Log successful initialization
DO $$
BEGIN
    RAISE NOTICE '========================================';
    RAISE NOTICE 'Jon Database Management Project';
    RAISE NOTICE 'PostgreSQL 18 Database Initialized!';
    RAISE NOTICE '========================================';
    RAISE NOTICE 'Database: jon_database_dev';
    RAISE NOTICE 'Extensions: uuid-ossp, pgcrypto, citext';
    RAISE NOTICE 'Schemas: public, app, logs';
    RAISE NOTICE 'Version: %', version();
    RAISE NOTICE '========================================';
END $$;