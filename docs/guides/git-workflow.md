# Git Workflow & Branching Strategy

**Project:** PAKAR Tech Healthcare Database  
**Version Control:** Git with GitHub  
**Strategy:** Feature Branch Workflow

---

## 🎯 Workflow Overview

Each team member works on their **own branch** and merges to `main` when ready.

---

## 📋 Initial Setup (Do This Once)

### 1. Clone the Repository

```bash
# Clone the repository
git clone https://github.com/your-username/Jon-Database-Management.git
cd Jon-Database-Management

# Check current branch (should be 'main')
git branch

# Set your name and email
git config --global user.name "Your Name"
git config --global user.email "your.email@example.com"

# Verify configuration
git config --list

--

# Create Your Personal Branch:

# Replace [name] with your name and [role] with your role
# Examples:
# lawrence/database-schema
# cherrylyn/seed-data
# jason/queries
# faisal/devops

git checkout -b [name]/[role]

# Example for Lawrence:
git checkout -b lawrence/database-schema

# Push your new branch to GitHub
git push -u origin lawrence/database-schema

# ALL EXAMPLES (BE SPECIFIC PLEASE):
# lawrence/patient-table-schema
# lawrence/doctor-relationships
# jonathan/appointment-constraints
# cherrylyn/patient-seed-data
# cherrylyn/doctor-schedules
# jason/revenue-queries
# jason/analytics-views
# faisal/backup-automation
# faisal/monitoring-setup

--

#Daily Workflow:
# 1. Make sure you're on your branch
git branch  # Shows current branch with *

# 2. Fetch latest changes from GitHub
git fetch origin

# 3. Switch to main branch
git checkout main

# 4. Pull latest changes
git pull origin main

# 5. Switch back to your branch
git checkout [your-branch-name]

# 6. Merge main into your branch (to get teammates' changes)
git merge main

# If there are conflicts, see "Handling Merge Conflicts" section below


# SAVING CHANGES:
# 1. Check what files you changed
git status

# 2. See specific changes
git diff

# 3. Add files to staging
git add database/project/01_core_schema.sql  # Add specific file
# OR
git add .  # Add all changed files

# 4. Commit with a clear message
git commit -m "Add patients table schema with UUID primary key"

# Good commit message examples:
# "Add doctors table with foreign key to departments"
# "Create seed data for 50+ patients"
# "Add query for monthly revenue analysis"
# "Update backup procedures documentation"

# 5. Push to your branch on GitHub
git push origin [your-branch-name]

# Before leaving, make sure everything is pushed
git status  # Should show "nothing to commit, working tree clean"
git push origin [your-branch-name]


# MERGING YOUR WORK TO MAIN
# Test your changes locally
npm run db:start
npm run schema:create  # If you're working on schema
npm run seeds:run      # If you're working on seeds
npm run queries:test   # If you're working on queries

# Verify everything works!

# GET LATEST CHANGES FROM MAIN
# Make sure you're on your branch
git checkout [your-branch-name]

# Get latest main
git fetch origin
git merge origin/main

# Fix any conflicts (see section below if needed)


# CREATE PULL REQUEST
# Go to the repo in Github
# Click "Pull Requests" Tab
# Click "New Pull Request"
# Set Base: main , Compare: [your-branch-name]
# Click "Create Pull Request"

#Then fill in these details:
## What Changed
Brief description of what you added/changed

## Type of Change
- [ ] Schema changes (tables, relationships)
- [ ] Seed data (sample data)
- [ ] Queries (reports, analytics)
- [ ] Documentation
- [ ] DevOps (scripts, monitoring)

## Testing Done
- [ ] Ran locally without errors
- [ ] Tested with sample data
- [ ] Verified relationships work
- [ ] Checked documentation is clear

## Screenshots (if applicable)
Add screenshots of pgAdmin, query results, etc.

## Notes for Reviewers
Any special instructions or things to watch out for

# Then click "Create Pull Request"
# Then tell in the groupchat or some that you are in need of a review


#AFTER MERGE
# Switch to main branch
git checkout main

# Pull the merged changes
git pull origin main

# Delete your old branch locally (optional, you can keep it)
git branch -d [your-branch-name]

# Create a new branch for your next task
git checkout -b [your-name]/[next-feature]


# ALL THE COMMANDS REFERENCES

# Checking status
git status              # What files changed?
git branch              # What branch am I on?
git branch -a           # Show all branches (local + remote)
git log --oneline       # Show recent commits
git diff                # Show changes not yet staged
git diff --staged       # Show changes ready to commit

# Working with branches
git checkout [branch]           # Switch to a branch
git checkout -b [new-branch]    # Create and switch to new branch
git branch -d [branch]          # Delete local branch
git push origin --delete [branch]  # Delete remote branch

# Saving updates
git add [file]          # Stage specific file
git add .               # Stage all changes
git commit -m "msg"     # Commit with message
git push                # Push to your branch
git push origin [branch]  # Push specific branch

# Getting updates
git add [file]          # Stage specific file
git add .               # Stage all changes
git commit -m "msg"     # Commit with message
git push                # Push to your branch
git push origin [branch]  # Push specific branch

# Undoing changes
git checkout -- [file]       # Discard changes in file (not staged)
git reset HEAD [file]        # Unstage file (keep changes)
git reset --hard HEAD        # Discard ALL changes (dangerous!)
git revert [commit-hash]     # Undo a specific commit

# EMERGENCY COMMANDS
# OH NO! I committed to main instead of my branch!
git reset --soft HEAD~1      # Undo last commit, keep changes
git checkout -b [your-branch]  # Create your branch
git add .
git commit -m "Your message"
git push origin [your-branch]

# OH NO! I made a mess, start fresh!
git fetch origin
git reset --hard origin/main  # WARNING: Loses all local changes!
git checkout -b [new-branch]