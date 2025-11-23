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

npm run schema:create      # Create core schema (tables, indexes)
npm run monitoring:enable  # Enable audit triggers
npm run schema:full        # Create schema + enable monitoring
npm run schema:drop        # Drop and recreate app schema
npm run schema:rebuild     # Drop, recreate, and reload

npm run seeds:reference  # Load conditions, symptoms, medications
npm run seeds:patients   # Load 200 patient records
npm run seeds:doctors    # Load 20 doctor records
npm run seeds:admins     # Load 5 admin accounts
npm run seeds:run        # Load all seeds in order

npm run queries:validate  # Validate database structure & data
npm run queries:test      # Run test queries
npm run queries:run       # Run validation + test queries

npm run project:fresh  # Fresh start: reset + schema + seeds
npm run project:check  # Check if everything is running
npm run pgadmin        # Show pgAdmin URL
```

## Database Details

- **Host:** localhost:5432
- **Database:** jon_database_dev
- **Username:** jondb_admin
- **Password:** JonathanBangerDatabase26!

## Project Structure 
```
Jon-Database-Management/
├── database/
│   ├── project/
│   │   ├── 01_core_schema.sql       ← Main schema file
│   │   └── databaseSchema.md        ← Complete documentation
│   ├── seeds/
│   │   ├── 01_patients_seed.sql     ← Sample patients
│   │   ├── 02_doctors_seed.sql      ← Sample doctors
│   │   └── seeds.md                 ← Data documentation
│   ├── queries/
│   │   ├── test_queries.sql         ← Test queries
│   │   └── testQuery.md             ← Query guide
│   ├── init/
│   │   └── 01_setup.sql             ← Database initialization
│   ├── backups/                     ← Backup location
│   └── migrations/                  ← Schema migrations
├── docs/
│   ├── README.md                    ← DevOps guide
│   └── guides/
│       └── git-workflow.md          ← Git branching strategy
├── scripts/
│   └── setup-database.sh            ← Automated setup script
├── docker-compose.yml               ← Docker configuration
├── package.json                     ← NPM commands
├── .env                             ← Environment variables
└── README.md                        ← This file
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