#!/bin/bash

# Test PostgreSQL Data Persistence
# This script tests that PostgreSQL data persists across cluster recreations

set -e

# Configuration
CLUSTER_NAME="homelab"
HOST_DATA_DIR="/data/homelab-data/postgres-keycloak"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}🧪 Testing PostgreSQL data persistence...${NC}"

# Function to wait for PostgreSQL to be ready
wait_for_postgres() {
    echo -e "${YELLOW}⏳ Waiting for PostgreSQL to be ready...${NC}"
    kubectl wait --for=condition=Ready pod -l app=keycloak-postgres -n keycloak --timeout=300s
    
    # Test database connectivity
    local max_attempts=30
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        if kubectl exec -n keycloak deployment/keycloak-postgres -- psql -U keycloak -d keycloak -c "SELECT 1;" >/dev/null 2>&1; then
            echo -e "${GREEN}✅ PostgreSQL is ready${NC}"
            return 0
        fi
        
        echo -e "${YELLOW}⏳ Attempt $attempt/$max_attempts: PostgreSQL not ready yet...${NC}"
        sleep 10
        ((attempt++))
    done
    
    echo -e "${RED}❌ PostgreSQL failed to become ready${NC}"
    return 1
}

# Function to create test data
create_test_data() {
    echo -e "${YELLOW}📝 Creating test data in PostgreSQL...${NC}"
    
    # Create a test table and insert data
    kubectl exec -n keycloak deployment/keycloak-postgres -- psql -U keycloak -d keycloak << 'EOF'
CREATE TABLE IF NOT EXISTS persistence_test (
    id SERIAL PRIMARY KEY,
    message VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO persistence_test (message) VALUES ('Test data before cluster recreation');
EOF
    
    echo -e "${GREEN}✅ Test data created${NC}"
}

# Function to verify test data
verify_test_data() {
    echo -e "${YELLOW}🔍 Verifying test data exists...${NC}"
    
    local count=$(kubectl exec -n keycloak deployment/keycloak-postgres -- psql -U keycloak -d keycloak -t -c "SELECT COUNT(*) FROM persistence_test;" | tr -d ' ')
    
    if [ "$count" -gt 0 ]; then
        echo -e "${GREEN}✅ Found $count records in persistence_test table${NC}"
        kubectl exec -n keycloak deployment/keycloak-postgres -- psql -U keycloak -d keycloak -c "SELECT * FROM persistence_test;"
        return 0
    else
        echo -e "${RED}❌ No test data found${NC}"
        return 1
    fi
}

# Check if cluster exists
if ! k3d cluster list | grep -q "${CLUSTER_NAME}"; then
    echo -e "${RED}❌ Cluster '${CLUSTER_NAME}' does not exist${NC}"
    echo "Please run: ./scripts/setup-cluster-with-persistent-storage.sh"
    exit 1
fi

# Check if PostgreSQL is deployed
if ! kubectl get deployment -n keycloak keycloak-postgres >/dev/null 2>&1; then
    echo -e "${YELLOW}⚠️  PostgreSQL not deployed. Deploying applications first...${NC}"
    kubectl apply -k clusters/k3d/
fi

# Wait for PostgreSQL to be ready
wait_for_postgres

# Create test data
create_test_data

# Show host directory contents
echo -e "${YELLOW}📁 Host directory contents:${NC}"
if [ -d "${HOST_DATA_DIR}" ]; then
    ls -la "${HOST_DATA_DIR}"
    echo -e "${GREEN}✅ Data directory exists on host${NC}"
else
    echo -e "${RED}❌ Data directory does not exist on host${NC}"
fi

echo -e "${GREEN}🎉 Test data created successfully!${NC}"
echo ""
echo -e "${YELLOW}📋 To test persistence:${NC}"
echo "1. Recreate the cluster: ./scripts/setup-cluster-with-persistent-storage.sh"
echo "2. Redeploy applications: kubectl apply -k clusters/k3d/"
echo "3. Run verification: kubectl exec -n keycloak deployment/keycloak-postgres -- psql -U keycloak -d keycloak -c 'SELECT * FROM persistence_test;'"
