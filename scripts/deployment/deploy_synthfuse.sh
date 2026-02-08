#!/bin/bash

# SynthFuse Deployment Script
# Usage: ./scripts/deployment/deploy_synthfuse.sh [environment]

set -e

ENVIRONMENT=${1:-development}

echo "============================================="
echo "Deploying SynthFuse (Environment: $ENVIRONMENT)"
echo "============================================="

# Load environment variables
if [ -f .env ]; then
    export $(cat .env | grep -v '^#' | xargs)
fi

# Function to check prerequisites
check_prerequisites() {
    echo "Checking prerequisites..."
    
    command -v docker >/dev/null 2>&1 || { echo "Docker is required but not installed. Aborting." >&2; exit 1; }
    command -v docker-compose >/dev/null 2>&1 || { echo "docker-compose is required but not installed. Aborting." >&2; exit 1; }
    
    if [ "$ENVIRONMENT" = "production" ]; then
        command -v kubectl >/dev/null 2>&1 || { echo "kubectl is required for production deployment. Aborting." >&2; exit 1; }
        command -v helm >/dev/null 2>&1 || { echo "helm is required for production deployment. Aborting." >&2; exit 1; }
    fi
    
    echo "✓ All prerequisites satisfied"
}

# Function to deploy with docker-compose
deploy_development() {
    echo "Deploying SynthFuse for development..."
    
    # Build and start SynthFuse services
    docker-compose -f docker-compose.synthfuse.yml build
    docker-compose -f docker-compose.synthfuse.yml up -d
    
    # Wait for services to be healthy
    echo "Waiting for services to start..."
    sleep 30
    
    # Run health checks
    echo "Running health checks..."
    curl -f http://localhost:8082/health || echo "Health check failed"
    
    echo "✓ SynthFuse development deployment complete"
}

# Function to deploy with Kubernetes
deploy_production() {
    echo "Deploying SynthFuse for production..."
    
    # Apply Kubernetes manifests
    kubectl apply -k infrastructure/kubernetes/synthfuse/
    
    # Deploy with Helm
    helm upgrade --install synthfuse infrastructure/helm/synthfuse-chart/ \
        --namespace synthfuse \
        --create-namespace \
        --values configs/synthfuse/production-values.yaml
    
    echo "✓ SynthFuse production deployment complete"
}

# Function to deploy with Terraform
deploy_infrastructure() {
    echo "Deploying SynthFuse infrastructure..."
    
    cd infrastructure/terraform/synthfuse
    terraform init
    terraform apply -auto-approve -var-file="environments/${ENVIRONMENT}.tfvars"
    cd ../../..
    
    echo "✓ SynthFuse infrastructure deployed"
}

# Main deployment logic
main() {
    check_prerequisites
    
    case $ENVIRONMENT in
        development)
            deploy_development
            ;;
        staging|production)
            deploy_infrastructure
            deploy_production
            ;;
        *)
            echo "Unknown environment: $ENVIRONMENT"
            echo "Usage: $0 [development|staging|production]"
            exit 1
            ;;
    esac
    
    echo ""
    echo "============================================="
    echo "SynthFuse Deployment Summary"
    echo "============================================="
    echo "Environment: $ENVIRONMENT"
    echo "Status: ✓ Deployed"
    echo ""
    echo "Access URLs:"
    echo "- SynthFuse API: http://localhost:8082"
    echo "- Grafana: http://localhost:3000"
    echo "- Documentation: http://localhost:8082/docs"
    echo ""
    echo "Next steps:"
    echo "1. Generate synthetic data: make synthfuse-generate"
    echo "2. Monitor quality: make synthfuse-monitor"
    echo "3. Run validation: make synthfuse-validate"
}

main "$@"
