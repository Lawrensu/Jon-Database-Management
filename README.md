# Jon's Database Management Project

**Database Design Project (COS 20031) - Year 2, Semester 1**

Modern PostgreSQL 18 database setup for PAKAR Tech Healthcare.

## 📋 Prerequisites & Installation

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
   npm run db:setup
   ```

2. **Start working:**
   ```bash
   npm run db:start
   ```

3. **Access pgAdmin:**
   Open http://localhost:8080

## Why

- **PostgreSQL 18**: Latest database with advanced features
- **pgAdmin**: Web-based database management
- **Automatic setup**: One command gets everything running
- **Team ready**: Easy for classmates to set up

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

## To-Do

- Create tables in the `app` schema
- Use pgAdmin for visual design
- Document database structure

<!-- ## Port Configuration

Using port 5433 to avoid conflicts with local PostgreSQL installations on port 5432. -->