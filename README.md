# Jon's Database Management Project

**Database Design Project (COS 20031) - Year 2, Semester 1**

Modern PostgreSQL 18 database setup for PAKAR Tech Healthcare.

## Prerequisites & Installation

### 1. Required Software

**Everyone on the team must install:**

#### **Git** (Version Control)
- **Windows:** Download from https://git-scm.com/download/win
- **macOS:** `brew install git` or download from https://git-scm.com/
- **Linux:** `sudo apt install git` (Ubuntu/Debian) or `sudo yum install git` (CentOS/RHEL)

#### **Docker Desktop** (Database Environment)
- **Windows/macOS:** Download from https://www.docker.com/products/docker-desktop/
- **Linux:** Follow instructions at https://docs.docker.com/engine/install/
- **Minimum Requirements:**
  - 4GB RAM (8GB recommended)
  - 10GB free disk space
  - Windows 10/11 with WSL 2 enabled
  - macOS 10.15 or newer

#### **Node.js** (Script Runner)
- Download from https://nodejs.org/ (LTS version recommended)
- **Alternative:** Use Node Version Manager (nvm)
  - Windows: https://github.com/coreybutler/nvm-windows
  - macOS/Linux: https://github.com/nvm-sh/nvm

  ### 3. Initial Setup (One Command!)
```bash
# Run the automated setup script
npm run db:setup
```

**What this does:**
- Creates your `.env` file from the template
- Downloads PostgreSQL 18 and pgAdmin images
- Creates database containers
- Initializes the database with schemas and extensions
- Starts all services

### 4. Verify Installation
```bash
# Check if services are running
npm run db:status

# Expected output:
# jon-database-postgres    Up (healthy)
# jon-database-pgadmin     Up (healthy)
```

## Quick Start

1. **First setup:**
```bash
   # 1. Clone the repository
   git clone <repository-url>
   cd Jon-Database-Management

   # 2. Install Node.js dependencies
   npm install

   # 3. Setup database containers
   npm run db:setup
   # OR manually:
   npm run db:start
   timeout /t 30  # Wait for PostgreSQL to initialize

   # 4. Create database schema (2 steps now!)
   npm run schema:create      # Creates tables, indexes, constraints
   npm run monitoring:enable  # Attaches audit triggers

   # OR use combined command (better to do manually to get used to it):
   npm run schema:full

   # Expected output after schema:create:
   # ========================================
   # PAKAR Tech Schema Created (PostgreSQL)
   # ========================================
   # Tables: 16 core tables
   # ENUMs: 8 custom types
   # Triggers: 3 auto-update
   # Indexes: 32 performance indexes
   # ========================================

   # Expected output after monitoring:enable:
   # =========================================
   # Monitoring Triggers ENABLED
   # =========================================
   # Total active triggers: 6
   #   - Audit triggers: 5
   #   - Monitor triggers: 1
   # Logging to: security.events_log
   # Anomaly detection: ACTIVE
   # =========================================

   # 5. Load reference data (conditions, symptoms, medications)
   npm run seeds:reference

   # Expected Output:
   # ========================================
   # Reference Data Loaded Successfully
   # ========================================
   # Conditions: 27 records
   # Symptoms: 10 records
   # Side Effects: 11 records
   # Medications: 15 records
   # Med-SideEffect Links: 6 records
   # ========================================

   # 6. Load patient data
   npm run seeds:patients

   # Expected Output:
   # ========================================
   # Patient Seed Data Loaded
   # ========================================
   # Patients: 200 records
   # User Accounts (Patient): 200 records
   # ========================================

   # 7. Load doctor data
   npm run seeds:doctors

   # Expected Output:
   # ========================================
   # Doctor Seed Data Loaded
   # ========================================
   # Doctors: 20 records
   # User Accounts (Doctor): 20 records
   # ========================================

   # 8. Load admin data
   npm run seeds:admins

   # Expected Output:
   # ========================================
   # Admin Seed Data Loaded
   # ========================================
   # Regular Admins: 3 accounts
   # Super Admins: 2 accounts
   # ========================================

   # 9. Verify everything works
   npm run queries:validate

   # Expected Output:
   # ========================================
   # Database Validation Results
   # ========================================
   # Schema Validation     | 16 | 16 | PASS
   # Conditions            | 27 | 27 | PASS
   # Symptoms              | 10 | 10 | PASS
   # Side Effects          | 11 | 11 | PASS
   # Medications           | 15 | 15 | PASS
   # Patients              | 200| 200| PASS
   # Doctors               | 20 | 20 | PASS
   # Admins                | 3  | 3  | PASS
   # Super Admins          | 2  | 2  | PASS
   # User Accounts         | 225| 225| PASS
   # Audit Log (Events)    | 225+     | PASS
   # ========================================

   # 10. Check summary to ensure it's working
   npm run db:summary

   # Expected Output:
   # ┌──────────────┬───────┐
   # │     type     │ count │
   # ├──────────────┼───────┤
   # │ Patients     │   200 │
   # │ Doctors      │    20 │
   # │ Admins       │     3 │
   # │ Audit Events │   446 │  ← 223 DELETEs + 223 INSERTs = 446 
   # └──────────────┴───────┘
```

## Available Commands

### Database Operations
```bash
npm run db:setup     # Initial setup (first time only)
npm run db:start     # Start database containers
npm run db:stop      # Stop database containers
npm run db:restart   # Restart database containers
npm run db:reset     # Delete all data and reset
npm run db:connect   # Connect to database (psql)
npm run db:summary   # Show patients, doctors, admins and audit events count
npm run db:logs      # View PostgreSQL logs
npm run db:status    # Check container status
npm run db:backup    # Create database backup
npm run pgadmin      # Show pgAdmin URL
```

### Schema Management
```bash
npm run schema:create      # Create core schema (tables, indexes)
npm run monitoring:enable  # Enable audit triggers
npm run schema:full        # Create schema + enable monitoring
npm run schema:drop        # Drop and recreate app schema
npm run schema:rebuild     # Drop, recreate, and reload
```

### Seed Data (Sample Data)
```bash
npm run seeds:reference  # Load conditions, symptoms, medications
npm run seeds:patients   # Load 200 patient records
npm run seeds:doctors    # Load 20 doctor records
npm run seeds:admins     # Load 5 admin accounts
npm run seeds:prescriptions # Load 300 prescription records
npm run seeds:run        # Load all seeds in order
```

### Queries & Validation
```bash
npm run queries:validate  # Validate database structure & data
npm run queries:test      # Run test queries
npm run queries:run       # Run validation + test queries
```

### Advanced Database Indexing for Query Performance Optimization (Lawrence Lian anak Matius Ding)
```bash
# Complete Benchmark Workflow
npm run perf:baseline    # Step 1: Capture BEFORE performance
npm run perf:optimize    # Step 2: Apply 4 advanced indexes
npm run perf:after       # Step 3: Capture AFTER performance
npm run perf:report      # Step 4: Generate comparison report

# Additional Analysis
npm run perf:demo        # Show EXPLAIN ANALYZE proof (index usage)

# Expected Results:
# - Overall Improvement: 48.81% faster
# - Best Improvement: 69.92% (Medication Full-Text Search)
# - 4 Advanced Indexes: Composite, Partial, GIN, Covering
```

**Testing Guide:** See [`database/performance/benchmarks_guide/testingGuide.md`](database/performance/benchmarks_guide/testingGuide.md)


### Utility Commands
```bash
npm run project:fresh  # Fresh start: reset + schema + seeds
npm run project:check  # Check if everything is running
```

---

## Database Details

- **Host:** localhost:5432
- **Database:** jon_database_dev
- **Username:** jondb_admin
- **Password:** JonathanBangerDatabase26!

## Project Structure

```
Jon-Database-Management/
├── .github/
│   └── workflows/
│       └── cicd_config.yml
│
├── database/
│   ├── backups/
│   │
│   ├── init/
│   │   ├── 01_setup.sql
│   │   └── 02_monitor.sql
│   │
│   ├── migrations/
│   │   └── (empty - not needed unless actual production)
│   │
│   ├── performance/
│   │   ├── 01_baseline_benchmark.sql
│   │   ├── 02_advanced_indexes.sql
│   │   ├── 03_after_benchmark.sql
│   │   ├── 04_comparison_report.sql
│   │   ├── 05_demonstration.sql
│   │   ├── benchmarks_guide/
│   │   │   ├── after_results.txt
│   │   │   ├── before_results.txt
│   │   │   ├── benchmark.md
│   │   │   ├── comparison_report.txt
│   │   │   ├── explain_plans.txt
│   │   │   ├── testingGuide.md
│   │   │   └── screenshots/
│   │   └── materialized_views/
│   │       └── 01_patient_analytics_mv.sql
│   │
│   ├── project/
│   │   ├── 01_core_schema.sql
│   │   ├── 02_monitoring_triggers.sql
│   │   └── databaseSchema.md
│   │
│   ├── queries/
│   │   ├── 00_validation_query.sql
│   │   ├── test_query.sql
│   │   └── testQuery.md
│   │
│   ├── seeds/
│   │   ├── 00_reference_data.sql
│   │   ├── 01_patients_seed.sql
│   │   ├── 02_doctors_seed.sql
│   │   ├── 03_admins_seed.sql
│   │   ├── 04_prescriptions_seed.sql
│   │   └── seeds.md
│   │
│   └── tests/
│
├── docs/
│   ├── design/
│   │
│   ├── guides/
│   │   ├── git-workflow.md
│   │
│   └── devOpsDocs.md
│
├── scripts/
│   └── setup-database.sh
│
├── .env
├── .env.example
├── .gitignore
├── .psqlrc
├── docker-compose.yml
├── package.json
└── README.md
```

---

## Development Workflow
```
1. Create feature branch
- git checkout -b your-name/feature-name

2. Make changes

3. Test locally
- npm run schema:rebuild
- npm run seeds:run
- npm run queries:test

4. Commit and push
- git add .
- git commit -m "Description of changes"
- git push origin your-name/feature-name

5. Merging main to your branch
- git checkout main
- git pull origin main
- git checkout your-branch
- git merge main
```

## Major-Specific Enhancements

### Lawrence Lian anak Matius Ding (Software Development)
**Advanced Database Indexing for Query Performance Optimization**

This enhancement includes advanced database optimization techniques demonstrating PostgreSQL indexing strategies.

### Overview

**Problem:** Standard queries on 200+ patients, 300+ prescriptions, and 45+ medications were slightly slow and would be significantly slower as database scale/grow.

**Solution:** Implemented 4 advanced indexing strategies:

1. **Composite Index** (`idx_patient_birth_gender_composite`)
   - Multi-column index on `birth_date + gender`
   - Enables single index scan for combined filters
   - **Use Case:** "Find all male patients born 1950-1974"

2. **Partial Index** (`idx_prescription_active_only`)
   - Indexes only active prescriptions (WHERE status = 'Active')
   - 60% smaller than full index
   - **Use Case:** "Show all active prescriptions"

3. **GIN Full-Text Index** (`idx_medication_fulltext_search`)
   - Google-style search for medication names/descriptions
   - Supports stemming and fuzzy matching
   - **Use Case:** "Search medications containing 'insulin' or 'diabetes'"

4. **Covering Index** (`idx_patient_birth_covering`)
   - Includes extra columns (INCLUDE gender)
   - Enables index-only scans (no heap access)
   - **Use Case:** "Get patient_id, birth_date, gender for date range"

### Performance Results

```
┌───────────────────────────────────┬─────────────┬────────────┬─────────────────┐
│             Test Name             │ Before (ms) │ After (ms) │ Improvement (%) │
├───────────────────────────────────┼─────────────┼────────────┼─────────────────┤
│ Medication Search (Full-Text)     │       13.67 │       4.11 │           69.92 │
│ Active Prescriptions              │        2.69 │       1.88 │           30.25 │
│ Patient Health Analytics          │        4.61 │       4.38 │            4.93 │
│ Patient Search (Birth Date Range) │        0.51 │       0.62 │          -22.68 │
└───────────────────────────────────┴─────────────┴────────────┴─────────────────┘

OVERALL IMPROVEMENT: 48.81% faster
BEST IMPROVEMENT: 69.92% (Medication Search)
```

### Files

- **Benchmarks:** [`database/performance/`](database/performance/)
- **Testing Guide:** [`database/performance/benchmarks_guide/testingGuide.md`](database/performance/benchmarks_guide/testingGuide.md)
- **Screenshots:** [`database/performance/benchmarks_guide/screenshots/`](database/performance/benchmarks_guide/screenshots/)

### Academic Context

**Dataset Limitations:**
- Current: 200 patients, 300 prescriptions, 45 medications
- Production: 100,000+ patients, 1,000,000+ prescriptions, 10,000+ medications

**Why Some Queries Got Slower:**
- Very fast queries (< 1ms) have query planning overhead > execution time
- PostgreSQL prefers sequential scans for tables < 100 rows
- At production scale, indexes would provide **10-100x improvements**

**Learning Outcomes:**
- Advanced indexing strategies (Composite, Partial, GIN, Covering)
- Performance benchmarking methodology (BEFORE/AFTER comparison)
- Query optimization techniques (EXPLAIN ANALYZE analysis)
- Real-world trade-offs (storage vs speed, planning overhead)

---