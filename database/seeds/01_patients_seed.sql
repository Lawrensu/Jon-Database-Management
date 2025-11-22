-- PAKAR Tech Healthcare - Patient Sample Data
-- COS 20031 Database Design Project
-- Author: [Cherylynn Cassidy]

-- ============================================================================
-- PATIENT SAMPLE DATA
-- ============================================================================

-- Set search path to use 'app' schema
SET search_path TO app, public;

BEGIN;

WITH params AS (
  SELECT
    ARRAY[
      'Ahmad','Siti','Lee','Rajesh','Amira','Nur','Wei','Tan','Kumar','Priya',
      'Hassan','Lim','Chen','Soo','Goh','Zainab','Aishah','Faizal','Suresh','Mei',
      'Ling','Arun','Nurul','Farah','Ismail','Anita','Sofia','Hadi','Ibrahim','Ravi',
      'Sanjay','Lily','Grace','Ethan','Noor','Hana','Azman','Fauzi','Syafiq','Wong'
    ]::text[] AS first_names,
    ARRAY[
      'Abdullah','Rahman','Chen','Menon','Hassan','Lim','Tan','Kumar','Singh','Sharma',
      'Nair','Patel','Lee','Gomez','Ng','Ong','Sulaiman','Mohamad','Aziz','Mustafa'
    ]::text[] AS last_names,
    ARRAY['bin','binti','a/l','a/p','']::text[] AS middle_names,
    ARRAY['Bukit Bintang','Tun Razak','Jalan Ampang','Cheras','Bangsar','SS2','Damansara','Subang Jaya','Shah Alam','Kelana Jaya']::text[] AS streets,
    ARRAY['Kuala Lumpur','Petaling Jaya','Subang Jaya','Shah Alam']::text[] AS cities,
    ARRAY['Selangor','Kuala Lumpur']::text[] AS states,
    ARRAY['53100','50450','50400','46000','40150','47301','40100','68000','68100','43200']::text[] AS postals,
    ARRAY['12','13','14','16','17','18','19']::text[] AS mobile_prefixes
),
gen AS (
  SELECT
    g,
    -- indexing helpers
    params.first_names[((g-1) % cardinality(params.first_names)) + 1] AS first_name,
    params.last_names[((g-1) % cardinality(params.last_names)) + 1] AS last_name,
    params.middle_names[((g-1) % cardinality(params.middle_names)) + 1] AS middle_name,
    params.streets[((g-1) % cardinality(params.streets)) + 1] AS street,
    params.cities[((g-1) % cardinality(params.cities)) + 1] AS city,
    params.states[((g-1) % cardinality(params.states)) + 1] AS state,
    params.postals[((g-1) % cardinality(params.postals)) + 1] AS postal_code,
    params.mobile_prefixes[((g-1) % cardinality(params.mobile_prefixes)) + 1] AS mobile_prefix,
    -- age distribution: children (~20%), teens (~10%), adults (~50%), seniors (~20%)
    CASE
      WHEN (g % 10) < 2 THEN floor(random()*13)::int                         -- 0-12
      WHEN (g % 10) < 4 THEN (floor(random()*5)::int + 13)                  -- 13-17
      WHEN (g % 10) < 9 THEN (floor(random()*47)::int + 18)                 -- 18-64
      ELSE (floor(random()*26)::int + 65)                                   -- 65-90
    END AS age_years,
    -- Phone as BIGINT (no dashes, format: 60XXXXXXXXXX for Malaysian mobile)
    (60120000000::bigint + floor(random() * 99999999)::bigint) AS phone_num,
    (60130000000::bigint + floor(random() * 99999999)::bigint) AS emergency_phone,
    -- address line generation
    ('No. ' || (100 + ((g*13) % 900))::text) AS address_line1,
    CASE WHEN random() < 0.35 THEN ('Apartment ' || ((g % 30) + 1)::text) ELSE NULL END AS address_line2,
    -- emergency contact
    ('EC ' || params.last_names[((g-1) % cardinality(params.last_names)) + 1] || ' ' || ((g % 7)+1)::text) AS emergency_contact_name,
    -- registration date in last ~18 months
    (CURRENT_DATE - ((floor(random()*540)::int) * INTERVAL '1 day'))::date AS registration_date
  FROM generate_series(1,200) g
  CROSS JOIN params
),
-- Step 1: Create user_account rows first and return their IDs
user_inserts AS (
  INSERT INTO app.user_account (user_id, username, password_hash, user_type, is_active, created_at)
  SELECT
    'P' || LPAD(g::text, 6, '0') AS user_id,
    lower(first_name || '.' || last_name || g::text) AS username,
    '$2a$10$abcdefghijklmnopqrstuv' AS password_hash, -- bcrypt hash placeholder
    'Patient' AS user_type,
    TRUE AS is_active,
    registration_date::timestamp AS created_at
  FROM gen
  ON CONFLICT (username) DO NOTHING
  RETURNING id, username
)
-- Step 2: Insert patients
INSERT INTO app.patient (
  patient_id,
  user_id,
  phone_num,
  birth_date,
  gender,
  address,
  emergency_contact_name,
  emergency_contact_phone,
  created_at,
  updated_at
)
SELECT
  'P' || LPAD(gen.g::text, 6, '0') AS patient_id,
  ui.id AS user_id,
  gen.phone_num::text AS phone_num,
  (CURRENT_DATE - ((gen.age_years * 365) + floor(random() * 365)::int) * INTERVAL '1 day')::date AS birth_date,
  CASE (gen.g % 3)
    WHEN 0 THEN 'Male'
    WHEN 1 THEN 'Female'
    ELSE 'Other'
  END AS gender,
  (gen.address_line1 || COALESCE(' ' || gen.address_line2, '') || ', ' || gen.city || ', ' || gen.state || ' ' || gen.postal_code) AS address,
  gen.emergency_contact_name,
  gen.emergency_phone::text AS emergency_contact_phone,
  gen.registration_date::timestamp AS created_at,
  gen.registration_date::timestamp AS updated_at
FROM gen
JOIN user_inserts ui ON ui.username = lower(gen.first_name || '.' || gen.last_name || gen.g::text)
ON CONFLICT (patient_id) DO NOTHING;

COMMIT;

-- Verification
DO $$
DECLARE
    patient_count INT;
    user_count INT;
BEGIN
    SELECT COUNT(*) INTO patient_count FROM app.patient;
    SELECT COUNT(*) INTO user_count FROM app.user_account WHERE user_type = 'Patient';
    
    RAISE NOTICE '========================================';
    RAISE NOTICE 'Patient Seed Data Loaded';
    RAISE NOTICE '========================================';
    RAISE NOTICE 'Patients: % records', patient_count;
    RAISE NOTICE 'User Accounts (Patient): % records', user_count;
    RAISE NOTICE '========================================';
END $$;