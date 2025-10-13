# Database Schema Design Guide

**Team Members:** Lawrence, Jonathan  
**Role:** Database Designers  
**Responsibility:** Database structure, ER diagrams, normalization, schema design

---

## 🎯 What we need to do?

WE are responsible for designing the **complete database structure** for PAKAR Tech Healthcare. This includes:

1. **Schema Design** - Creating all tables, relationships, and constraints
2. **ER Diagrams** - Visual representation of the database
3. **Normalization** - Ensuring data integrity and efficiency
4. **Documentation** - Explaining design decisions

---

## 📋 What You Need to Do

### Phase 1: Understanding the Schema 

**File to work on:** `01_core_schema.sql`

1. **Review Current Structure**
   ```bash
   # View the schema file
   code database/project/01_core_schema.sql
   ```

2. **Understand the Healthcare Domain**
   - **Patients:** The customer basically (End User)
   - **Doctors:** Medical professionals
   - **Appointments:** Scheduling system
   - **Medical Records:** Patient history and diagnoses
   - **Medications:** Medications for the patients
   - **Symptoms:**  Symptoms that the patients have
   - **Side-Effects:**  Side-Effects that patients got after consuming the medications

3. **Study the Design Principles**
   - Every table uses `UUID` as primary key (globally unique)
   - Every table has `created_at` and `updated_at` timestamps
   - Use `CITEXT` for case-insensitive text (emails)
   - Foreign keys with proper `ON DELETE` actions
   - Indexes on frequently queried columns

### Phase 2: Extending the Schema

**Add more tables as needed:**

```sql
-- Example: Adding a Billing table
CREATE TABLE IF NOT EXISTS app.billing (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    
    -- Relationships
    appointment_id UUID NOT NULL REFERENCES app.appointments(id) ON DELETE RESTRICT,
    patient_id UUID NOT NULL REFERENCES app.patients(id) ON DELETE RESTRICT,
    
    -- Billing details
    invoice_number VARCHAR(50) NOT NULL UNIQUE,
    total_amount DECIMAL(10,2) NOT NULL,
    paid_amount DECIMAL(10,2) DEFAULT 0.00,
    payment_method VARCHAR(50) CHECK (payment_method IN ('Cash', 'Card', 'Insurance', 'Bank Transfer')),
    
    -- Status
    payment_status VARCHAR(20) CHECK (payment_status IN ('Pending', 'Paid', 'Partial', 'Cancelled')),
    
    -- Audit fields
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Constraints
    CONSTRAINT ck_billing_amounts CHECK (paid_amount <= total_amount)
);

-- Always add indexes for foreign keys
CREATE INDEX IF NOT EXISTS idx_billing_appointment ON app.billing(appointment_id);
CREATE INDEX IF NOT EXISTS idx_billing_patient ON app.billing(patient_id);
CREATE INDEX IF NOT EXISTS idx_billing_status ON app.billing(payment_status);
```

### Phase 3: Creating ER Diagrams (Already but just putting it here as a note)

**Tools you can use:**
- **pgAdmin** - Built-in ER diagram tool
- **draw.io** - Free online tool (https://app.diagrams.net/)
- **Lucidchart** - Professional diagramming
- **dbdiagram.io** - Database-specific tool

**What to include in your ER diagram:**
1. All entities (tables)
2. Attributes (columns) with data types
3. Primary keys (underlined)
4. Foreign keys (arrows showing relationships)
5. Cardinality (1:1, 1:N, M:N)
6. Business rules and constraints

**Example ER diagram notation:**
```
┌─────────────────────┐         ┌─────────────────────┐
│     PATIENTS        │         │     APPOINTMENTS    │
├─────────────────────┤         ├─────────────────────┤
│ PK id (UUID)        │────┐    │ PK id (UUID)        │
│    patient_number   │    │    │    appointment_num  │
│    first_name       │    │    │ FK patient_id       │
│    last_name        │    └───>│ FK doctor_id        │
│    date_of_birth    │         │    appointment_date │
│    email            │         │    status           │
└─────────────────────┘         └─────────────────────┘
```

**Save your diagrams to:** `docs/design/er-diagram.png` or `.pdf`

### Phase 4: Testing Your Schema 

**Test your schema design:**

```bash
# 1. Drop and recreate schema
npm run schema:drop

# 2. Create your new schema
npm run schema:create

# 3. Check for errors
npm run db:logs

# 4. Load sample data to test
npm run seeds:run

# 5. Verify relationships work
npm run queries:test
```

**Common issues to check:**
- ✅ All foreign keys reference existing tables
- ✅ Data types are appropriate (VARCHAR length, DECIMAL precision)
- ✅ Check constraints are logical
- ✅ Indexes are created for performance
- ✅ No circular dependencies

---

## 🛠️ Schema Design Checklist

Use this checklist for EVERY table we create (good practise):

```
Table: _______________

[ ] Has UUID primary key with uuid_generate_v4()
[ ] Has created_at timestamp with DEFAULT NOW()
[ ] Has updated_at timestamp with DEFAULT NOW()
[ ] All foreign keys have proper ON DELETE actions
[ ] All foreign keys have indexes
[ ] Email fields use CITEXT type
[ ] Numeric fields have CHECK constraints (e.g., price >= 0)
[ ] Enum-like fields use CHECK constraints
[ ] Has meaningful comments using COMMENT ON
[ ] Tested with sample data
[ ] Documented in ER diagram
```

---

## 📊 Database Normalization Guide (Putting this note here)

**What is normalization?**  
Organizing data to reduce redundancy and improve integrity.

### 1st Normal Form (1NF)
- ✅ Each column contains atomic (single) values
- ✅ Each row is unique (has primary key)
- ❌ No repeating groups or arrays

**Bad Example:**
```sql
-- DON'T DO THIS
CREATE TABLE patients (
    id UUID PRIMARY KEY,
    name VARCHAR(200),
    phone_numbers VARCHAR(500)  -- "123-456, 789-012, 345-678" ❌
);
```

**Good Example:**
```sql
-- DO THIS
CREATE TABLE patients (
    id UUID PRIMARY KEY,
    name VARCHAR(200)
);

CREATE TABLE patient_phones (
    id UUID PRIMARY KEY,
    patient_id UUID REFERENCES patients(id),
    phone_number VARCHAR(20),
    phone_type VARCHAR(20)  -- 'Primary', 'Secondary', 'Emergency'
);
```

### 2nd Normal Form (2NF)
- ✅ Must be in 1NF
- ✅ All non-key columns depend on the ENTIRE primary key

### 3rd Normal Form (3NF)
- ✅ Must be in 2NF
- ✅ No transitive dependencies (non-key columns depend only on primary key)

**Bad Example:**
```sql
-- DON'T DO THIS
CREATE TABLE appointments (
    id UUID PRIMARY KEY,
    patient_id UUID,
    patient_name VARCHAR(200),      -- ❌ Depends on patient_id, not appointment id
    patient_phone VARCHAR(20),      -- ❌ Depends on patient_id
    doctor_id UUID,
    doctor_name VARCHAR(200),       -- ❌ Depends on doctor_id
    appointment_date DATE
);
```

**Good Example:**
```sql
-- DO THIS - Keep patient/doctor data in their own tables
CREATE TABLE appointments (
    id UUID PRIMARY KEY,
    patient_id UUID REFERENCES patients(id),  -- ✅ Just the reference
    doctor_id UUID REFERENCES doctors(id),    -- ✅ Just the reference
    appointment_date DATE,
    appointment_time TIME
);
```

---

## 🔧 Common SQL Patterns

### Pattern 1: Lookup Tables (Reference Data)

```sql
-- For fixed categories/statuses
CREATE TABLE IF NOT EXISTS app.appointment_statuses (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    status_name VARCHAR(50) NOT NULL UNIQUE,
    description TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Insert fixed values
INSERT INTO app.appointment_statuses (status_name, description) VALUES
('Scheduled', 'Appointment has been scheduled'),
('Confirmed', 'Patient confirmed the appointment'),
('Completed', 'Appointment completed successfully'),
('Cancelled', 'Appointment was cancelled')
ON CONFLICT (status_name) DO NOTHING;
```

### Pattern 2: Audit Timestamps with Triggers

```sql
-- Automatically update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply to a table
CREATE TRIGGER update_patients_updated_at 
    BEFORE UPDATE ON app.patients 
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();
```

### Pattern 3: Soft Deletes

```sql
-- Instead of deleting records, mark them as inactive
CREATE TABLE IF NOT EXISTS app.patients (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    -- ... other fields ...
    is_active BOOLEAN DEFAULT TRUE,
    deleted_at TIMESTAMP WITH TIME ZONE,
    deleted_by UUID
);

-- View only active records
CREATE VIEW app.active_patients AS
SELECT * FROM app.patients WHERE is_active = TRUE;
```

### Pattern 4: Many-to-Many Relationships

```sql
-- Doctors can have multiple specializations
CREATE TABLE IF NOT EXISTS app.doctor_specializations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    doctor_id UUID NOT NULL REFERENCES app.doctors(id) ON DELETE CASCADE,
    specialization_id UUID NOT NULL REFERENCES app.specializations(id) ON DELETE CASCADE,
    certified_date DATE,
    certification_number VARCHAR(100),
    is_primary BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Ensure unique combinations
    CONSTRAINT uq_doctor_specialization UNIQUE(doctor_id, specialization_id)
);

CREATE INDEX idx_doctor_spec_doctor ON app.doctor_specializations(doctor_id);
CREATE INDEX idx_doctor_spec_specialization ON app.doctor_specializations(specialization_id);
```

---

## 🚀 Commands for Your Work

```bash
# Start working
npm run db:start

# Connect to database directly
npm run db:connect

# Create/update schema
npm run schema:create

# Rebuild from scratch
npm run schema:rebuild

# Test with data
npm run seeds:run

# Run test queries
npm run queries:test

# Check database status
npm run db:status

# View logs if something fails
npm run db:logs
```

---

## 📝 Documentation Requirements

Create these documents in `docs/design/`:

### 1. **schema-overview.md**
```md
# PAKAR Tech Healthcare - Database Schema Overview

## Entities
1. Patients
2. Doctors
3. Appointments
4. Medical Records
5. Departments
6. Lab Tests

## Relationships
- One Patient can have many Appointments
- One Doctor can have many Appointments
- One Appointment has one Medical Record
...
```

### 2. **design-decisions.md**
```md
# Database Design Decisions

## Why UUID instead of SERIAL?
- Globally unique identifiers
- Better for distributed systems
- Prevents ID prediction attacks

## Why CITEXT for emails?
- Case-insensitive comparisons
- Prevents duplicate emails (john@example.com = JOHN@example.com)
...
```

### 3. **table-descriptions.md**
```md
# Table Descriptions

## app.patients
**Purpose:** Stores patient demographic and contact information

**Columns:**
- `id` - Unique identifier
- `patient_number` - Human-readable patient ID (e.g., PT2024001)
- `first_name` - Patient's first name
...

**Business Rules:**
- Patient must be at least 0 years old
- Email must be unique
- Phone number is required
...
```

---

## 🤝 Working with our Team

### With Data Manager (Cherrylyn):
- ✅ Share our schema changes immediately
- ✅ Ensure sample data matches our constraints
- ✅ Test together: your schema + her seeds

### With Query Specialist (Jason):
- ✅ Create views for complex queries
- ✅ Ensure indexes support common queries
- ✅ Discuss what reports are needed

### With DevOps (Faisal):
- ✅ Document all schema changes
- ✅ Create migration files for changes
- ✅ Test schema deployment

---

## 🎓 Learning Resources

- **PostgreSQL Documentation:** https://www.postgresql.org/docs/18/
- **Database Design Tutorial:** https://www.guru99.com/database-design.html
- **ER Diagram Guide:** https://www.lucidchart.com/pages/er-diagrams
- **Normalization Explained:** https://www.studytonight.com/dbms/database-normalization.php

---

## ⚠️ Common Mistakes to Avoid

❌ **Don't use** `VARCHAR` without length: `VARCHAR(200)` 
❌ **Don't forget** `ON DELETE CASCADE/RESTRICT` on foreign keys  
❌ **Don't create** tables without indexes on foreign keys  
❌ **Don't use** `SERIAL` (use `UUID` instead)  
❌ **Don't forget** to add comments to tables and complex columns  
❌ **Don't** commit `.env` file to git  

---

## 📞 Need Help?

1. Check existing schema in `01_core_schema.sql`
2. Review seed data in `database/seeds/`
3. Ask in team meeting
4. Check pgAdmin for visual reference