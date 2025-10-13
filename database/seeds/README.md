# Sample Data (Seeds) Guide

**Team Member:** Cherrylyn  
**Role:** Data Manager  
**Responsibility:** Creating realistic sample data for testing

---

## 🎯 Objectives/Mission whatever u wanna call it

Responsible for creating **realistic, consistent sample data** that:

1. **Tests all database features** - Every table, relationship, constraint
2. **Represents real-world scenarios** - Actual patient data, appointments, etc.
3. **Covers edge cases** - Empty values, maximum lengths, date ranges
4. **Maintains referential integrity** - All foreign keys point to valid records

---

## 📋 What You Need to Do

### Phase 1: Understanding the Database 

**Files to work on:**
- `01_patients_seed.sql` - Patient data
- `02_doctors_seed.sql` - Doctor data
- `03_appointments_seed.sql` - Appointment bookings
- `` - More if needed (perhaps need admin and superadmin data too?)

**First, understand the schema:**

```bash
# View the database structure
npm run schema:create

# Connect to database
npm run db:connect

# List all tables
\dt app.*

# Describe a table
\d app.patients
```

### Phase 2: Creating Patient Data 

**File:** `01_patients_seed.sql`

**What to include:**

1. **Diverse Demographics**
   - Different age groups (children, adults, seniors)
   - Multiple ethnicities (Malaysian, Chinese, Indian, etc.)
   - Various genders
   - Different locations in Malaysia

2. **Realistic Data**
   - Actual Malaysian names
   - Valid Malaysian phone numbers (+60-XX-XXX-XXXX)
   - Real addresses in Kuala Lumpur/Selangor
   - Valid email formats

3. **Medical Information**
   - Blood types (A+, B+, O+, AB+, A-, B-, O-, AB-)
   - Realistic height (50-220 cm)
   - Realistic weight (3-200 kg)
   - Common allergies
   - Perhaps got more? Following ER diagram data (WATCH OUT FOR THIS)

**Example patient data:**

```sql
SET search_path TO app, public;

-- Insert patients with realistic Malaysian data
INSERT INTO app.patients (
    patient_number, first_name, middle_name, last_name, 
    date_of_birth, gender,
    email, phone_primary, phone_secondary,
    address_line1, address_line2, city, state, postal_code,
    blood_type, height_cm, weight_kg,
    emergency_contact_name, emergency_contact_phone, emergency_contact_relationship,
    is_active, registration_date
) VALUES
(
    'PT2024001',
    'Ahmad', 'bin', 'Abdullah',
    '1985-03-15', 'Male',
    'ahmad.abdullah@email.com',
    '+60-12-345-6001',
    '+60-3-8765-4001',
    '123 Jalan Bukit Bintang', 'Taman Melawati',
    'Kuala Lumpur', 'Selangor', '53100',
    'O+', 175.5, 78.2,
    'Siti Abdullah', '+60-12-345-6002', 'Spouse',
    TRUE, '2024-01-15'
),
(
    'PT2024002',
    'Siti', 'binti', 'Rahman',
    '1990-07-22', 'Female',
    'siti.rahman@email.com',
    '+60-12-345-6003',
    NULL,  -- Optional field
    '456 Jalan Tun Razak', 'Apartment 5B',
    'Kuala Lumpur', 'Selangor', '50400',
    'A+', 160.0, 55.8,
    'Ahmad Rahman', '+60-12-345-6004', 'Spouse',
    TRUE, '2024-01-20'
),
-- Add at least 50 more patients with variety...
(
    'PT2024003',
    'Lee', 'Wei', 'Chen',
    '1982-11-08', 'Male',
    'lee.chen@email.com',
    '+60-12-345-6005',
    '+60-3-8765-4002',
    '789 Jalan Ampang', 'Condominium Unit 12',
    'Kuala Lumpur', 'Selangor', '50450',
    'B+', 170.0, 72.5,
    'Tan Mei Ling', '+60-12-345-6006', 'Spouse',
    TRUE, '2024-02-01'
)
ON CONFLICT (patient_number) DO NOTHING;
```

**Variety checklist:**
- [ ] 10+ children (age 0-12)
- [ ] 20+ adults (age 18-64)
- [ ] 10+ seniors (age 65+)
- [ ] 5+ teenagers (age 13-17)
- [ ] Mix of all blood types
- [ ] Various cities (KL, PJ, Subang, Shah Alam)

### Phase 3: Creating Doctor Data 

**File:** `02_doctors_seed.sql`

**What to include:**

1. **Different Specializations**
   - General Practitioners (most common)
   - Cardiologists
   - Pediatricians
   - Orthopedic Surgeons
   - Dermatologists
   - Neurologists
   - Obstetricians/Gynecologists
   - Emergency Medicine specialists

2. **Varied Experience Levels (MAYBE)**
   - Junior doctors (2-5 years experience)
   - Mid-level doctors (6-15 years)
   - Senior doctors (15+ years)


**Example doctor data:**

```sql
-- First, departments must exist
INSERT INTO app.departments (name, code, description, phone, email, location, is_active) VALUES
('Cardiology', 'CARD', 'Heart and cardiovascular specialists', '+60-3-2345-1001', 'cardiology@pakartech.com', 'Block A, Level 2', TRUE),
('Pediatrics', 'PEDI', 'Child and adolescent healthcare', '+60-3-2345-1002', 'pediatrics@pakartech.com', 'Block B, Level 1', TRUE),
('General Practice', 'GP', 'General medical consultation', '+60-3-2345-1004', 'gp@pakartech.com', 'Block C, Level 1', TRUE)
ON CONFLICT (code) DO NOTHING;

-- Then specializations
INSERT INTO app.specializations (name, code, description, requires_certification, years_training_required) VALUES
('General Practitioner', 'GP', 'General medical practice', TRUE, 3, TRUE),
('Cardiologist', 'CARD', 'Heart specialist', TRUE, 5, TRUE),
('Pediatrician', 'PEDI', 'Children''s doctor', TRUE, 4, TRUE)
ON CONFLICT (code) DO NOTHING;

-- Then doctors
INSERT INTO app.doctors (
    doctor_number, license_number,
    first_name, middle_name, last_name,
    department_id, specialization_id,
    qualification, years_of_experience,
    email, phone, office_location,
    hire_date, employment_type,
    consultation_fee,
    is_active, is_accepting_patients
) VALUES
(
    'DR2024001', 'MMC-CARD-12345',
    'Rajesh', 'Kumar', 'Menon',
    (SELECT id FROM app.departments WHERE code = 'CARD'),
    (SELECT id FROM app.specializations WHERE code = 'CARD'),
    'MBBS, MD (Cardiology), Fellowship in Interventional Cardiology',
    15,
    'dr.rajesh.menon@pakartech.com',
    '+60-12-234-5001',
    'Block A, Level 2, Room 201',
    '2015-03-15', 'Full-time',
    300.00,
    TRUE, TRUE
),
-- Add 20-30 more doctors...
(
    'DR2024002', 'MMC-PEDI-34567',
    'Amira', 'binti', 'Hassan',
    (SELECT id FROM app.departments WHERE code = 'PEDI'),
    (SELECT id FROM app.specializations WHERE code = 'PEDI'),
    'MBBS, MD (Pediatrics), Fellowship in Neonatology',
    12,
    'dr.amira.hassan@pakartech.com',
    '+60-12-234-5003',
    'Block B, Level 1, Room 101',
    '2016-09-01', 'Full-time',
    250.00,
    TRUE, TRUE
)
ON CONFLICT (doctor_number) DO NOTHING;
```

**Doctor schedules (working hours) (MAYBE):**

```sql
-- Full-time doctors work Monday-Friday, 9 AM - 5 PM
INSERT INTO app.doctor_schedules (doctor_id, day_of_week, start_time, end_time, break_start_time, break_end_time, is_active)
SELECT 
    d.id,
    dow.day,
    '09:00:00'::TIME,
    '17:00:00'::TIME,
    '13:00:00'::TIME,  -- Lunch break
    '14:00:00'::TIME,
    TRUE
FROM app.doctors d
CROSS JOIN (
    SELECT 1 AS day UNION ALL  -- Monday
    SELECT 2 UNION ALL          -- Tuesday
    SELECT 3 UNION ALL          -- Wednesday
    SELECT 4 UNION ALL          -- Thursday
    SELECT 5                    -- Friday
) dow
WHERE d.employment_type = 'Full-time'
ON CONFLICT DO NOTHING;
```

### Phase 4: Creating Appointment Data (yes)

**File:** `03_appointments_seed.sql`

**What to include:**

1. **Different Time Periods**
   - Past appointments (completed)
   - Current appointments (today/this week)
   - Future appointments (scheduled)

2. **Various Statuses**
   - Completed (most past appointments)
   - Scheduled (future appointments)
   - Confirmed (upcoming appointments)
   - Cancelled (some appointments)
   - No Show (a few appointments)

3. **Realistic Scenarios**
   - Follow-up appointments (reference previous appointments)
   - Different times of day (morning, afternoon, evening)
   - Different consultation fees based on doctor
   - Payment statuses (Paid, Pending, Cancelled)

**Example appointment data:**

```sql
-- Helper function for generating appointment numbers
CREATE OR REPLACE FUNCTION generate_appointment_number(counter INTEGER) 
RETURNS VARCHAR(20) AS $$
BEGIN
    RETURN 'APT' || TO_CHAR(CURRENT_DATE, 'YYYY') || LPAD(counter::TEXT, 6, '0');
END;
$$ LANGUAGE plpgsql;

-- Past completed appointments (30-120 days ago)
INSERT INTO app.appointments (
    appointment_number, patient_id, doctor_id, department_id,
    appointment_date, appointment_time, duration_minutes,
    status_id, reason_for_visit, symptoms, doctor_notes,
    is_follow_up, consultation_fee, payment_status
) VALUES
(
    generate_appointment_number(1),
    (SELECT id FROM app.patients WHERE patient_number = 'PT2024001'),
    (SELECT id FROM app.doctors WHERE doctor_number = 'DR2024001'),
    (SELECT id FROM app.departments WHERE code = 'CARD'),
    CURRENT_DATE - 45,  -- 45 days ago
    '10:00:00',
    45,
    (SELECT id FROM app.appointment_statuses WHERE status_name = 'Completed'),
    'Chest pain and irregular heartbeat',
    'Experiencing chest discomfort for past 2 weeks, occasional palpitations',
    'ECG shows slight abnormality. Prescribed beta-blockers. Follow-up in 2 weeks.',
    FALSE,
    300.00,
    'Paid'
);

-- Upcoming appointments (next 7 days)
INSERT INTO app.appointments (
    appointment_number, patient_id, doctor_id, department_id,
    appointment_date, appointment_time, duration_minutes,
    status_id, reason_for_visit,
    consultation_fee, payment_status
) VALUES
(
    generate_appointment_number(50),
    (SELECT id FROM app.patients WHERE patient_number = 'PT2024002'),
    (SELECT id FROM app.doctors WHERE doctor_number = 'DR2024007'),
    (SELECT id FROM app.departments WHERE code = 'GP'),
    CURRENT_DATE + 2,  -- 2 days from now
    '09:00:00',
    30,
    (SELECT id FROM app.appointment_statuses WHERE status_name = 'Confirmed'),
    'Annual physical examination',
    150.00,
    'Pending'
);

-- Clean up helper function
DROP FUNCTION IF EXISTS generate_appointment_number(INTEGER);
```

**Data variety checklist:**
- [ ] 50+ completed appointments
- [ ] 20+ upcoming appointments
- [ ] 5+ cancelled appointments
- [ ] 2-3 no-show appointments
- [ ] Mix of different doctors
- [ ] Mix of different departments
- [ ] Different times (9 AM, 10 AM, 2 PM, 3 PM, etc.)
- [ ] Some follow-up appointments

---

## 🛠️ Testing Your Seeds (funny)

### Test Individual Seed Files

```bash
# Test patients seed
npm run seeds:patients

# Test doctors seed
npm run seeds:doctors

# Test appointments seed
npm run seeds:appointments
```

### Test All Seeds Together

```bash
# Load all seed files in order
npm run seeds:run
```

### Verify Data Was Loaded

```bash
# Connect to database
npm run db:connect

# Count records in each table
SELECT 
    'Patients' AS table_name, COUNT(*) AS records FROM app.patients
UNION ALL
SELECT 'Doctors', COUNT(*) FROM app.doctors
UNION ALL
SELECT 'Appointments', COUNT(*) FROM app.appointments;

# Check for data integrity issues
SELECT * FROM app.appointments a 
LEFT JOIN app.patients p ON a.patient_id = p.id 
WHERE p.id IS NULL;  -- Should return 0 rows
```

---

## 📊 Data Generation Tips

### Malaysian Names

**Malay names:**
- Ahmad, Mohd, Ali, Hassan, Ismail (males)
- Siti, Nur, Fatimah, Aishah, Zainab (females)
- Use "bin" (son of) or "binti" (daughter of) for middle names

**Chinese names:**
- Lee, Tan, Wong, Lim, Chan (surnames)
- Wei, Mei, Jun, Ling, Hao (given names)

**Indian names:**
- Kumar, Singh, Sharma, Nair, Patel (surnames)
- Raj, Priya, Suresh, Lakshmi, Arun (given names)

### Malaysian Phone Numbers
- Format: `+60-12-XXX-XXXX` or `+60-3-XXXX-XXXX`
- Mobile prefixes: 12, 13, 14, 16, 17, 18, 19
- Landline prefix (KL): 3

### Malaysian Addresses
**Common areas in Klang Valley:**
- Kuala Lumpur: Bukit Bintang, KLCC, Cheras, Bangsar
- Petaling Jaya: SS2, Damansara, Subang Jaya
- Shah Alam: Section 1-25
- Postal codes: 50000-59200

### Medical Data
**Common blood types in Malaysia:**
- O+ (39%)
- A+ (27%)
- B+ (25%)
- AB+ (7%)
- Others (2%)

**Common allergies:**
- Penicillin (drug)
- Peanuts (food)
- Shellfish (food)
- Pollen (environmental)
- Latex (environmental)

---

## 🔧 Common SQL Patterns for Seeds

### Pattern 1: Using SELECT for Foreign Keys

```sql
-- Instead of hardcoding UUIDs, use SELECT
INSERT INTO app.appointments (
    patient_id,
    doctor_id,
    -- other fields...
) VALUES (
    (SELECT id FROM app.patients WHERE patient_number = 'PT2024001'),
    (SELECT id FROM app.doctors WHERE doctor_number = 'DR2024001'),
    -- other values...
);
```

### Pattern 2: Bulk Insert with SELECT

```sql
-- Generate multiple records at once
INSERT INTO app.appointments (appointment_number, patient_id, doctor_id, appointment_date)
SELECT 
    'APT202400' || ROW_NUMBER() OVER (),
    p.id,
    d.id,
    CURRENT_DATE + (random() * 30)::INTEGER
FROM (SELECT * FROM app.patients LIMIT 20) p
CROSS JOIN LATERAL (
    SELECT * FROM app.doctors 
    WHERE is_accepting_patients = TRUE 
    ORDER BY RANDOM() 
    LIMIT 1
) d;
```

### Pattern 3: Handling Conflicts

```sql
-- Prevent errors if data already exists
INSERT INTO app.departments (name, code, description)
VALUES ('Cardiology', 'CARD', 'Heart specialists')
ON CONFLICT (code) DO NOTHING;

-- Or update existing data
ON CONFLICT (code) DO UPDATE 
SET description = EXCLUDED.description;
```

### Pattern 4: Using Date Arithmetic

```sql
-- Past appointments (30-90 days ago)
CURRENT_DATE - INTERVAL '45 days'
CURRENT_DATE - (random() * 60 + 30)::INTEGER

-- Future appointments (1-30 days ahead)
CURRENT_DATE + INTERVAL '5 days'
CURRENT_DATE + (random() * 30)::INTEGER
```

---

## 🎯 Data Quality Checklist

Before submitting your seed files (make sure of these for good):

```
[ ] All seed files run without errors
[ ] No orphaned foreign keys (all references exist)
[ ] Data is realistic and diverse
[ ] Dates make sense (no future birth dates)
[ ] Contact information follows Malaysian format
[ ] Email addresses are unique
[ ] Patient numbers are sequential (PT2024001, PT2024002...)
[ ] Doctor numbers are sequential (DR2024001, DR2024002...)
[ ] Appointment numbers are sequential (APT2024000001...)
[ ] All required fields are filled
[ ] Optional fields have mix of filled/NULL values
[ ] Numeric values are within valid ranges
[ ] Check constraints are satisfied
[ ] At least 50 patients
[ ] At least 20 doctors
[ ] At least 100 appointments
[ ] Mix of completed, scheduled, and cancelled appointments
[ ] Success message prints at end of each seed file
```

---

## 🚀 Commands for Your Work

```bash
# Start database
npm run db:start

# Connect to database
npm run db:connect

# Create schema first (if needed)
npm run schema:create

# Test your seeds
npm run seeds:patients
npm run seeds:doctors
npm run seeds:appointments

# Load all seeds
npm run seeds:run

# Reset and reload everything
npm run schema:rebuild
npm run seeds:run

# Check results
npm run queries:test

# View logs
npm run db:logs
```

---

## 🤝 Working with Your Team

### With Database Designers (Lawrence & Jonathan):
- ✅ Wait for them to finalize schema before creating seeds
- ✅ If schema changes, update your seeds immediately
- ✅ Test that your data satisfies all constraints
- ✅ Report any issues with constraints that are too restrictive

### With Query Specialist (Jason):
- ✅ Provide diverse data for testing queries
- ✅ Ensure edge cases are covered
- ✅ Create data that makes reports meaningful

### With DevOps:
- ✅ Ensure seeds can run in any environment
- ✅ Document any special requirements
- ✅ Make seeds repeatable (use ON CONFLICT)

---

## 📝 Documentation Requirements

Create `docs/seeds-documentation.md`:

```md
# Sample Data Documentation

## Overview
Total records created:
- Patients: 50+
- Doctors: 20+
- Appointments: 100+
- Departments: 8
- Specializations: 8

## Data Sources
- Malaysian names from [source]
- Phone numbers follow Malaysian format
- Addresses are real locations in Klang Valley

## Special Cases Covered
- Pediatric patients (age < 18)
- Senior citizens (age > 65)
- Patients with allergies
- Patients with insurance
- Follow-up appointments
- Cancelled appointments

## Known Limitations
- All addresses are in Klang Valley
- Limited to 8 medical specializations
- Appointment history only covers last 120 days
```

---

## ⚠️ Common Mistakes to Avoid

❌ **Don't** hardcode UUIDs - use SELECT to find them  
❌ **Don't** forget `ON CONFLICT DO NOTHING` - prevents errors on re-run  
❌ **Don't** use unrealistic data - use actual Malaysian names/addresses  
❌ **Don't** forget to test each seed file individually first  
❌ **Don't** create circular dependencies (e.g., appointments before patients exist)  
❌ **Don't** use future dates for birth dates or past appointments  
❌ **Don't** exceed CHECK constraint limits (e.g., height > 300 cm)  
❌ **Don't** forget to add success messages at the end  

---

## 📞 Need Help?

1. Review the schema first: `database/project/01_core_schema.sql`
2. Check existing seed files for examples
3. Test in pgAdmin to see what data looks like
4. Ask Lawrence/Jonathan about schema questions
5. Ask Jason what data would be useful for queries

**Your data makes the database come alive. Make it realistic!** 📊