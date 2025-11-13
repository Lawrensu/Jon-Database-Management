# Database Queries Guide

**Team Member:** Jason  
**Role:** Query Specialist  
**Responsibility:** Writing SQL queries, reports, analytics, and optimization

---

## 🎯 Mission/Objectives

You are responsible for creating **powerful, efficient SQL queries** that:

1. **Extract meaningful insights** - Business intelligence and reporting
2. **Test database performance** - Identify bottlenecks and optimize
3. **Validate data integrity** - Ensure data relationships are correct
4. **Create reusable views** - Common queries that others can use
5. **Document query patterns** - Teaching the team SQL best practices

---

## 📋 What You Need to Do

### Phase 1: Understanding the Data 

**Files to work on:**
- `test_queries.sql` - Basic validation queries
- `analytics_queries.sql` - Business intelligence reports
- `performance_queries.sql` - Query optimization

**First, explore the database:**

```bash
# Start the database
npm run db:start

# Load the schema and data
npm run schema:create
npm run seeds:run

# Connect to database
npm run db:connect

# Explore tables
\dt app.*

# View a table structure
\d+ app.patients

# See sample data
SELECT * FROM app.patients LIMIT 5;
```

### Phase 2: Writing Basic Queries 

**File:** `test_queries.sql`

Create queries that validate the database is working correctly:

```sql
-- filepath: database/queries/test_queries.sql
SET search_path TO app, public;

-- ============================================================================
-- BASIC VALIDATION QUERIES
-- ============================================================================

-- Query 1: Count all records in each table
SELECT 
    'Patients' AS table_name, 
    COUNT(*) AS total_records,
    COUNT(CASE WHEN is_active = TRUE THEN 1 END) AS active_records
FROM app.patients
UNION ALL
SELECT 'Doctors', COUNT(*), COUNT(CASE WHEN is_active = TRUE THEN 1 END)
FROM app.doctors
UNION ALL
SELECT 'Appointments', COUNT(*), COUNT(*)
FROM app.appointments
UNION ALL
SELECT 'Medical Records', COUNT(*), COUNT(*)
FROM app.medical_records
ORDER BY table_name;

-- Query 2: Check data distribution by date
SELECT 
    'Patients' AS category,
    DATE_TRUNC('month', registration_date)::DATE AS month,
    COUNT(*) AS count
FROM app.patients
GROUP BY DATE_TRUNC('month', registration_date)
ORDER BY month DESC
LIMIT 12;

-- Query 3: Verify foreign key relationships
SELECT 
    'Appointments without patients' AS issue,
    COUNT(*) AS count
FROM app.appointments a
LEFT JOIN app.patients p ON a.patient_id = p.id
WHERE p.id IS NULL
UNION ALL
SELECT 
    'Appointments without doctors',
    COUNT(*)
FROM app.appointments a
LEFT JOIN app.doctors d ON a.doctor_id = d.id
WHERE d.id IS NULL
UNION ALL
SELECT 
    'Medical records without appointments',
    COUNT(*)
FROM app.medical_records mr
LEFT JOIN app.appointments a ON mr.appointment_id = a.id
WHERE a.id IS NULL;

-- Query 4: Patient demographics summary
SELECT 
    gender,
    COUNT(*) AS total_patients,
    ROUND(AVG(EXTRACT(YEAR FROM AGE(date_of_birth)))) AS avg_age,
    MIN(EXTRACT(YEAR FROM AGE(date_of_birth))) AS min_age,
    MAX(EXTRACT(YEAR FROM AGE(date_of_birth))) AS max_age,
    COUNT(CASE WHEN blood_type IS NOT NULL THEN 1 END) AS with_blood_type
FROM app.patients
WHERE is_active = TRUE
GROUP BY gender
ORDER BY total_patients DESC;

-- Query 5: Doctor workload distribution
SELECT 
    d.doctor_number,
    d.first_name || ' ' || d.last_name AS doctor_name,
    dept.name AS department,
    COUNT(a.id) AS total_appointments,
    COUNT(CASE WHEN s.status_name = 'Completed' THEN 1 END) AS completed,
    COUNT(CASE WHEN s.status_name IN ('Scheduled', 'Confirmed') THEN 1 END) AS upcoming,
    ROUND(AVG(a.consultation_fee), 2) AS avg_fee
FROM app.doctors d
LEFT JOIN app.appointments a ON d.id = a.doctor_id
LEFT JOIN app.appointment_statuses s ON a.status_id = s.id
LEFT JOIN app.departments dept ON d.department_id = dept.id
WHERE d.is_active = TRUE
GROUP BY d.id, d.doctor_number, d.first_name, d.last_name, dept.name
ORDER BY total_appointments DESC;
```

### Phase 3: Advanced Analytics 

**File:** `analytics_queries.sql`

Create queries for business intelligence and reporting:

```sql
-- filepath: database/queries/analytics_queries.sql
SET search_path TO app, public;

-- ============================================================================
-- BUSINESS INTELLIGENCE QUERIES
-- ============================================================================

-- Report 1: Monthly Revenue Analysis
WITH monthly_revenue AS (
    SELECT 
        DATE_TRUNC('month', appointment_date) AS month,
        COUNT(*) AS total_appointments,
        COUNT(CASE WHEN payment_status = 'Paid' THEN 1 END) AS paid_appointments,
        SUM(consultation_fee) AS potential_revenue,
        SUM(CASE WHEN payment_status = 'Paid' THEN consultation_fee ELSE 0 END) AS actual_revenue,
        SUM(CASE WHEN payment_status = 'Pending' THEN consultation_fee ELSE 0 END) AS pending_revenue
    FROM app.appointments
    WHERE appointment_date >= CURRENT_DATE - INTERVAL '12 months'
    GROUP BY DATE_TRUNC('month', appointment_date)
)
SELECT 
    TO_CHAR(month, 'Mon YYYY') AS month_name,
    total_appointments,
    paid_appointments,
    ROUND(paid_appointments * 100.0 / NULLIF(total_appointments, 0), 2) AS payment_rate,
    TO_CHAR(actual_revenue, 'FM$999,999,999.00') AS revenue_collected,
    TO_CHAR(pending_revenue, 'FM$999,999,999.00') AS revenue_pending,
    TO_CHAR(potential_revenue, 'FM$999,999,999.00') AS revenue_potential
FROM monthly_revenue
ORDER BY month DESC;

-- Report 2: Department Performance Dashboard
SELECT 
    dept.name AS department,
    COUNT(DISTINCT d.id) AS total_doctors,
    COUNT(a.id) AS total_appointments,
    COUNT(CASE WHEN s.status_name = 'Completed' THEN 1 END) AS completed_appointments,
    COUNT(CASE WHEN s.status_name = 'Cancelled' THEN 1 END) AS cancelled_appointments,
    ROUND(COUNT(CASE WHEN s.status_name = 'Cancelled' THEN 1 END) * 100.0 / 
          NULLIF(COUNT(a.id), 0), 2) AS cancellation_rate,
    ROUND(AVG(a.consultation_fee), 2) AS avg_consultation_fee,
    ROUND(SUM(CASE WHEN a.payment_status = 'Paid' THEN a.consultation_fee ELSE 0 END), 2) AS total_revenue
FROM app.departments dept
LEFT JOIN app.doctors d ON dept.id = d.department_id
LEFT JOIN app.appointments a ON d.id = a.doctor_id
LEFT JOIN app.appointment_statuses s ON a.status_id = s.id
WHERE dept.is_active = TRUE
GROUP BY dept.id, dept.name
ORDER BY total_revenue DESC;

-- Report 3: Patient Engagement Analysis
WITH patient_visits AS (
    SELECT 
        p.id,
        p.patient_number,
        p.first_name || ' ' || p.last_name AS patient_name,
        p.registration_date,
        COUNT(a.id) AS total_visits,
        MAX(a.appointment_date) AS last_visit,
        MIN(a.appointment_date) AS first_visit,
        EXTRACT(DAY FROM CURRENT_DATE - MAX(a.appointment_date)) AS days_since_last_visit
    FROM app.patients p
    LEFT JOIN app.appointments a ON p.id = a.patient_id
    WHERE p.is_active = TRUE
    GROUP BY p.id, p.patient_number, p.first_name, p.last_name, p.registration_date
)
SELECT 
    CASE 
        WHEN total_visits = 0 THEN 'Never Visited'
        WHEN days_since_last_visit <= 30 THEN 'Active (< 1 month)'
        WHEN days_since_last_visit <= 90 THEN 'Recent (1-3 months)'
        WHEN days_since_last_visit <= 180 THEN 'Inactive (3-6 months)'
        ELSE 'Lost (> 6 months)'
    END AS patient_status,
    COUNT(*) AS patient_count,
    ROUND(AVG(total_visits), 2) AS avg_visits_per_patient,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) AS percentage
FROM patient_visits
GROUP BY patient_status
ORDER BY patient_count DESC;

-- Report 4: Appointment Patterns by Day and Time
SELECT 
    CASE EXTRACT(DOW FROM appointment_date)
        WHEN 0 THEN 'Sunday'
        WHEN 1 THEN 'Monday'
        WHEN 2 THEN 'Tuesday'
        WHEN 3 THEN 'Wednesday'
        WHEN 4 THEN 'Thursday'
        WHEN 5 THEN 'Friday'
        WHEN 6 THEN 'Saturday'
    END AS day_of_week,
    EXTRACT(DOW FROM appointment_date) AS day_number,
    CASE 
        WHEN appointment_time BETWEEN '08:00' AND '11:59' THEN 'Morning (8-12)'
        WHEN appointment_time BETWEEN '12:00' AND '14:59' THEN 'Afternoon (12-3)'
        WHEN appointment_time BETWEEN '15:00' AND '17:59' THEN 'Late Afternoon (3-6)'
        ELSE 'Evening (6-8)'
    END AS time_slot,
    COUNT(*) AS total_appointments,
    ROUND(AVG(duration_minutes), 0) AS avg_duration_minutes,
    COUNT(CASE WHEN s.status_name = 'No Show' THEN 1 END) AS no_shows,
    ROUND(COUNT(CASE WHEN s.status_name = 'No Show' THEN 1 END) * 100.0 / 
          NULLIF(COUNT(*), 0), 2) AS no_show_rate
FROM app.appointments a
JOIN app.appointment_statuses s ON a.status_id = s.id
WHERE appointment_date >= CURRENT_DATE - INTERVAL '90 days'
GROUP BY day_of_week, day_number, time_slot
ORDER BY day_number, 
    CASE time_slot
        WHEN 'Morning (8-12)' THEN 1
        WHEN 'Afternoon (12-3)' THEN 2
        WHEN 'Late Afternoon (3-6)' THEN 3
        ELSE 4
    END;

-- Report 5: Top Diagnoses and Conditions
SELECT 
    mr.diagnosis,
    COUNT(*) AS frequency,
    COUNT(DISTINCT mr.patient_id) AS unique_patients,
    ROUND(AVG(EXTRACT(YEAR FROM AGE(p.date_of_birth))), 1) AS avg_patient_age,
    STRING_AGG(DISTINCT dept.name, ', ' ORDER BY dept.name) AS departments,
    COUNT(CASE WHEN mr.follow_up_required THEN 1 END) AS requires_follow_up
FROM app.medical_records mr
JOIN app.patients p ON mr.patient_id = p.id
JOIN app.doctors d ON mr.doctor_id = d.id
LEFT JOIN app.departments dept ON d.department_id = dept.id
WHERE mr.diagnosis IS NOT NULL
GROUP BY mr.diagnosis
HAVING COUNT(*) >= 3  -- Only show diagnoses with 3+ occurrences
ORDER BY frequency DESC
LIMIT 20;

-- Report 6: Doctor Efficiency Metrics
WITH doctor_stats AS (
    SELECT 
        d.id,
        d.doctor_number,
        d.first_name || ' ' || d.last_name AS doctor_name,
        dept.name AS department,
        spec.name AS specialization,
        COUNT(a.id) AS total_appointments,
        COUNT(CASE WHEN s.status_name = 'Completed' THEN 1 END) AS completed_appointments,
        COUNT(CASE WHEN s.status_name = 'Cancelled' THEN 1 END) AS cancelled_by_patient,
        COUNT(CASE WHEN s.status_name = 'No Show' THEN 1 END) AS patient_no_shows,
        AVG(a.duration_minutes) AS avg_appointment_duration,
        SUM(CASE WHEN a.payment_status = 'Paid' THEN a.consultation_fee ELSE 0 END) AS revenue_generated
    FROM app.doctors d
    JOIN app.departments dept ON d.department_id = dept.id
    LEFT JOIN app.specializations spec ON d.specialization_id = spec.id
    LEFT JOIN app.appointments a ON d.id = a.doctor_id
    LEFT JOIN app.appointment_statuses s ON a.status_id = s.id
    WHERE d.is_active = TRUE
    GROUP BY d.id, d.doctor_number, d.first_name, d.last_name, dept.name, spec.name
)
SELECT 
    doctor_number,
    doctor_name,
    department,
    specialization,
    total_appointments,
    completed_appointments,
    ROUND(completed_appointments * 100.0 / NULLIF(total_appointments, 0), 2) AS completion_rate,
    patient_no_shows,
    ROUND(patient_no_shows * 100.0 / NULLIF(total_appointments, 0), 2) AS no_show_rate,
    ROUND(avg_appointment_duration, 0) AS avg_duration_mins,
    TO_CHAR(revenue_generated, 'FM$999,999,999.00') AS total_revenue
FROM doctor_stats
WHERE total_appointments > 0
ORDER BY revenue_generated DESC;

-- Report 7: Patient Risk Assessment (Allergies & Conditions)
SELECT 
    p.patient_number,
    p.first_name || ' ' || p.last_name AS patient_name,
    EXTRACT(YEAR FROM AGE(p.date_of_birth)) AS age,
    p.blood_type,
    COUNT(DISTINCT pa.id) AS total_allergies,
    STRING_AGG(DISTINCT pa.allergen, ', ' ORDER BY pa.allergen) AS allergies,
    MAX(CASE WHEN pa.severity = 'Life-threatening' THEN 'HIGH RISK' 
             WHEN pa.severity = 'Severe' THEN 'MEDIUM RISK'
             ELSE 'LOW RISK' END) AS risk_level,
    COUNT(DISTINCT a.id) AS total_visits,
    MAX(a.appointment_date) AS last_visit_date
FROM app.patients p
LEFT JOIN app.patient_allergies pa ON p.id = pa.patient_id AND pa.is_active = TRUE
LEFT JOIN app.appointments a ON p.id = a.patient_id
WHERE p.is_active = TRUE
GROUP BY p.id, p.patient_number, p.first_name, p.last_name, p.date_of_birth, p.blood_type
HAVING COUNT(DISTINCT pa.id) > 0  -- Only patients with allergies
ORDER BY 
    CASE risk_level
        WHEN 'HIGH RISK' THEN 1
        WHEN 'MEDIUM RISK' THEN 2
        ELSE 3
    END,
    total_allergies DESC;
```

### Phase 4: Creating Useful Views 

**File:** `views.sql`

Create views for commonly used queries:

```sql
-- filepath: database/queries/views.sql
SET search_path TO app, public;

-- ============================================================================
-- USEFUL DATABASE VIEWS
-- ============================================================================

-- View 1: Patient Summary (for quick lookups)
CREATE OR REPLACE VIEW app.v_patient_summary AS
SELECT 
    p.id,
    p.patient_number,
    p.first_name || ' ' || COALESCE(p.middle_name || ' ', '') || p.last_name AS full_name,
    p.date_of_birth,
    EXTRACT(YEAR FROM AGE(p.date_of_birth)) AS age,
    p.gender,
    p.blood_type,
    p.email,
    p.phone_primary,
    p.emergency_contact_name,
    p.emergency_contact_phone,
    COUNT(DISTINCT a.id) AS total_appointments,
    MAX(a.appointment_date) AS last_appointment_date,
    COUNT(DISTINCT pa.id) AS allergy_count,
    CASE 
        WHEN MAX(CASE WHEN pa.severity = 'Life-threatening' THEN 1 ELSE 0 END) = 1 THEN 'HIGH RISK'
        WHEN MAX(CASE WHEN pa.severity = 'Severe' THEN 1 ELSE 0 END) = 1 THEN 'MEDIUM RISK'
        WHEN COUNT(pa.id) > 0 THEN 'LOW RISK'
        ELSE 'NO ALLERGIES'
    END AS allergy_risk,
    p.is_active
FROM app.patients p
LEFT JOIN app.appointments a ON p.id = a.patient_id
LEFT JOIN app.patient_allergies pa ON p.id = pa.patient_id AND pa.is_active = TRUE
GROUP BY p.id;

COMMENT ON VIEW app.v_patient_summary IS 'Patient summary with key metrics and risk assessment';

-- View 2: Upcoming Appointments (for scheduling)
CREATE OR REPLACE VIEW app.v_upcoming_appointments AS
SELECT 
    a.appointment_number,
    a.appointment_date,
    a.appointment_time,
    TO_CHAR(a.appointment_date, 'Day') AS day_of_week,
    a.duration_minutes,
    p.patient_number,
    p.first_name || ' ' || p.last_name AS patient_name,
    p.phone_primary AS patient_phone,
    d.doctor_number,
    d.first_name || ' ' || d.last_name AS doctor_name,
    dept.name AS department,
    s.status_name AS status,
    a.reason_for_visit,
    a.consultation_fee,
    a.payment_status,
    CASE 
        WHEN a.appointment_date = CURRENT_DATE THEN 'TODAY'
        WHEN a.appointment_date = CURRENT_DATE + 1 THEN 'TOMORROW'
        WHEN a.appointment_date <= CURRENT_DATE + 7 THEN 'THIS WEEK'
        ELSE 'LATER'
    END AS urgency
FROM app.appointments a
JOIN app.patients p ON a.patient_id = p.id
JOIN app.doctors d ON a.doctor_id = d.id
JOIN app.departments dept ON a.department_id = dept.id
JOIN app.appointment_statuses s ON a.status_id = s.id
WHERE a.appointment_date >= CURRENT_DATE
  AND s.status_name IN ('Scheduled', 'Confirmed')
ORDER BY a.appointment_date, a.appointment_time;

COMMENT ON VIEW app.v_upcoming_appointments IS 'All future appointments with patient and doctor details';

-- View 3: Doctor Availability (for booking)
CREATE OR REPLACE VIEW app.v_doctor_availability AS
SELECT 
    d.id AS doctor_id,
    d.doctor_number,
    d.first_name || ' ' || d.last_name AS doctor_name,
    dept.name AS department,
    spec.name AS specialization,
    ds.day_of_week,
    CASE ds.day_of_week
        WHEN 0 THEN 'Sunday'
        WHEN 1 THEN 'Monday'
        WHEN 2 THEN 'Tuesday'
        WHEN 3 THEN 'Wednesday'
        WHEN 4 THEN 'Thursday'
        WHEN 5 THEN 'Friday'
        WHEN 6 THEN 'Saturday'
    END AS day_name,
    ds.start_time,
    ds.end_time,
    ds.break_start_time,
    ds.break_end_time,
    d.consultation_fee,
    d.is_accepting_patients,
    d.employment_type
FROM app.doctors d
JOIN app.departments dept ON d.department_id = dept.id
LEFT JOIN app.specializations spec ON d.specialization_id = spec.id
LEFT JOIN app.doctor_schedules ds ON d.id = ds.doctor_id AND ds.is_active = TRUE
WHERE d.is_active = TRUE
ORDER BY d.last_name, ds.day_of_week, ds.start_time;

COMMENT ON VIEW app.v_doctor_availability IS 'Doctor working hours and availability for appointments';

-- View 4: Patient Medical History
CREATE OR REPLACE VIEW app.v_patient_medical_history AS
SELECT 
    mr.id AS record_id,
    p.patient_number,
    p.first_name || ' ' || p.last_name AS patient_name,
    mr.visit_date,
    d.first_name || ' ' || d.last_name AS doctor_name,
    dept.name AS department,
    mr.chief_complaint,
    mr.diagnosis,
    mr.treatment_plan,
    mr.medications_prescribed,
    mr.follow_up_required,
    mr.follow_up_date,
    a.appointment_number,
    -- Vitals
    mr.temperature_celsius,
    mr.blood_pressure_systolic || '/' || mr.blood_pressure_diastolic AS blood_pressure,
    mr.heart_rate,
    mr.respiratory_rate,
    mr.oxygen_saturation
FROM app.medical_records mr
JOIN app.patients p ON mr.patient_id = p.id
JOIN app.doctors d ON mr.doctor_id = d.id
LEFT JOIN app.departments dept ON d.department_id = dept.id
LEFT JOIN app.appointments a ON mr.appointment_id = a.id
ORDER BY p.patient_number, mr.visit_date DESC;

COMMENT ON VIEW app.v_patient_medical_history IS 'Complete medical history for each patient';

-- View 5: Revenue Dashboard
CREATE OR REPLACE VIEW app.v_revenue_dashboard AS
SELECT 
    DATE_TRUNC('month', a.appointment_date)::DATE AS month,
    dept.name AS department,
    COUNT(*) AS total_appointments,
    COUNT(CASE WHEN a.payment_status = 'Paid' THEN 1 END) AS paid_appointments,
    SUM(a.consultation_fee) AS potential_revenue,
    SUM(CASE WHEN a.payment_status = 'Paid' THEN a.consultation_fee ELSE 0 END) AS actual_revenue,
    SUM(CASE WHEN a.payment_status = 'Pending' THEN a.consultation_fee ELSE 0 END) AS pending_revenue,
    ROUND(SUM(CASE WHEN a.payment_status = 'Paid' THEN a.consultation_fee ELSE 0 END) * 100.0 / 
          NULLIF(SUM(a.consultation_fee), 0), 2) AS collection_rate
FROM app.appointments a
JOIN app.departments dept ON a.department_id = dept.id
WHERE a.appointment_date >= CURRENT_DATE - INTERVAL '12 months'
GROUP BY DATE_TRUNC('month', a.appointment_date), dept.name
ORDER BY month DESC, actual_revenue DESC;

COMMENT ON VIEW app.v_revenue_dashboard IS 'Monthly revenue by department';
```

---

## 🛠️ Query Optimization Tips

### 1. Use EXPLAIN ANALYZE
```sql
-- See how PostgreSQL executes your query
EXPLAIN ANALYZE
SELECT * FROM app.patients p
JOIN app.appointments a ON p.id = a.patient_id
WHERE p.is_active = TRUE;
```

### 2. Create Indexes for Frequently Queried Columns
```sql
-- Example: Index on appointment dates
CREATE INDEX IF NOT EXISTS idx_appointments_date_range 
ON app.appointments(appointment_date) 
WHERE appointment_date >= CURRENT_DATE;
```

### 3. Use CTEs for Complex Queries
```sql
-- Common Table Expressions improve readability
WITH active_patients AS (
    SELECT * FROM app.patients WHERE is_active = TRUE
),
patient_appointments AS (
    SELECT patient_id, COUNT(*) as visit_count
    FROM app.appointments
    GROUP BY patient_id
)
SELECT 
    ap.patient_number,
    ap.first_name,
    ap.last_name,
    COALESCE(pa.visit_count, 0) as total_visits
FROM active_patients ap
LEFT JOIN patient_appointments pa ON ap.id = pa.patient_id;
```

### 4. Avoid SELECT *
```sql
-- ❌ Bad: Retrieves all columns
SELECT * FROM app.patients;

-- ✅ Good: Only retrieve what you need
SELECT patient_number, first_name, last_name, email 
FROM app.patients;
```

---

## 🚀 Commands for Your Work

```bash
# Start database
npm run db:start

# Load schema and seeds
npm run schema:create
npm run seeds:run

# Run your test queries
npm run queries:test

# Run all queries in the folder
npm run queries:run

# Connect to database for interactive queries
npm run db:connect

# Check query performance
# Inside psql:
\timing on
SELECT ...;
```

---

## 🤝 Working with Team

### With Database Designers (Lawrence & Jonathan):
- ✅ Request indexes for slow queries
- ✅ Suggest schema improvements based on query patterns
- ✅ Test queries after schema changes

### With Data Manager (Cherrylyn):
- ✅ Request specific data scenarios for testing
- ✅ Provide feedback on data quality
- ✅ Ensure queries work with edge cases

### With DevOps (Faisal):
- ✅ Document query performance metrics
- ✅ Provide queries for monitoring dashboards
- ✅ Help with backup/restore testing

---

## 📝 Documentation Requirements

Create `docs/queries-documentation.md`:

```md
# Query Documentation

## Query Categories
1. Validation Queries - Data integrity checks
2. Analytics Queries - Business intelligence
3. Performance Queries - Optimization analysis
4. Views - Reusable query patterns

## Key Metrics Tracked
- Patient visit frequency
- Doctor efficiency
- Revenue collection
- Appointment patterns
- Department performance

## Query Performance Benchmarks
- Simple queries: < 50ms
- Complex joins: < 200ms
- Analytics queries: < 1s
- Reports: < 3s
```

---

## ⚠️ Common Mistakes to Avoid

❌ **Don't** use `SELECT *` in production queries  
❌ **Don't** forget to add `WHERE` clauses for date ranges  
❌ **Don't** create queries without testing with large datasets  
❌ **Don't** forget to handle NULL values properly  
❌ **Don't** use subqueries when JOINs are more efficient  
❌ **Don't** forget to add comments explaining complex logic  

---

## 📞 Need Help?

1. Check existing queries in `database/queries/`
2. Use `EXPLAIN ANALYZE` to understand query performance
3. Test queries in pgAdmin first
4. Ask Lawrence/Jonathan about schema questions
5. Review PostgreSQL documentation

**Your queries turn data into insights. Make them powerful!** 🚀