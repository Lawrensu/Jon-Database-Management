# PAKAR Tech Healthcare Database - Schema Documentation

**Project:** Database Design Project (COS 20031)  
**Team:** Lawrence, Jonathan, Cherrylyn, Jason, Faisal  
**Database:** PostgreSQL 18  
**Last Updated:** January 2025

---

## Executive Summary

Medication management system with patient records, prescriptions, adherence tracking, and role-based access control.

**Key Metrics:**
- **16 Tables** in `app` schema
- **15 Foreign Key Relationships**
- **51 Indexes** for performance
- **11 Check Constraints** for data validation
- **UUID Primary Keys** for distributed system support

---

## Database Structure

### User Management (3 tables)
1. **admin** - System administrators
2. **super_admin** - Elevated privilege accounts
3. **user_account** - Regular users (Patient/Doctor)

### Core Entities (3 tables)
4. **patient** - Patient demographics and contacts
5. **doctor** - Doctor credentials and licenses
6. **reminder** - Medication reminders

### Medical Data (3 tables)
7. **condition** - Medical conditions (Hypertension, Diabetes, etc.)
8. **symptom** - Symptoms linked to conditions
9. **patient_symptom** - Junction: Patients ↔ Symptoms

### Medications (3 tables)
10. **medication** - Medication master data
11. **side_effect** - Side effects catalog
12. **medication_side_effect** - Junction: Medications ↔ Side Effects

### Prescriptions (2 tables)
13. **prescription** - Prescription master record
14. **prescription_version** - Version history (dosage changes)

### Tracking (2 tables)
15. **medication_schedule** - When/how to take medication
16. **medication_log** - Adherence tracking (Taken/Missed/Skipped)

---

## Key Relationships
user_account (1) ──→ (1) patient
user_account (1) ──→ (1) doctor

patient (1) ──→ (N) prescription
doctor (1) ──→ (N) prescription

prescription (1) ──→ (N) prescription_version
prescription_version (1) ──→ (N) medication_schedule

patient (N) ←──→ (N) symptom (via patient_symptom)
medication (N) ←──→ (N) side_effect (via medication_side_effect)


---

## Table Details

### 1. admin
| Column | Type | Key |
|--------|------|-----|
| id | UUID | PK |
| admin_id | VARCHAR(50) | UNIQUE |
| username | VARCHAR(50) | UNIQUE |
| password_hash | VARCHAR(255) | - |
| created_at | TIMESTAMP | - |

**Purpose:** System administrators for management tasks.

---

### 2. super_admin
| Column | Type | Key |
|--------|------|-----|
| id | UUID | PK |
| super_admin_id | VARCHAR(50) | UNIQUE |
| username | VARCHAR(50) | UNIQUE |
| password_hash | VARCHAR(255) | - |
| created_at | TIMESTAMP | - |

**Purpose:** Elevated privilege accounts with full system access.

---

### 3. user_account
| Column | Type | Constraints |
|--------|------|-------------|
| id | UUID | PK |
| user_id | VARCHAR(50) | UNIQUE |
| username | VARCHAR(50) | UNIQUE |
| password_hash | VARCHAR(255) | NOT NULL |
| user_type | VARCHAR(20) | CHECK: 'Patient' or 'Doctor' |
| is_active | BOOLEAN | DEFAULT TRUE |
| created_at | TIMESTAMP | DEFAULT NOW() |

**Purpose:** Regular user accounts for patients and doctors.

---

### 4. patient
| Column | Type | Constraints |
|--------|------|-------------|
| id | UUID | PK |
| patient_id | VARCHAR(50) | UNIQUE |
| user_id | UUID | FK → user_account |
| phone_num | VARCHAR(20) | NOT NULL |
| birth_date | DATE | CHECK: ≤ TODAY |
| gender | VARCHAR(20) | CHECK: Male/Female/Other |
| address | VARCHAR(300) | NULL |
| emergency_contact_name | VARCHAR(100) | NULL |
| emergency_contact_phone | VARCHAR(20) | NULL |
| created_at | TIMESTAMP | AUTO |
| updated_at | TIMESTAMP | AUTO (trigger) |

**Purpose:** Patient demographics and contact information.

---

### 5. doctor
| Column | Type | Constraints |
|--------|------|-------------|
| id | UUID | PK |
| doctor_id | VARCHAR(50) | UNIQUE |
| user_id | UUID | FK → user_account |
| phone_num | VARCHAR(20) | NOT NULL |
| license_num | VARCHAR(100) | UNIQUE, NOT NULL |
| license_exp | DATE | NOT NULL |
| gender | VARCHAR(20) | CHECK: Male/Female/Other |
| specialization | VARCHAR(200) | NULL |
| qualification | VARCHAR(300) | NULL |
| created_at | TIMESTAMP | AUTO |
| updated_at | TIMESTAMP | AUTO (trigger) |

**Purpose:** Doctor credentials and professional information.

---

### 6. reminder
| Column | Type | Constraints |
|--------|------|-------------|
| id | UUID | PK |
| reminder_id | VARCHAR(50) | UNIQUE |
| patient_id | UUID | FK → user_account |
| medication_schedule_id | UUID | FK → medication_schedule |
| message | VARCHAR(500) | NOT NULL |
| schedule | TIMESTAMP | NOT NULL |

**Purpose:** Medication reminders for patients.

---

### 7. condition
| Column | Type | Constraints |
|--------|------|-------------|
| id | UUID | PK |
| condition_id | VARCHAR(50) | UNIQUE |
| condition_name | VARCHAR(200) | NOT NULL |
| condition_desc | TEXT | NULL |

**Purpose:** Medical conditions (Hypertension, Diabetes, Asthma, etc.).

**Sample Data:** COND001-COND005 (5 common conditions)

---

### 8. symptom
| Column | Type | Constraints |
|--------|------|-------------|
| id | UUID | PK |
| symptom_id | VARCHAR(50) | UNIQUE |
| condition_id | UUID | FK → condition |
| notes | TEXT | NULL |
| severity | VARCHAR(20) | CHECK: Mild/Moderate/Severe |
| date_reported | TIMESTAMP | DEFAULT NOW() |

**Purpose:** Symptoms linked to medical conditions.

---

### 9. patient_symptom
| Column | Type | Constraints |
|--------|------|-------------|
| id | UUID | PK |
| patient_id | UUID | FK → patient |
| symptom_id | UUID | FK → symptom |
| date_reported | TIMESTAMP | DEFAULT NOW() |

**Unique:** (patient_id, symptom_id, date_reported)

**Purpose:** Many-to-many junction linking patients to their symptoms.

---

### 10. medication
| Column | Type | Constraints |
|--------|------|-------------|
| id | UUID | PK |
| medication_id | VARCHAR(50) | UNIQUE |
| med_name | VARCHAR(200) | NOT NULL |
| med_brand_name | VARCHAR(200) | NULL |
| manufacturer | VARCHAR(200) | NULL |
| med_dose | VARCHAR(100) | NULL |

**Purpose:** Medication master data catalog.

---

### 11. side_effect
| Column | Type | Constraints |
|--------|------|-------------|
| id | UUID | PK |
| side_effect_id | VARCHAR(50) | UNIQUE |
| condition_id | UUID | FK → condition (if mimics condition) |

**Purpose:** Side effects catalog.

---

### 12. medication_side_effect
| Column | Type | Constraints |
|--------|------|-------------|
| id | UUID | PK |
| medication_id | UUID | FK → medication |
| side_effect_id | UUID | FK → side_effect |
| frequency | VARCHAR(100) | NULL (Common/Rare) |

**Unique:** (medication_id, side_effect_id)

**Purpose:** Many-to-many junction linking medications to side effects.

---

### 13. prescription
| Column | Type | Constraints |
|--------|------|-------------|
| id | UUID | PK |
| prescription_id | VARCHAR(50) | UNIQUE |
| patient_id | UUID | FK → patient (RESTRICT) |
| doctor_id | UUID | FK → doctor (RESTRICT) |
| created_date | TIMESTAMP | DEFAULT NOW() |
| status | VARCHAR(50) | CHECK: Active/Completed/Cancelled/Expired |
| doctor_note | TEXT | NULL |

**Purpose:** Prescription master record.

**ON DELETE RESTRICT:** Cannot delete patient/doctor with active prescriptions.

---

### 14. prescription_version
| Column | Type | Constraints |
|--------|------|-------------|
| id | UUID | PK |
| prescription_version_id | VARCHAR(50) | UNIQUE |
| prescription_id | UUID | FK → prescription (CASCADE) |
| medication_id | UUID | FK → medication (RESTRICT) |
| titration | DECIMAL(10,2) | NULL |
| titration_unit | VARCHAR(50) | CHECK: mg/ml/tablets/capsules/units |
| start_date | TIMESTAMP | DEFAULT NOW() |
| end_date | TIMESTAMP | NULL (NULL = current version) |
| reason_for_change | TEXT | NULL |

**Purpose:** Immutable audit trail of dosage changes (temporal versioning).

---

### 15. medication_schedule
| Column | Type | Constraints |
|--------|------|-------------|
| id | UUID | PK |
| medication_schedule_id | VARCHAR(50) | UNIQUE |
| prescription_version_id | UUID | FK → prescription_version (CASCADE) |
| med_timing | VARCHAR(50) | CHECK: BeforeMeal/AfterMeal |
| frequency_times_daily | INT | CHECK: 1-6 |
| frequency_interval_hours | INT | CHECK: 1-24 |
| duration | INT | NULL |
| duration_unit | VARCHAR(50) | CHECK: Days/Weeks/Months |
| updated_at | TIMESTAMP | AUTO (trigger) |

**Purpose:** Defines when and how often to take medication.

---

### 16. medication_log
| Column | Type | Constraints |
|--------|------|-------------|
| id | UUID | PK |
| medication_log_id | VARCHAR(50) | UNIQUE |
| patient_id | UUID | FK → patient (CASCADE) |
| medication_id | UUID | FK → medication (RESTRICT) |
| medication_schedule_id | UUID | FK → medication_schedule (SET NULL) |
| notes | TEXT | NULL |
| scheduled_time | TIMESTAMP | NOT NULL |
| actual_taken_time | TIMESTAMP | NULL |
| status | VARCHAR(50) | CHECK: Taken/Missed/Skipped, DEFAULT Missed |

**Purpose:** Tracks actual medication intake for adherence monitoring.

---

## Constraints Summary

### Check Constraints (11)
- `patient.birth_date ≤ CURRENT_DATE`
- `patient.gender IN ('Male', 'Female', 'Other')`
- `doctor.gender IN ('Male', 'Female', 'Other')`
- `user_account.user_type IN ('Patient', 'Doctor')`
- `symptom.severity IN ('Mild', 'Moderate', 'Severe')`
- `prescription.status IN ('Active', 'Completed', 'Cancelled', 'Expired')`
- `prescription_version.titration_unit IN ('mg', 'ml', 'tablets', 'capsules', 'units')`
- `medication_schedule.med_timing IN ('BeforeMeal', 'AfterMeal')`
- `medication_schedule.frequency_times_daily BETWEEN 1 AND 6`
- `medication_schedule.frequency_interval_hours BETWEEN 1 AND 24`
- `medication_log.status IN ('Taken', 'Missed', 'Skipped')`

### Unique Constraints (19)
- All `*_id` business identifiers
- All `username` columns
- `(patient_id, symptom_id, date_reported)` on patient_symptom
- `(medication_id, side_effect_id)` on medication_side_effect

---

## Indexes (51 total)

**Primary:** UUID on all tables (16)  
**Foreign Keys:** All FK columns (15)  
**Business Keys:** All `*_id` columns (16)  
**Performance:** user_type, prescription_status, symptom_severity, med_log_status (4)

---

## Triggers (3)

**Auto-update `updated_at` on:**
- `patient`
- `doctor`
- `medication_schedule`

```sql
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;