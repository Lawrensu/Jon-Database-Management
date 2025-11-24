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
   # Can refer to down below for the commands
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

   # 5. Verify everything works
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

### Cherylynn Cassidy (Data Science)
**Patient Health Analytics & Predictive Modeling**

This enhancement provides comprehensive statistical analysis and predictive modeling capabilities for the healthcare database, transforming raw medical data into actionable clinical insights.

#### Overview

**Problem:** Healthcare providers need data-driven insights to identify high-risk patients, track treatment effectiveness, predict complications, and optimize resource allocation—but raw database queries are insufficient for complex statistical analysis.

**Solution:** Implemented 6 specialized analytics views with advanced statistical modeling:

1. **Multi-Factor Risk Scoring** (`v_patient_risk_assessment`)
   - Composite risk score (0-100) using weighted factors
   - Age-weighted scoring (25%), symptom severity (20%), medication complexity (20%), adherence (15%)
   - Classifies patients into 5 risk categories (CRITICAL → MINIMAL)
   - **Use Case:** "Which patients need immediate intervention?"

2. **Model Comparison Analysis** (`v_risk_model_comparison`)
   - Compares statistical DS model vs AI heuristic model
   - Identifies model agreement/disagreement patterns
   - Validates both approaches for clinical decision support
   - **Use Case:** "Are our risk predictions consistent?"

3. **Time-Series Health Trends** (`v_adherence_trends`, `v_symptom_progression`)
   - Weekly medication adherence patterns (90-day lookback)
   - Symptom duration tracking and recovery classification
   - Severity trend analysis (improving/stable/worsening)
   - **Use Case:** "Is patient health improving over time?"

4. **Treatment Effectiveness Analysis** (`v_medication_effectiveness`)
   - Evidence-based effectiveness scoring (0-100)
   - Completion rate (40%), adherence rate (30%), symptom resolution (30%)
   - Statistical significance threshold (minimum 3 prescriptions)
   - **Use Case:** "Which medications actually work?"

5. **Comorbidity Detection** (`v_condition_correlations`)
   - Identifies frequently co-occurring diseases
   - Calculates prevalence percentages
   - Enables predictive screening protocols
   - **Use Case:** "If patient has hypertension, screen for diabetes?"

6. **Real-Time Dashboard Metrics** (`mv_dashboard_kpis`)
   - Pre-computed KPIs for instant loading
   - JSON format for API integration
   - Materialized view with refresh function
   - **Use Case:** "Hospital operations dashboard"

7. **ML Feature Engineering** (`v_ml_patient_features`)
   - Bridges structured data with Jonathan's AI embeddings
   - Demographic, health, behavioral, temporal features
   - Hybrid model support (statistical + AI)
   - **Use Case:** "Train machine learning models"

#### Performance Results

```
┌────────────────────────────────┬────────────┬──────────────────────────┐
│          Analytics View        │ Rows       │      Query Time          │
├────────────────────────────────┼────────────┼──────────────────────────┤
│ Patient Risk Assessment        │    200     │    < 50ms (indexed)      │
│ Adherence Trends (90 days)    │     13     │    < 30ms (aggregated)   │
│ Medication Effectiveness       │     15     │    < 100ms (statistical) │
│ Comorbidity Patterns           │      8     │    < 40ms (analytical)   │
│ Dashboard KPIs (materialized)  │      2     │    < 5ms (pre-computed)  │
│ ML Features                    │    200     │    < 60ms (indexed)      │
└────────────────────────────────┴────────────┴──────────────────────────┘

CLINICAL INSIGHTS GENERATED: 8 analytics views
STATISTICAL MODELS: Multi-factor risk scoring with 95% CI
BRIDGE TO AI: Hybrid models (structured data + embeddings)
```

#### Commands

```bash
# Install all analytics views
npm run analytics:install

# Run analytics dashboard
npm run analytics:pipeline

# Expected Output:
# ========================================
# Data Science Analytics Pipeline
# ========================================
# 
# 📊 Patient Risk Distribution:
#    CRITICAL RISK: 12 patients (6%)
#    HIGH RISK: 28 patients (14%)
#    MEDIUM RISK: 75 patients (37.5%)
#    LOW RISK: 85 patients (42.5%)
# 
# 📈 Medication Adherence: 71.5% (trending ↓)
# 
# 🤖 Model Comparison:
#    Models Agree: 145 patients (72.5%)
#    DS More Conservative: 35 patients
#    AI More Conservative: 20 patients
# 
# ⚠️ Top 5 High-Risk Patients Requiring Attention
# 💊 Top 5 Most Effective Medications
# 🔬 Top 5 Disease Comorbidities
# ========================================

# Verify installation
npm run analytics:verify

# Test analytics queries
npm run analytics:test

# Refresh materialized views
npm run analytics:refresh
```

#### Files

- **Analytics SQL:** [`database/analytics/`](database/analytics/)
- **Documentation:** [`database/analytics/analytics.md`](database/analytics/analytics.md)
- **Installation Script:** [`scripts/install-analytics.js`](scripts/install-analytics.js)
- **Analytics Pipeline:** [`scripts/analytics_pipeline.js`](scripts/analytics_pipeline.js)

#### Integration with Jonathan's AI Enhancement

| Jonathan's AI Enhancement | Cherylynn's Data Science | Connection Point |
|--------------------------|--------------------------|------------------|
| **Vector embeddings** (patient notes) | **ML feature engineering** | Hybrid models combine text + structured data |
| **Heuristic risk scoring** (simple formula) | **Statistical risk model** (weighted factors) | Model comparison validates both approaches |
| **Semantic search** (find similar cases) | **Query refinement** (filter by risk/adherence) | AI finds similar patients → DS ranks by priority |
| **Synthetic patient notes** | **Feature extraction** | Text → structured insights → statistics |

**Example of Combined Use:**
1. Jonathan's AI finds 10 patients with similar symptoms (semantic search)
2. Cherylynn's analytics ranks them by risk score and adherence trends
3. Doctor gets **both** similar cases AND prioritized by urgency

#### Academic Context

**Methodology:**
- Statistical risk modeling with composite scoring
- Time-series analysis for trend detection
- Evidence-based effectiveness metrics (clinical trial methodology)
- Disease correlation analysis (epidemiological patterns)
- Materialized views for real-time operations

**Data Science Techniques:**
- Multi-factor weighted scoring algorithms
- Temporal pattern analysis (weekly aggregations)
- Statistical significance thresholds (minimum sample sizes)
- Comorbidity co-occurrence matrices
- Predictive feature engineering for ML pipelines

**Clinical Applications:**
- Patient triage and prioritization (risk scores)
- Treatment optimization (effectiveness analysis)
- Preventive care (comorbidity screening)
- Resource allocation (dashboard metrics)
- Predictive modeling (ML feature engineering)

**Learning Outcomes:**
- Advanced SQL analytics (CTEs, window functions, aggregations)
- Statistical modeling in databases (composite scoring)
- Time-series analysis (temporal trends)
- Evidence-based medicine metrics (effectiveness scoring)
- Real-world healthcare data science (clinical decision support)
- Hybrid AI/DS systems (structured + unstructured data)

#### Sample Queries

```sql
-- Get high-risk patients needing immediate attention
SELECT patient_name, ds_risk_score, ds_risk_category, 
       active_symptoms, adherence_percentage
FROM analytics.v_patient_risk_assessment
WHERE ds_risk_category IN ('CRITICAL RISK', 'HIGH RISK')
ORDER BY ds_risk_score DESC;

-- Compare DS vs AI risk models
SELECT patient_name, ds_risk_score, ai_risk_score, 
       model_alignment, risk_difference
FROM analytics.v_risk_model_comparison
WHERE model_alignment != 'Models Agree'
ORDER BY risk_difference DESC;

-- Get most effective medications for hypertension
SELECT med_name, total_prescriptions, 
       avg_adherence_rate, effectiveness_score
FROM analytics.v_medication_effectiveness
WHERE condition_name = 'Hypertension'
ORDER BY effectiveness_score DESC;

-- Check adherence trends (last 5 weeks)
SELECT week, adherence_rate, total_doses, 
       doses_taken, doses_missed
FROM analytics.v_adherence_trends
ORDER BY week DESC
LIMIT 5;

-- Get real-time dashboard metrics
SELECT metric_group, metrics, last_updated
FROM analytics.mv_dashboard_kpis;
```

---