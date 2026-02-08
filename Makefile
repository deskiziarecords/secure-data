.PHONY: help init test deploy clean

help:
	@echo "Data Security Platform with SynthFuse"
	@echo ""
	@echo "Available commands:"
	@echo "  make init        - Initialize development environment"
	@echo "  make test        - Run all tests"
	@echo "  make deploy-core - Deploy core DSPM/DLP services"
	@echo "  make deploy-synthfuse - Deploy SynthFuse services"
	@echo "  make deploy-all  - Deploy all services"
	@echo "  make clean       - Clean build artifacts"
	@echo "  make docs        - Generate documentation"
	@echo "  make lint        - Run linters"

init:
	@echo "Initializing development environment..."
	pip install -r requirements.txt
	pip install -r requirements-dev.txt
	pre-commit install

test:
	@echo "Running tests..."
	pytest tests/unit/
	pytest tests/integration/
	pytest tests/synthfuse/

deploy-core:
	@echo "Deploying core services..."
	./scripts/deployment/deploy_dspm.sh
	./scripts/deployment/deploy_dlp.sh

deploy-synthfuse:
	@echo "Deploying SynthFuse services..."
	./scripts/deployment/deploy_synthfuse.sh

deploy-all: deploy-core deploy-synthfuse

clean:
	@echo "Cleaning build artifacts..."
	find . -type d -name __pycache__ -exec rm -rf {} +
	find . -type d -name .pytest_cache -exec rm -rf {} +
	find . -type d -name .coverage -exec rm -rf {} +
	find . -type f -name "*.pyc" -delete
	find . -type f -name "*.pyo" -delete
	find . -type f -name "*.pyd" -delete

lint:
	@echo "Running linters..."
	black --check src/
	flake8 src/
	mypy src/

docs:
	@echo "Generating documentation..."
	mkdir -p docs/build
	pdoc --html src/ --output-dir docs/build/

# SynthFuse specific commands
synthfuse-generate:
	@echo "Starting synthetic data generation..."
	python -m src.synthfuse.api-gateway.synthfuse_api --generate

synthfuse-validate:
	@echo "Validating synthetic data quality..."
	python -m src.synthfuse.data-quality-observability.quality-metrics.fidelity_score

synthfuse-monitor:
	@echo "Starting SynthFuse monitoring..."
	docker-compose -f docker-compose.synthfuse.yml up monitoring
