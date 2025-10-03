# Jon's Database Management Project

**Database Design Project (COS 20031) - Year 2, Semester 1**

Modern PostgreSQL 18 database setup for university coursework.

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