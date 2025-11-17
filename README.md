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

   # 3. Setup database (one command does everything!)
   npm run db:setup

   # 4. Create database schema
   npm run schema:create

   # 5. Load conditions, symptoms, side effects, medications
   npm run seeds:reference

   #Expected Output
   ✅ Reference Data Loaded Successfully
   Conditions: 27 records
   Symptoms: 10 records
   Side Effects: 11 records
   Medications: 15 records

   # 6. Verify everything works
   npm run queries:validate

   #Expected Output
   Schema Validation     | 16 | 16 | ✅ PASS
   Conditions            | 27 | 27 | ✅ PASS
   Symptoms              | 10 | 10 | ✅ PASS
   Side Effects          | 11 | 11 | ✅ PASS
   Medications           | 15 | 15 | ✅ PASS
```

## Available Commands

```bash
npm run db:setup     # Initial setup
npm run db:start     # Start database
npm run db:stop      # Stop database
npm run db:connect   # Connect to database
npm run db:logs      # View database logs
npm run db:reset     # Reset to clean state
npm run pgadmin      # Show pgAdmin URL
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