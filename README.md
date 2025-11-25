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

### Jonathan (Artificial Intelligence)
**AI-Powered Semantic Search & Intelligent Risk Scoring**

This enhancement integrates advanced AI capabilities into the healthcare database, enabling semantic patient matching, intelligent audit logging, and automated risk assessment through vector embeddings and machine learning techniques.

#### Overview

**Problem:** Traditional keyword-based searches cannot understand medical context or find conceptually similar patient cases. Static rule-based systems fail to adapt to complex patient patterns, and manual risk assessment is time-consuming and inconsistent.

**Solution:** Implemented AI-powered infrastructure with 4 core components:

1. **Vector Embeddings for Semantic Search** (`app.embedding`)
   - 1536-dimensional vector storage using pgvector extension
   - IVFFlat indexing for fast similarity search (sub-100ms queries)
   - Supports natural language patient note retrieval
   - **Use Case:** "Find patients with similar symptoms to current case"

2. **Intelligent Audit Logging** (`app.audit_log`)
   - Automatic change tracking for patient, prescription, and user data
   - Captures before/after states in JSONB format
   - Trigger-based real-time logging for compliance
   - **Use Case:** "Track who modified prescription records and when"

3. **AI-Driven Risk Scoring** (`health_risk_score`)
   - Heuristic model with 3 weighted factors: age (40%), conditions (35%), adherence (25%)
   - Auto-recomputes on patient data changes via triggers
   - Normalized 0.00-1.00 scale for integration with DS models
   - **Use Case:** "Identify high-risk patients needing intervention"

4. **Semantic Patient Suggestion Service** (Node.js API)
   - Cosine similarity search using vector distance operators
   - Real-time treatment recommendations based on similar cases
   - Integration-ready for external embedding APIs (OpenAI, Cohere)
   - **Use Case:** "Given patient symptoms, suggest similar treatment plans"

#### Performance Results

```
┌──────────────────────────────────┬─────────────┬───────────────────────────┐
│          AI Feature              │ Performance │       Capability          │
├──────────────────────────────────┼─────────────┼───────────────────────────┤
│ Vector Similarity Search         │   < 50ms    │  Find top 5 similar cases │
│ Embedding Storage (1536-dim)     │   < 10ms    │  Insert with JSONB meta   │
│ IVFFlat Index Build (200 vecs)   │   < 2s      │  100 lists, L2 distance   │
│ Risk Score Computation           │   < 20ms    │  3-factor weighted model  │
│ Audit Log Insert                 │   < 5ms     │  JSONB before/after state │
│ Trigger-Based Recomputation      │   < 30ms    │  Auto-update on changes   │
└──────────────────────────────────┴─────────────┴───────────────────────────┘

AI INFRASTRUCTURE: pgvector extension + Node.js pg client
EMBEDDING DIMENSION: 1536 (OpenAI-compatible)
INDEX TYPE: IVFFlat (optimized for L2 distance)
INTEGRATION: Bridges with Cherylynn's DS analytics via risk scores
```

#### Commands

```bash
# Install AI enhancement (pgvector + tables + triggers)
npm run ai:install

# Generate 200 synthetic embeddings for development
npm run ai:generate

# Run semantic patient suggestion service
npm run ai:suggest <patient_id> "patient symptoms text"

# Expected Output (ai:install):
# ========================================
# AI Enhancement Installation
# ========================================
# 
# ✅ pgvector extension enabled
# ✅ app.embedding table created (1536-dim vectors)
# ✅ IVFFlat index created (100 lists)
# ✅ app.audit_log table created (JSONB tracking)
# ✅ Audit triggers attached (patient, prescription, user)
# ✅ health_risk_score column added to app.patient
# ✅ Risk computation triggers enabled
# 
# AI Enhancement Ready!
# ========================================

# Expected Output (ai:generate):
# Inserted 0 embeddings
# Inserted 50 embeddings
# Inserted 100 embeddings
# Inserted 150 embeddings
# Inserted synthetic embeddings.

# Expected Output (ai:suggest):
# Top retrieved snippets:
# 1. Patient reports mild headache and nausea for 2 days. (synthetic 142)
# 2. Prescribed medication for high blood pressure; take twice daily. (synthetic 87)
# 3. Follow-up: symptoms improved after therapy. (synthetic 23)
# 4. Patient reports allergy to penicillin. (synthetic 196)
# 5. Medication adherence low; missed last 2 scheduled doses. (synthetic 54)
# 
# Suggested Actions:
# - Check current medications for patient PT-1001
# - Review similar cases above for treatment patterns
# - Schedule follow-up based on risk assessment
```

#### Files

- **AI SQL Schema:** [`database/project/99_ai_extensions.sql`](database/project/99_ai_extensions.sql)
- **Embedding Generator:** [`scripts/generate_synthetic_data.js`](scripts/generate_synthetic_data.js)
- **Suggestion Service:** [`scripts/patient_suggestion_service.js`](scripts/patient_suggestion_service.js)
- **Installation Script:** [`scripts/install-ai.js`](scripts/install-ai.js)
- **Documentation:** [`database/seeds/AI_EMBEDDINGS_DEV.md`](database/seeds/AI_EMBEDDINGS_DEV.md)

#### Integration with Cherylynn's Data Science

| Jonathan's AI Enhancement | Cherylynn's Data Science | Integration Point |
|--------------------------|--------------------------|-------------------|
| **Heuristic risk scoring** (3-factor formula) | **Statistical risk model** (multi-factor weighted) | Both populate risk scores for model comparison |
| **Semantic search** (vector similarity) | **Query refinement** (filter by risk/adherence) | AI finds similar cases → DS ranks by priority |
| **Real-time triggers** (auto-recompute risk) | **Materialized views** (pre-computed KPIs) | Complementary performance strategies |
| **Audit logging** (change tracking) | **Time-series analysis** (temporal trends) | Historical data feeds trend detection |
| **Embedding table** (1536-dim vectors) | **ML feature engineering** | Hybrid models combine embeddings + structured features |

**Example Workflow:**
1. **Jonathan's AI:** New patient notes trigger semantic search → finds 10 similar cases
2. **Cherylynn's DS:** Filters results by `ds_risk_score > 0.7` and `adherence < 70%`
3. **Combined Output:** High-risk similar patients ranked by statistical models
4. **Clinical Value:** Doctor gets both conceptual similarity AND evidence-based prioritization

#### Academic Context

**AI Techniques:**
- Vector embeddings for semantic understanding (1536-dimensional space)
- Cosine similarity search using L2 distance operators
- IVFFlat indexing (Inverted File Flat) for approximate nearest neighbor search
- Trigger-based reactive systems (event-driven architecture)
- Heuristic modeling with weighted multi-factor scoring

**Database AI Integration:**
- pgvector extension for native PostgreSQL vector operations
- JSONB for flexible audit log schema (schema-less metadata)
- Trigger functions for real-time computation (BEFORE/AFTER hooks)
- Index optimization for high-dimensional data (lists tuning)
- Node.js integration for external AI API calls (OpenAI-compatible)

**Production Considerations:**
- **Scalability:** IVFFlat index supports 100K+ vectors with sub-second queries
- **Accuracy:** 1536 dimensions enable nuanced semantic matching
- **Security:** SECURITY DEFINER functions prevent privilege escalation
- **Compliance:** Complete audit trail for HIPAA/healthcare regulations
- **Extensibility:** Modular design allows swapping heuristic model for ML models

**Learning Outcomes:**
- Vector database architecture (pgvector, embeddings, similarity search)
- AI-powered semantic retrieval (NLP embeddings, cosine similarity)
- Intelligent audit systems (JSONB tracking, trigger automation)
- Real-time risk assessment (heuristic models, auto-recomputation)
- Hybrid AI/DB integration (Node.js + PostgreSQL, external APIs)
- Production AI infrastructure (indexing strategies, performance tuning)

#### Sample Queries

```sql
-- Semantic search: Find 5 most similar patient cases
SELECT source_table, source_id, text_snippet,
       embedding <-> '[0.1, 0.2, ..., 0.5]'::vector AS distance
FROM app.embedding
ORDER BY embedding <-> '[0.1, 0.2, ..., 0.5]'::vector
LIMIT 5;

-- Get patients with AI risk scores above threshold
SELECT patient_id, first_name, last_name, health_risk_score
FROM app.patient
WHERE health_risk_score > 0.70
ORDER BY health_risk_score DESC;

-- Audit log: Track prescription changes in last 7 days
SELECT table_name, operation, row_id, changed_by,
       row_before->>'status' AS old_status,
       row_after->>'status' AS new_status,
       changed_at
FROM app.audit_log
WHERE table_name = 'prescription'
  AND changed_at >= NOW() - INTERVAL '7 days'
ORDER BY changed_at DESC;

-- Compare AI vs DS risk models (integration query)
SELECT p.patient_id, p.first_name, p.last_name,
       p.health_risk_score AS ai_risk,
       v.ds_risk_score,
       v.model_alignment
FROM app.patient p
JOIN analytics.v_risk_model_comparison v 
  ON p.patient_id = v.patient_id
WHERE ABS(p.health_risk_score - v.ds_risk_score) > 0.20
ORDER BY ABS(p.health_risk_score - v.ds_risk_score) DESC;

-- Get embeddings for specific patient
SELECT id, text_snippet, created_at
FROM app.embedding
WHERE source_table = 'patient_note'
  AND source_id = 'PT-1001'
ORDER BY created_at DESC;
```

#### Technical Deep Dive

**1. Vector Embedding Architecture:**
```sql
-- 1536-dimensional vectors (OpenAI-compatible)
CREATE TABLE app.embedding (
    embedding vector(1536),  -- Semantic representation
    text_snippet TEXT,       -- Original text for context
    source_table TEXT,       -- Traceability
    source_id TEXT           -- Link to patient/note
);

-- IVFFlat index for fast approximate search
CREATE INDEX idx_embedding_vector_ivfflat
  ON app.embedding USING ivfflat (embedding vector_l2_ops)
  WITH (lists = 100);  -- 100 clusters for 200-10K vectors
```

**2. Intelligent Risk Scoring Algorithm:**
```
risk_score = MIN(1.0, 
    AGE_FACTOR * 0.40 +      -- (age - 40) / 60 capped at 1.0
    CONDITION_FACTOR * 0.35 + -- condition_count / 5 capped at 1.0
    ADHERENCE_FACTOR * 0.25   -- missed_doses / 30 capped at 1.0
)

Example: 65-year-old, 3 conditions, 10 missed doses
= ((65-40)/60 * 0.4) + (3/5 * 0.35) + (10/30 * 0.25)
= (0.417 * 0.4) + (0.6 * 0.35) + (0.333 * 0.25)
= 0.167 + 0.210 + 0.083 = 0.46 (MEDIUM RISK)
```

**3. Audit Logging with JSONB:**
```sql
-- Captures full row state for forensic analysis
INSERT INTO app.audit_log(table_name, operation, row_before, row_after)
VALUES (
    'prescription',
    'U',  -- UPDATE
    '{"status": "Active", "dosage": "10mg"}'::jsonb,
    '{"status": "Completed", "dosage": "10mg"}'::jsonb
);
```

**4. Semantic Search Implementation:**
```javascript
// Node.js: Find similar patients using cosine similarity
const query = `
  SELECT source_id, text_snippet,
         embedding <-> $1 AS distance
  FROM app.embedding
  WHERE source_table = 'patient_note'
  ORDER BY embedding <-> $1
  LIMIT 5;
`;
await client.query(query, [patientEmbedding]);
```

---

## Troubleshooting

### Common Setup Issues

#### 1. **"Cannot find module 'dotenv'" or "Cannot find module 'pg'"**

**Problem:** Node.js dependencies not installed.

**Solution:**
```bash
# Install all npm dependencies
npm install

# This will install:
# - dotenv (environment variable management)
# - pg (PostgreSQL client for Node.js)
```

#### 2. **Docker Init Script Error: "cannot execute: required file not found"**

**Problem:** `00_setup_auth.sh` has Windows (CRLF) line endings instead of Unix (LF) format.

**Solution (PowerShell):**
```powershell
# Convert line endings from CRLF to LF
$content = Get-Content 'database\init\00_setup_auth.sh' -Raw
$content = $content -replace "`r`n", "`n"
[System.IO.File]::WriteAllText("$PWD\database\init\00_setup_auth.sh", $content, [System.Text.UTF8Encoding]::new($false))

# Restart Docker containers
docker compose down -v
docker compose up -d
```

**Solution (Linux/macOS):**
```bash
# Convert line endings
dos2unix database/init/00_setup_auth.sh

# OR use sed
sed -i 's/\r$//' database/init/00_setup_auth.sh

# Restart Docker containers
docker compose down -v
docker compose up -d
```

#### 3. **"schema 'app' does not exist" when running AI installation**

**Problem:** Database schema not initialized before running AI enhancement.

**Solution - Full Setup Sequence:**
```bash
# Step 1: Reset database (clean slate)
docker compose down -v
docker compose up -d
Start-Sleep -Seconds 15  # Wait for PostgreSQL to be ready

# Step 2: Create core schema
npm run schema:full
# This runs:
#   - schema:create (creates 16 tables, 8 enums, 32 indexes)
#   - monitoring:enable (attaches 6 audit triggers)

# Step 3: Load seed data
npm run seeds:run
# This inserts:
#   - 200 patients
#   - 20 doctors
#   - 5 admins
#   - 150 prescriptions
#   - 2000 medication logs

# Step 4: Install AI enhancement
npm run ai:install
# This creates:
#   - app.embedding table (pgvector)
#   - app.ai_audit_log table
#   - patient.health_risk_score column

# Step 5: Install Data Science analytics
npm run analytics:install
# This creates:
#   - 6 analytics views
#   - 1 materialized view (dashboard KPIs)

# Step 6: Generate synthetic AI embeddings
npm run ai:generate

# Step 7: Verify everything works
npm run analytics:pipeline
npm run ai:suggest 1 "chest pain"
```

#### 4. **Database containers unhealthy or failing to start**

**Problem:** PostgreSQL initialization failed or containers in bad state.

**Solution:**
```bash
# Complete reset with volume removal
docker compose down -v  # Remove volumes to force clean init
docker compose up -d
Start-Sleep -Seconds 15

# Check container status
docker compose ps

# Check PostgreSQL logs if issues persist
docker compose logs postgres --tail 50

# Common log errors:
# - "cannot execute: required file not found" → Fix line endings (see #2)
# - "database already exists" → Normal on restart, ignore
# - "permission denied" → Check Docker Desktop has file access
```

#### 5. **pgAdmin shows "Unable to connect to server"**

**Problem:** pgAdmin starts before PostgreSQL is ready.

**Solution:**
```bash
# Wait for PostgreSQL health check to pass
docker compose ps

# If postgres shows "healthy", restart pgAdmin
docker compose restart pgadmin

# Access pgAdmin at http://localhost:5050
# Email: admin@pakartech.com
# Password: admin123
```

### Complete Fresh Install Checklist

Use this checklist if you encounter persistent issues:

```bash
# ✅ Step 1: Clean everything
docker compose down -v
rm -rf node_modules  # Optional: if npm issues
npm cache clean --force  # Optional: if npm issues

# ✅ Step 2: Install dependencies
npm install

# ✅ Step 3: Fix line endings (Windows only)
$content = Get-Content 'database\init\00_setup_auth.sh' -Raw
$content = $content -replace "`r`n", "`n"
[System.IO.File]::WriteAllText("$PWD\database\init\00_setup_auth.sh", $content, [System.Text.UTF8Encoding]::new($false))

# ✅ Step 4: Start Docker containers
docker compose up -d
Start-Sleep -Seconds 15

# ✅ Step 5: Verify containers are healthy
docker compose ps
# Expected: jon-database-postgres (healthy), jon-database-pgadmin (healthy)

# ✅ Step 6: Initialize database schema
npm run schema:full
# Expected output: "✅ All 16 tables created successfully"

# ✅ Step 7: Load seed data
npm run seeds:run
# Expected output: "200 patients", "20 doctors", "150 prescriptions"

# ✅ Step 8: Install enhancements
npm run ai:install
npm run analytics:install

# ✅ Step 9: Generate test data
npm run ai:generate

# ✅ Step 10: Test everything works
npm run analytics:pipeline
npm run ai:suggest 1 "chest pain"
npm run project:check
```

### Quick Debugging Commands

```bash
# Check if PostgreSQL is accepting connections
docker compose exec postgres psql -U jondb_admin -d jon_database_dev -c "SELECT version();"

# List all schemas
docker compose exec postgres psql -U jondb_admin -d jon_database_dev -c "\dn"

# List all tables in app schema
docker compose exec postgres psql -U jondb_admin -d jon_database_dev -c "\dt app.*"

# Check if AI enhancement is installed
docker compose exec postgres psql -U jondb_admin -d jon_database_dev -c "SELECT COUNT(*) FROM app.embedding;"

# Check if analytics views exist
docker compose exec postgres psql -U jondb_admin -d jon_database_dev -c "SELECT COUNT(*) FROM information_schema.views WHERE table_schema = 'app' AND table_name LIKE 'v_%';"

# View PostgreSQL logs in real-time
docker compose logs -f postgres

# Check container resource usage
docker stats jon-database-postgres
```

---