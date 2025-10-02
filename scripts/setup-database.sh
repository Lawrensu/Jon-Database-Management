#!/bin/bash

# Jon's Database Management Project Setup Script
# Database Design Project (COS 20031) - Year 2, Semester 1

set -e  # Exit on any error

echo "🎓 Jon's Database Management Project Setup"
echo "=========================================="
echo "📚 Database Design Project (COS 20031)"
echo "🏫 Year 2, Semester 1"
echo ""

# Check Docker installation
echo "🔍 Checking prerequisites..."
if ! command -v docker &> /dev/null; then
    echo "❌ Docker is not installed!"
    echo "📖 Please install Docker Desktop from: https://www.docker.com/get-started"
    echo "💡 This is required for running PostgreSQL 18"
    exit 1
fi

# Check Docker Compose (newer versions have 'docker compose' instead of 'docker-compose')
if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null 2>&1; then
    echo "❌ Docker Compose is not available!"
    echo "📖 Please ensure Docker Compose is installed"
    exit 1
fi

# Determine which Docker Compose command to use
if command -v docker-compose &> /dev/null; then
    COMPOSE_CMD="docker-compose"
else
    COMPOSE_CMD="docker compose"
fi

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo "❌ Docker is not running!"
    echo "🚀 Please start Docker Desktop and try again"
    exit 1
fi

echo "✅ Docker is ready (using $COMPOSE_CMD)"

# Create .env file if it doesn't exist
if [ ! -f .env ]; then
    echo "📝 Creating .env file from template..."
    cp .env.example .env
    echo "✅ Created .env file"
    echo "💡 You can edit .env to customize database settings"
else
    echo "📝 Using existing .env file"
fi

# Create directory structure (in case some are missing)
echo "📁 Ensuring directory structure exists..."
mkdir -p database/init
mkdir -p database/migrations
mkdir -p database/seeds
mkdir -p database/backups

echo "✅ Directory structure ready"

# Start the database services
echo ""
echo "🚀 Starting PostgreSQL 18 and pgAdmin..."
echo "   PostgreSQL: Latest version with advanced features"
echo "   pgAdmin: Web-based database management interface"

$COMPOSE_CMD up -d

# Wait for PostgreSQL to be healthy
echo ""
echo "⏳ Waiting for PostgreSQL to be ready..."
echo "   This may take 30-60 seconds for first-time setup..."

for i in {1..120}; do
    if $COMPOSE_CMD exec -T postgres pg_isready -U jondb_admin > /dev/null 2>&1; then
        echo ""
        echo "✅ PostgreSQL 18 is ready and healthy!"
        break
    fi
    
    if [ $i -eq 120 ]; then
        echo ""
        echo "❌ PostgreSQL failed to start within 2 minutes"
        echo "🔍 Check logs with: $COMPOSE_CMD logs postgres"
        exit 1
    fi
    
    # Show progress every 10 seconds
    if [ $((i % 10)) -eq 0 ]; then
        echo "   Still waiting... (${i}s)"
    fi
    sleep 1
done

# Check pgAdmin status
echo "⏳ Checking pgAdmin status..."
sleep 5

if $COMPOSE_CMD ps pgadmin | grep -q "Up"; then
    echo "✅ pgAdmin is running"
else
    echo "⚠️  pgAdmin may still be starting up"
fi

echo ""
echo "🎉 Jon's Database Management Project Setup Complete!"
echo "======================================================"
echo ""
echo "📊 PostgreSQL 18 Database:"
echo "   🌐 Host: localhost"
echo "   🔌 Port: 5432"
echo "   🗄️  Database: jon_database_dev"
echo "   👤 Username: jondb_admin"
echo "   🔑 Password: JonathanBangerDatabase26!"
echo ""
echo "🌐 pgAdmin Web Interface:"
echo "   🔗 URL: http://localhost:8080"
echo "   📧 Email: jonAdmin@database.com"
echo "   🔑 Password: JonathanPGAdmin26!"
echo ""
echo "🛠️  Useful Commands:"
echo "   Start services:    $COMPOSE_CMD up -d"
echo "   Stop services:     $COMPOSE_CMD stop"
echo "   View logs:         $COMPOSE_CMD logs -f postgres"
echo "   Connect to DB:     $COMPOSE_CMD exec postgres psql -U jondb_admin -d jon_database_dev"
echo "   Reset database:    $COMPOSE_CMD down -v && $COMPOSE_CMD up -d"
echo "   Check status:      $COMPOSE_CMD ps"
echo ""
echo "📚 For our Database:"
echo "   - Use pgAdmin for visual database management"
echo "   - Create your tables in the 'app' schema"
echo "   - Document our database design"
echo "   - Use migrations for version control"
echo ""