-- PAKAR Tech Healthcare - Patient Sample Data
-- COS 20031 Database Design Project
-- Author: [Cherylynn Cassidy]

-- ============================================================================
-- PATIENT SAMPLE DATA
-- ============================================================================

-- Set search path to use 'app' schema
SET search_path TO app, public;

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
    ARRAY['O+','A+','B+','AB+','A-','B-','O-','AB-']::text[] AS bloods,
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
    -- renamed to avoid duplicate alias later
    params.bloods[((g-1) % cardinality(params.bloods)) + 1] AS candidate_blood,
    params.mobile_prefixes[((g-1) % cardinality(params.mobile_prefixes)) + 1] AS mobile_prefix,
    -- age distribution: children (~20%), teens (~10%), adults (~50%), seniors (~20%)
    CASE
      WHEN (g % 10) < 2 THEN floor(random()*13)::int                         -- 0-12
      WHEN (g % 10) < 4 THEN (floor(random()*5)::int + 13)                  -- 13-17
      WHEN (g % 10) < 9 THEN (floor(random()*47)::int + 18)                 -- 18-64
      ELSE (floor(random()*26)::int + 65)                                   -- 65-90
    END AS age_years,
    -- generate phone numbers
    CASE
      WHEN random() < 0.8
      THEN '+60-' || params.mobile_prefixes[((g-1) % cardinality(params.mobile_prefixes)) + 1] || '-' ||
           lpad((floor(random()*900)::int + 100)::text,3,'0') || '-' || lpad((floor(random()*10000)::int)::text,4,'0')
      ELSE '+60-3-' || lpad((floor(random()*9000)::int + 1000)::text,4,'0') || '-' || lpad((floor(random()*10000)::int)::text,4,'0')
    END AS phone_primary,
    -- phone_secondary is optional
    CASE WHEN random() < 0.45 THEN
      '+60-' || params.mobile_prefixes[((g-1) % cardinality(params.mobile_prefixes)) + 1] || '-' ||
      lpad((floor(random()*900)::int + 100)::text,3,'0') || '-' || lpad((floor(random()*10000)::int)::text,4,'0')
    ELSE NULL END AS phone_secondary,
    -- address line generation
    ('No. ' || (100 + ((g*13) % 900))::text) AS address_line1,
    CASE WHEN random() < 0.35 THEN ('Apartment ' || ((g % 30) + 1)::text) ELSE NULL END AS address_line2,
    -- emergency contact
    ('EC ' || params.last_names[((g-1) % cardinality(params.last_names)) + 1] || ' ' || ((g % 7)+1)::text) AS emergency_contact_name,
    CASE
      WHEN random() < 0.85
      THEN '+60-' || params.mobile_prefixes[((g+3) % cardinality(params.mobile_prefixes)) + 1] || '-' ||
           lpad((floor(random()*900)::int + 100)::text,3,'0') || '-' || lpad((floor(random()*10000)::int)::text,4,'0')
      ELSE '+60-3-' || lpad((floor(random()*9000)::int + 1000)::text,4,'0') || '-' || lpad((floor(random()*10000)::int)::text,4,'0')
    END AS emergency_contact_phone,
    -- relationship inferred from age
    CASE
      WHEN ((CASE WHEN (g % 10) < 2 THEN floor(random()*13)::int WHEN (g % 10) < 4 THEN (floor(random()*5)::int + 13) WHEN (g % 10) < 9 THEN (floor(random()*47)::int + 18) ELSE (floor(random()*26)::int + 65) END) < 18)
        THEN 'Parent'
      WHEN ((g % 10) BETWEEN 4 AND 8) THEN (CASE WHEN random() < 0.6 THEN 'Spouse' ELSE 'Sibling' END)
      ELSE (CASE WHEN random() < 0.7 THEN 'Child' ELSE 'Spouse' END)
    END AS emergency_contact_relationship,
    -- vitals
    round((random()*170 + 50)::numeric,1) AS height_cm,
    round((random()*197 + 3)::numeric,1) AS weight_kg,
    -- registration date in last ~18 months
    (CURRENT_DATE - ((floor(random()*540)::int) * INTERVAL '1 day'))::date AS registration_date,
    -- add a random value for weighted blood selection
    random() AS r_blood
    -- removed duplicate CASE ... AS blood_type placeholder
  FROM generate_series(1,200) g
  CROSS JOIN params
)
-- Replace the placeholder blood_type with weighted assignment in the outer INSERT SELECT below
INSERT INTO app.patients (
  patient_number, first_name, middle_name, last_name,
  date_of_birth, gender,
  email, phone_primary, phone_secondary,
  address_line1, address_line2, city, state, postal_code,
  blood_type, height_cm, weight_kg,
  emergency_contact_name, emergency_contact_phone, emergency_contact_relationship,
  is_active, registration_date
)
SELECT
  -- patient_number e.g. PT20250001
  'PT' || to_char(CURRENT_DATE,'YYYY') || LPAD(g::text,4,'0') AS patient_number,
  first_name,
  NULLIF(TRIM(middle_name), '')::text AS middle_name,
  last_name,
  -- dob from age_years with an added random day offset within the year
  (CURRENT_DATE - ((age_years * 365) + floor(random() * 365)::int) * INTERVAL '1 day')::date AS date_of_birth,
  -- gender rotate with reasonable distribution
  (CASE WHEN (g % 3) = 1 THEN 'Male' WHEN (g % 3) = 2 THEN 'Female' ELSE 'Other' END) AS gender,
  lower(first_name || '.' || last_name || g || '@pakartech.test') AS email,
  phone_primary,
  phone_secondary,
  address_line1,
  address_line2,
  city,
  state,
  postal_code,
  -- weighted blood type using the r_blood value to match README distribution
  (CASE
     WHEN r_blood < 0.39 THEN 'O+'
     WHEN r_blood < 0.66 THEN 'A+'
     WHEN r_blood < 0.91 THEN 'B+'
     WHEN r_blood < 0.98 THEN 'AB+'
     ELSE (CASE WHEN random() < 0.5 THEN 'A-' ELSE (CASE WHEN random() < 0.5 THEN 'B-' ELSE (CASE WHEN random() < 0.5 THEN 'O-' ELSE 'AB-' END) END) END)
   END) AS blood_type,
  height_cm,
  weight_kg,
  emergency_contact_name,
  emergency_contact_phone,
  emergency_contact_relationship,
  -- most records active, small chance inactive
  (random() < 0.96) AS is_active,
  registration_date
FROM gen
ON CONFLICT (patient_number) DO NOTHING;

-- quick verification message (select row count from inserted set is environment-specific)
SELECT '01_patients_seed: completed (up to 200 records inserted, duplicates skipped).' AS info;