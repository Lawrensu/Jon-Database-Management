-- PAKAR Tech Healthcare - Admin Accounts
-- COS 20031 Database Design Project
-- Author: [Cherylynn]

SET search_path TO app, public;

BEGIN;

-- ============================================================================
-- SECTION 1: CREATE USER ACCOUNTS FOR ADMINS
-- ============================================================================

INSERT INTO app.user_account (
    username, 
    password,
    user_type, 
    first_name,
    last_name,
    email,
    is_active, 
    created_at
) VALUES
-- Regular Admins
('admin.john', decode('73656564', 'hex'), 'Admin', 'John', 'Tan', 'john.tan@pakartech.com', TRUE, '2023-01-15'),
('admin.sarah', decode('73656564', 'hex'), 'Admin', 'Sarah', 'Lee', 'sarah.lee@pakartech.com', TRUE, '2023-02-20'),
('admin.ahmad', decode('73656564', 'hex'), 'Admin', 'Ahmad', 'Rahman', 'ahmad.rahman@pakartech.com', TRUE, '2023-03-10'),

-- Super Admins
('superadmin.david', decode('73656564', 'hex'), 'SuperAdmin', 'David', 'Wong', 'david.wong@pakartech.com', TRUE, '2022-12-01'),
('superadmin.priya', decode('73656564', 'hex'), 'SuperAdmin', 'Priya', 'Kumar', 'priya.kumar@pakartech.com', TRUE, '2022-12-01')

ON CONFLICT (username) DO NOTHING;

-- ============================================================================
-- SECTION 2: CREATE ADMIN ENTRIES
-- ============================================================================

INSERT INTO app.admin (user_id, username, created_at)
SELECT 
    user_id,
    username,
    created_at
FROM app.user_account
WHERE user_type = 'Admin'
ON CONFLICT (user_id) DO NOTHING;

-- ============================================================================
-- SECTION 3: CREATE SUPER ADMIN ENTRIES
-- ============================================================================

INSERT INTO app.super_admin (user_id, username, created_at)
SELECT 
    user_id,
    username,
    created_at
FROM app.user_account
WHERE user_type = 'SuperAdmin'
ON CONFLICT (user_id) DO NOTHING;

COMMIT;

-- ============================================================================
-- VERIFICATION
-- ============================================================================

DO $$
DECLARE
    admin_count INT;
    super_admin_count INT;
BEGIN
    SELECT COUNT(*) INTO admin_count FROM app.admin;
    SELECT COUNT(*) INTO super_admin_count FROM app.super_admin;
    
    RAISE NOTICE '========================================';
    RAISE NOTICE 'Admin Seed Data Loaded';
    RAISE NOTICE '========================================';
    RAISE NOTICE 'Regular Admins: % accounts', admin_count;
    RAISE NOTICE 'Super Admins: % accounts', super_admin_count;
    RAISE NOTICE '';
    RAISE NOTICE 'Default password for all: "seed" (hash: 73656564)';
    RAISE NOTICE '========================================';
END $$;