-- PAKAR Tech Healthcare - Patient Sample Data
-- COS 20031 Database Design Project
-- Author: [Cherylynn Cassidy]

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
    ARRAY['Bukit Bintang','Tun Razak','Jalan Ampang','Cheras','Bangsar','SS2','Damansara','Subang Jaya','Shah Alam','Kelana Jaya']::text[] AS streets,
    ARRAY['Kuala Lumpur','Petaling Jaya','Subang Jaya','Shah Alam']::text[] AS cities,
    ARRAY['Selangor','Kuala Lumpur']::text[] AS states,
    ARRAY['53100','50450','50400','46000','40150','47301','40100','68000','68100','43200']::text[] AS postals
),
gen AS (
  SELECT
    g,
    params.first_names[((g-1) % cardinality(params.first_names)) + 1] AS first_name,
    params.last_names[((g-1) % cardinality(params.last_names)) + 1] AS last_name,
    params.streets[((g-1) % cardinality(params.streets)) + 1] AS street,
    params.cities[((g-1) % cardinality(params.cities)) + 1] AS city,
    params.states[((g-1) % cardinality(params.states)) + 1] AS state,
    params.postals[((g-1) % cardinality(params.postals)) + 1] AS postal_code,
    CASE
      WHEN (g % 10) < 2 THEN floor(random()*13)::int
      WHEN (g % 10) < 4 THEN (floor(random()*5)::int + 13)
      WHEN (g % 10) < 9 THEN (floor(random()*47)::int + 18)
      ELSE (floor(random()*26)::int + 65)
    END AS age_years,
    (60120000000::bigint + floor(random() * 99999999)::bigint) AS phone_num,
    (60130000000::bigint + floor(random() * 99999999)::bigint) AS emergency_phone,
    ('No. ' || (100 + ((g*13) % 900))::text) AS address_line1,
    CASE WHEN random() < 0.35 THEN ('Apartment ' || ((g % 30) + 1)::text) ELSE NULL END AS address_line2,
    ('EC ' || params.last_names[((g-1) % cardinality(params.last_names)) + 1] || ' ' || ((g % 7)+1)::text) AS emergency_contact_name,
    (CURRENT_DATE - ((floor(random()*540)::int) * INTERVAL '1 day'))::date AS registration_date
  FROM generate_series(1,200) g
  CROSS JOIN params
),
user_inserts AS (
  INSERT INTO app.user_account (
    username, 
    password, 
    user_type, 
    first_name, 
    last_name, 
    email, 
    is_active, 
    created_at
  )
  SELECT
    lower(first_name || '.' || last_name || g::text) AS username,
    decode('736565642d70617373776f7264', 'hex') AS password,
    'Patient'::user_type_enum AS user_type,
    first_name,
    last_name,
    lower(first_name || '.' || last_name || g::text || '@pakartech.com') AS email,
    TRUE AS is_active,
    registration_date::timestamp AS created_at
  FROM gen
  ON CONFLICT (username) DO NOTHING
  RETURNING user_id, username
)
INSERT INTO app.patient (
  user_id,
  doctor_id,
  phone_num,
  birth_date,
  gender,
  address,
  emergency_contact_name,
  emergency_phone,
  created_at,
  updated_at
)
SELECT
  ui.user_id,
  NULL AS doctor_id,
  gen.phone_num,
  (CURRENT_DATE - ((gen.age_years * 365) + floor(random() * 365)::int) * INTERVAL '1 day')::timestamp AS birth_date,
  CASE (gen.g % 3)
    WHEN 0 THEN 'Male'::gender_enum
    WHEN 1 THEN 'Female'::gender_enum
    ELSE 'Other'::gender_enum
  END AS gender,
  (gen.address_line1 || COALESCE(' ' || gen.address_line2, '') || ', ' || gen.city || ', ' || gen.state || ' ' || gen.postal_code) AS address,
  gen.emergency_contact_name,
  gen.emergency_phone,
  gen.registration_date::timestamp AS created_at,
  gen.registration_date::timestamp AS updated_at
FROM gen
JOIN user_inserts ui ON ui.username = lower(gen.first_name || '.' || gen.last_name || gen.g::text)
ON CONFLICT (user_id) DO NOTHING;

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