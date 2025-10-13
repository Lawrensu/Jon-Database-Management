# DevOps & Documentation Guide

**Team Member:** Faisal  
**Role:** DevOps & Documentation Lead  
**Responsibility:** Database operations, backups, monitoring, and team documentation

---

## 🎯 Mission/Objectives

You are the **operations backbone** of the team. Your responsibilities:

1. **Database Operations** - Ensure database is always available and running smoothly
2. **Backup & Recovery** - Protect team's work with regular backups
3. **Monitoring & Health Checks** - Track database performance and issues
4. **Documentation** - Maintain clear guides for the entire team
5. **CI/CD Setup** - Automate testing and deployment processes (VERY FUN YES)
6. **Team Support** - Help teammates with technical issues

---

## 📋 What to Do

### Phase 1: Understanding the Infrastructure 

**First, understand what you're managing:**

```bash
# Check current setup
npm run db:status

# View all running containers
docker compose ps

# Check resource usage
docker stats

# View database logs
npm run db:logs

# Connect to database
npm run db:connect
```

**Your infrastructure includes:**
- **PostgreSQL 18** - Main database server (port 5432)
- **pgAdmin** - Web interface (port 8080)
- **Docker Volumes** - Persistent data storage
- **Docker Network** - Internal communication

### Phase 2: Database Operations 

#### Daily Operations Checklist

**File to create:** `docs/operations/daily-checklist.md`

```md
# Daily Operations Checklist (Recommended I just made it up)

## Morning Check (9:00 AM)
- [ ] Verify database is running: `npm run db:status`
- [ ] Check disk space: `docker system df`
- [ ] Review logs for errors: `npm run db:logs | grep ERROR`
- [ ] Verify pgAdmin accessible: http://localhost:8080
- [ ] Check last backup date

## Before Team Standup
- [ ] Pull latest changes: `git pull origin main`
- [ ] Run schema updates: `npm run schema:create`
- [ ] Load new seed data: `npm run seeds:run`
- [ ] Test queries work: `npm run queries:test`

## End of Day (5:00 PM)
- [ ] Create backup: `npm run db:backup`
- [ ] Commit documentation updates
- [ ] Update team status board
- [ ] Check for pending issues
```

#### Backup Procedures

**File to create:** `docs/operations/backup-procedures.md`

```md
# Backup & Recovery Procedures

## Manual Backup

### Quick Backup (Daily)
```bash
# Create timestamped backup
npm run db:backup

# Backup saved to: database/backups/backup_YYYYMMDD_HHMMSS.sql
```

### Full Backup (Weekly)
```bash
# Stop database (recommended for consistency)
npm run db:stop

# Create backup with all data
docker compose run --rm postgres pg_dump \
  -U jondb_admin \
  -d jon_database_dev \
  --format=custom \
  --file=/backups/full_backup_$(date +%Y%m%d).backup

# Restart database
npm run db:start
```

### Schema-Only Backup
```bash
# Backup just the structure (no data)
docker compose exec postgres pg_dump \
  -U jondb_admin \
  -d jon_database_dev \
  --schema-only \
  > database/backups/schema_only_$(date +%Y%m%d).sql
```

## Restore Procedures

### Restore from SQL Backup
```bash
# 1. Stop current database
npm run db:stop

# 2. Reset database
npm run db:reset

# 3. Start fresh database
npm run db:start

# 4. Wait for database to be ready
sleep 30

# 5. Restore backup
cat database/backups/backup_YYYYMMDD_HHMMSS.sql | npm run sql:run
```

### Restore from Custom Format Backup
```bash
# Stop database
npm run db:stop

# Reset volumes
npm run db:reset

# Start database
npm run db:start

# Restore custom format backup
docker compose exec postgres pg_restore \
  -U jondb_admin \
  -d jon_database_dev \
  -v /backups/full_backup_YYYYMMDD.backup
```

## Automated Backups (Setup Once)

### Windows Task Scheduler
```powershell
# Create backup script: scripts/backup.bat
@echo off
cd /d "D:\University\...\Jon-Database-Management"
call npm run db:backup
```

### Linux/macOS Cron Job
```bash
# Edit crontab
crontab -e

# Add daily backup at 2 AM
0 2 * * * cd /path/to/Jon-Database-Management && npm run db:backup

# Add weekly full backup on Sundays at 3 AM
0 3 * * 0 cd /path/to/Jon-Database-Management && docker compose run --rm postgres pg_dump -U jondb_admin -d jon_database_dev --format=custom --file=/backups/weekly_$(date +%Y%m%d).backup
```

## Backup Retention Policy
- **Daily backups:** Keep for 7 days
- **Weekly backups:** Keep for 4 weeks
- **Monthly backups:** Keep for 3 months

## Testing Backups
```bash
# Test backup integrity (monthly)
# 1. Create test database
docker compose exec postgres createdb -U jondb_admin test_restore

# 2. Restore backup to test database
cat database/backups/latest_backup.sql | \
  docker compose exec -T postgres psql -U jondb_admin -d test_restore

# 3. Verify data
docker compose exec postgres psql -U jondb_admin -d test_restore \
  -c "SELECT COUNT(*) FROM app.patients;"

# 4. Drop test database
docker compose exec postgres dropdb -U jondb_admin test_restore
```
```

#### Monitoring & Health Checks

**File to create:** `docs/operations/monitoring.md`

```md
# Database Monitoring Guide

## Health Check Scripts

### Quick Health Check
```bash
#!/bin/bash
# File: scripts/health-check.sh

echo "🏥 Database Health Check"
echo "========================"

# Check if containers are running
echo -n "PostgreSQL Status: "
if docker compose ps postgres | grep -q "Up"; then
    echo "✅ Running"
else
    echo "❌ Down"
fi

echo -n "pgAdmin Status: "
if docker compose ps pgadmin | grep -q "Up"; then
    echo "✅ Running"
else
    echo "❌ Down"
fi

# Check database connectivity
echo -n "Database Connection: "
if docker compose exec -T postgres pg_isready -U jondb_admin > /dev/null 2>&1; then
    echo "✅ Connected"
else
    echo "❌ Cannot connect"
fi

# Check disk space
echo ""
echo "💾 Disk Usage:"
docker system df

# Check database size
echo ""
echo "📊 Database Size:"
docker compose exec postgres psql -U jondb_admin -d jon_database_dev -c "
SELECT 
    pg_size_pretty(pg_database_size('jon_database_dev')) AS database_size,
    (SELECT COUNT(*) FROM app.patients) AS patient_count,
    (SELECT COUNT(*) FROM app.doctors) AS doctor_count,
    (SELECT COUNT(*) FROM app.appointments) AS appointment_count;
"

# Check active connections
echo ""
echo "🔌 Active Connections:"
docker compose exec postgres psql -U jondb_admin -d jon_database_dev -c "
SELECT 
    count(*) AS total_connections,
    count(*) FILTER (WHERE state = 'active') AS active_queries,
    count(*) FILTER (WHERE state = 'idle') AS idle_connections
FROM pg_stat_activity 
WHERE datname = 'jon_database_dev';
"

# Check for long-running queries
echo ""
echo "⏱️  Long-Running Queries:"
docker compose exec postgres psql -U jondb_admin -d jon_database_dev -c "
SELECT 
    pid,
    now() - query_start AS duration,
    state,
    LEFT(query, 100) AS query_preview
FROM pg_stat_activity
WHERE datname = 'jon_database_dev'
  AND state = 'active'
  AND now() - query_start > interval '1 minute'
ORDER BY duration DESC;
"

echo ""
echo "✅ Health check complete"
```

### Performance Monitoring
```sql
-- File: database/monitoring/performance_queries.sql

-- Check table sizes
SELECT 
    schemaname,
    tablename,
    pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) AS size,
    pg_total_relation_size(schemaname||'.'||tablename) AS size_bytes
FROM pg_tables
WHERE schemaname = 'app'
ORDER BY size_bytes DESC;

-- Check index usage
SELECT 
    schemaname,
    tablename,
    indexname,
    idx_scan AS times_used,
    pg_size_pretty(pg_relation_size(indexrelid)) AS index_size
FROM pg_stat_user_indexes
WHERE schemaname = 'app'
ORDER BY idx_scan ASC;

-- Check slow queries (requires pg_stat_statements extension)
SELECT 
    LEFT(query, 100) AS query_preview,
    calls,
    ROUND(total_exec_time::numeric, 2) AS total_time_ms,
    ROUND(mean_exec_time::numeric, 2) AS avg_time_ms,
    ROUND((100 * total_exec_time / SUM(total_exec_time) OVER ())::numeric, 2) AS percentage
FROM pg_stat_statements
WHERE query NOT LIKE '%pg_stat_statements%'
ORDER BY total_exec_time DESC
LIMIT 10;

-- Check table bloat
SELECT 
    schemaname,
    tablename,
    pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) AS total_size,
    n_live_tup AS live_tuples,
    n_dead_tup AS dead_tuples,
    ROUND(100 * n_dead_tup / NULLIF(n_live_tup + n_dead_tup, 0), 2) AS dead_percentage
FROM pg_stat_user_tables
WHERE schemaname = 'app'
ORDER BY n_dead_tup DESC;
```

## Alerting Rules

### Critical Alerts (Immediate Action)
- Database down for > 2 minutes
- Disk space < 10% free
- Connection pool exhausted
- Backup failed

### Warning Alerts (Check Within 1 Hour)
- Disk space < 20% free
- Slow queries > 5 seconds
- Table bloat > 30%
- Unused indexes

### Info Alerts (Check Daily)
- Database size increased > 10%
- New schema changes
- Failed login attempts
```

### Phase 3: Documentation Management 

#### Documentation Structure

**Create this folder structure:**
```
docs/
├── README.md                          # This file
├── operations/
│   ├── daily-checklist.md
│   ├── backup-procedures.md
│   ├── monitoring.md
│   ├── troubleshooting.md
│   └── disaster-recovery.md
├── design/
│   ├── er-diagram.png
│   ├── schema-overview.md
│   ├── design-decisions.md
│   └── table-descriptions.md
├── meeting-notes/
│   ├── 2024-12-01-kickoff.md
│   ├── 2024-12-08-schema-review.md
│   └── template.md
├── guides/
│   ├── getting-started.md
│   ├── git-workflow.md
│   ├── pgadmin-guide.md
│   └── sql-best-practices.md
└── modules/
    ├── patient-module.md
    ├── doctor-module.md
    ├── appointment-module.md
    └── reporting-module.md
```

#### Meeting Notes Template

**File to create:** `docs/meeting-notes/template.md`

```md
# Team Meeting - [Date]

**Date:** YYYY-MM-DD  
**Time:** HH:MM - HH:MM  
**Attendees:** [Names]  
**Facilitator:** [Name]  
**Note-taker:** Faisal

---

## Agenda
1. Review last week's progress
2. Discuss current issues
3. Plan next week's tasks
4. Q&A

---

## Progress Updates

### Lawrence & Jonathan (Database Design)
- ✅ Completed: [Tasks]
- 🔄 In Progress: [Tasks]
- ⏭️ Next: [Tasks]
- ⚠️ Blockers: [Issues]

### Cherrylyn (Data Management)
- ✅ Completed: [Tasks]
- 🔄 In Progress: [Tasks]
- ⏭️ Next: [Tasks]
- ⚠️ Blockers: [Issues]

### Jason (Query Specialist)
- ✅ Completed: [Tasks]
- 🔄 In Progress: [Tasks]
- ⏭️ Next: [Tasks]
- ⚠️ Blockers: [Issues]

### Faisal (DevOps)
- ✅ Completed: [Tasks]
- 🔄 In Progress: [Tasks]
- ⏭️ Next: [Tasks]
- ⚠️ Blockers: [Issues]

---

## Discussions

### Topic 1: [Title]
**Issue:** [Description]  
**Decision:** [What we decided]  
**Action Items:**
- [ ] [Person] - [Task] - [Deadline]

### Topic 2: [Title]
**Issue:** [Description]  
**Decision:** [What we decided]  
**Action Items:**
- [ ] [Person] - [Task] - [Deadline]

---

## Action Items Summary
- [ ] [Person] - [Task] - [Deadline]
- [ ] [Person] - [Task] - [Deadline]
- [ ] [Person] - [Task] - [Deadline]

---

## Next Meeting
**Date:** YYYY-MM-DD  
**Time:** HH:MM  
**Topics:**
- Review action items
- [Other topics]
```

#### Team Onboarding Guide

**File to create:** `docs/guides/getting-started.md`

```md
# Getting Started Guide

Welcome to the PAKAR Tech Healthcare Database Project!

## For New Team Members

### Step 1: Install Prerequisites (30 minutes)

1. **Install Git**
   - Download: https://git-scm.com/downloads
   - Verify: `git --version`

2. **Install Docker Desktop**
   - Download: https://www.docker.com/products/docker-desktop/
   - Verify: `docker --version` and `docker compose version`

3. **Install Node.js**
   - Download: https://nodejs.org/ (LTS version)
   - Verify: `node --version` and `npm --version`

4. **Install a Code Editor**
   - Recommended: Visual Studio Code (https://code.visualstudio.com/)
   - Install PostgreSQL extension for VS Code

### Step 2: Clone the Repository (5 minutes)

```bash
# Clone the repository
git clone [repository-url]
cd Jon-Database-Management

# Create your own branch
git checkout -b feature/your-name-initials
```

### Step 3: Setup Database (10 minutes)

```bash
# Run automated setup
npm run db:setup

# Verify everything works
npm run db:status
npm run db:connect
\dt app.*
\q
```

### Step 4: Load Sample Data (5 minutes)

```bash
# Create schema
npm run schema:create

# Load seed data
npm run seeds:run

# Test queries
npm run queries:test
```

### Step 5: Access pgAdmin (5 minutes)

1. Open http://localhost:8080
2. Login with:
   - Email: `jonAdmin@database.com`
   - Password: `JonathanPGAdmin26!`
3. Add server:
   - Name: `Jon Database`
   - Host: `postgres` (NOT localhost!)
   - Port: `5432`
   - Username: `jondb_admin`
   - Password: `JonathanBangerDatabase26!`

### Step 6: Join the Team! 🎉

You're all set! Check your role-specific README:
- Database Design: `database/project/README.md`
- Data Management: `database/seeds/README.md`
- Query Specialist: `database/queries/README.md`
- DevOps: `docs/README.md` (you're here!)

## Quick Reference Card

Print this and keep it handy!

```
QUICK COMMANDS
==============
Start DB:        npm run db:start
Stop DB:         npm run db:stop
Connect:         npm run db:connect
View Logs:       npm run db:logs
Status:          npm run db:status
Backup:          npm run db:backup
Reset:           npm run db:reset

PGADMIN
=======
URL:     http://localhost:8080
Email:   jonAdmin@database.com
Pass:    JonathanPGAdmin26!

DATABASE
========
Host:    localhost:5432
DB:      jon_database_dev
User:    jondb_admin
Pass:    JonathanBangerDatabase26!

HELP
====
Stuck? Ask Faisal or check:
- docs/operations/troubleshooting.md
- Team chat
- Office hours: Mon/Wed 2-4 PM
```
```

### Phase 4: Troubleshooting & Support (Ongoing)

**File to create:** `docs/operations/troubleshooting.md`

````md
# Troubleshooting Guide

## Common Issues & Solutions

### Issue 1: "Docker is not running"

**Symptoms:**
```
Error: Cannot connect to the Docker daemon
```

**Solutions:**
1. Start Docker Desktop
2. Wait 30 seconds for Docker to fully start
3. Run `docker ps` to verify
4. Try command again

**Windows-specific:**
- Ensure WSL 2 is installed
- Enable "Use WSL 2 based engine" in Docker settings

---

### Issue 2: "Port 5432 is already in use"

**Symptoms:**
```
Error: Bind for 0.0.0.0:5432 failed: port is already allocated
```

**Solutions:**

**Option 1: Stop conflicting service (Windows)**
```powershell
# Find process using port 5432
netstat -ano | findstr :5432

# Stop PostgreSQL service
net stop postgresql-x64-15
```

**Option 2: Stop conflicting service (macOS/Linux)**
```bash
# Find process
lsof -i :5432

# Stop PostgreSQL
brew services stop postgresql
# or
sudo systemctl stop postgresql
```

**Option 3: Change port in .env**
```bash
# Edit .env file
POSTGRES_PORT=5433

# Restart containers
npm run db:restart
```

---

### Issue 3: "Permission denied" on scripts

**Symptoms:**
```
bash: ./scripts/setup-database.sh: Permission denied
```

**Solutions:**
```bash
# Make script executable
chmod +x scripts/setup-database.sh

# Run again
npm run db:setup
```

---

### Issue 4: "Database does not exist"

**Symptoms:**
```
FATAL: database "jon_database_dev" does not exist
```

**Solutions:**
```bash
# Reset and recreate database
npm run db:reset
npm run db:start

# Wait for database to be ready
sleep 30

# Recreate schema
npm run schema:create
```

---

### Issue 5: "Could not connect to server"

**Symptoms:**
```
could not connect to server: Connection refused
```

**Solutions:**
1. Check if containers are running:
   ```bash
   npm run db:status
   ```

2. Check logs for errors:
   ```bash
   npm run db:logs
   ```

3. Restart database:
   ```bash
   npm run db:restart
   ```

4. Full reset (last resort):
   ```bash
   npm run db:reset
   npm run db:setup
   ```

---

### Issue 6: "Relation does not exist"

**Symptoms:**
```
ERROR: relation "app.patients" does not exist
```

**Solutions:**
```bash
# Schema not created - create it
npm run schema:create

# Or if schema exists, check search path
npm run db:connect
SET search_path TO app, public;
\dt
```

---

### Issue 7: pgAdmin won't load

**Symptoms:**
- pgAdmin shows "Application Server could not be contacted"
- Page won't load

**Solutions:**
1. Check if pgAdmin container is running:
   ```bash
   docker compose ps pgadmin
   ```

2. Restart pgAdmin:
   ```bash
   docker compose restart pgadmin
   ```

3. Check logs:
   ```bash
   docker compose logs pgadmin
   ```

4. Clear browser cache and try again

5. Try incognito/private window

---

### Issue 8: "Disk space full"

**Symptoms:**
```
ERROR: could not write to file: No space left on device
```

**Solutions:**
1. Check Docker disk usage:
   ```bash
   docker system df
   ```

2. Clean up unused containers/images:
   ```bash
   docker system prune -a
   ```

3. Remove old backups:
   ```bash
   # Keep only last 7 days
   find database/backups/ -name "*.sql" -mtime +7 -delete
   ```

4. Increase Docker Desktop disk limit (Settings → Resources → Disk image size)

---

### Issue 9: Seed data fails to load

**Symptoms:**
```
ERROR: insert or update on table violates foreign key constraint
```

**Solutions:**
1. Load seeds in correct order:
   ```bash
   npm run seeds:patients    # First
   npm run seeds:doctors     # Second
   npm run seeds:appointments # Third
   ```

2. Check if schema exists:
   ```bash
   npm run db:connect
   \dt app.*
   ```

3. Rebuild everything:
   ```bash
   npm run schema:rebuild
   npm run seeds:run
   ```

---

### Issue 10: Git conflicts

**Symptoms:**
```
CONFLICT (content): Merge conflict in database/project/01_core_schema.sql
```

**Solutions:**
1. Check what files have conflicts:
   ```bash
   git status
   ```

2. Open conflicted files in VS Code (conflict markers shown)

3. Choose which changes to keep

4. Stage resolved files:
   ```bash
   git add database/project/01_core_schema.sql
   ```

5. Complete merge:
   ```bash
   git commit -m "Resolved merge conflicts"
   ```

**Best practice: Communicate with team before merging!**

---

## Getting Help

### Self-Service
1. Check this troubleshooting guide
2. Check `npm run db:logs` for error messages
3. Search error message online
4. Check PostgreSQL docs: https://www.postgresql.org/docs/18/

### Team Support
1. Post in team chat with:
   - What you were trying to do
   - Exact error message
   - What you've tried already
2. Tag Faisal for DevOps issues
3. Schedule pair programming session

### Emergency Contact
- **Faisal** (DevOps): [contact method]
- **Office Hours**: Mon/Wed 2-4 PM
- **Response Time**: < 4 hours during business days

---

## Diagnostic Commands

When reporting issues, run these and share output:

```bash
# System info
docker --version
docker compose version
node --version
npm --version

# Container status
docker compose ps

# Database connectivity
npm run db:connect
\conninfo
\q

# Disk space
docker system df

# Recent logs (last 50 lines)
npm run db:logs --tail=50

# Database size
docker compose exec postgres psql -U jondb_admin -d jon_database_dev -c "
SELECT pg_size_pretty(pg_database_size('jon_database_dev'));"
```