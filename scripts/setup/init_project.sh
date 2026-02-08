#!/bin/bash

# Project Initialization Script
# Usage: ./scripts/setup/init_project.sh

set -e

echo "============================================="
echo "Initializing Data Security Platform Project"
echo "============================================="

# Check prerequisites
command -v python3 >/dev/null 2>&1 || { echo "Python3 is required but not installed. Aborting." >&2; exit 1; }
command -v docker >/dev/null 2>&1 || { echo "Docker is required but not installed. Aborting." >&2; exit 1; }
command -v kubectl >/dev/null 2>&1 || { echo "kubectl is required but not installed. Aborting." >&2; exit 1; }

# Create virtual environment
echo "Creating Python virtual environment..."
python3 -m venv .venv
source .venv/bin/activate

# Install Python dependencies
echo "Installing Python dependencies..."
pip install --upgrade pip
pip install -r requirements.txt
pip install -r requirements-dev.txt

# Install pre-commit hooks
echo "Installing pre-commit hooks..."
pre-commit install

# Create environment files
echo "Creating environment configuration..."
cp .env.example .env 2>/dev/null || echo ".env.example not found, creating minimal .env"
cat > .env << 'ENVEOF'
# Data Security Platform Environment Configuration

# Core Services
DSPM_API_HOST=localhost:8080
DLP_API_HOST=localhost:8081
DATABASE_URL=postgresql://postgres:password@localhost:5432/security_platform

# SynthFuse Configuration
SYNTHFUSE_API_HOST=localhost:8082
GPU_ENABLED=false
PRIVACY_BUDGET_EPSILON=1.0
PRIVACY_BUDGET_DELTA=1e-5

# AI/ML Services
OPENAI_API_KEY=
HUGGINGFACE_TOKEN=
AWS_ACCESS_KEY_ID=
AWS_SECRET_ACCESS_KEY=
AZURE_OPENAI_ENDPOINT=
AZURE_OPENAI_KEY=

# Monitoring
GRAFANA_URL=http://localhost:3000
PROMETHEUS_URL=http://localhost:9090
ENVEOF

# Initialize git
echo "Initializing git repository..."
git init
git add .
git commit -m "Initial commit: Data Security Platform with SynthFuse"

echo ""
echo "============================================="
echo "Project initialization complete!"
echo "============================================="
echo ""
echo "Next steps:"
echo "1. Review and update .env file with your configuration"
echo "2. Source the virtual environment: source .venv/bin/activate"
echo "3. Run tests: make test"
echo "4. Deploy services: make deploy-all"
echo ""
echo "For more information, see docs/DEPLOYMENT.md"
