#!/bin/bash

# k3d Cluster Setup with Persistent Storage for PostgreSQL
# This script creates a k3d cluster with host path volumes mounted for data persistence

set -e

# Configuration
CLUSTER_NAME="homelab"
HOST_DATA_DIR="/data/homelab-data"
POSTGRES_DIR="${HOST_DATA_DIR}/postgres-keycloak"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}🚀 Setting up k3d cluster with persistent storage...${NC}"

# Create host directories for persistent storage
echo -e "${YELLOW}📁 Creating host directories for persistent storage...${NC}"
mkdir -p "${POSTGRES_DIR}"
mkdir -p "${HOST_DATA_DIR}/vault"
mkdir -p "${HOST_DATA_DIR}/gitlab"

echo -e "${GREEN}✅ Created directories:${NC}"
echo "  - ${POSTGRES_DIR}"
echo "  - ${HOST_DATA_DIR}/vault"
echo "  - ${HOST_DATA_DIR}/gitlab"

# Check if cluster already exists
if k3d cluster list | grep -q "${CLUSTER_NAME}"; then
    echo -e "${YELLOW}⚠️  Cluster '${CLUSTER_NAME}' already exists. Deleting it first...${NC}"
    k3d cluster delete "${CLUSTER_NAME}"
fi

# Create k3d cluster with volume mounts
echo -e "${YELLOW}🏗️  Creating k3d cluster with volume mounts...${NC}"
k3d cluster create "${CLUSTER_NAME}" \
    --agents 2 \
    --servers 1 \
    --port 8080:80@loadbalancer \
    --port 8443:443@loadbalancer \
    --volume "${POSTGRES_DIR}:/homelab-data/postgres-keycloak@agent:0" \
    --volume "${HOST_DATA_DIR}/vault:/homelab-data/vault@agent:1" \
    --volume "${HOST_DATA_DIR}/gitlab:/homelab-data/gitlab@agent:0" \
    --k3s-arg "--service-node-port-range=1-65535@server:0"

echo -e "${GREEN}✅ Cluster created successfully!${NC}"

# Wait for cluster to be ready
echo -e "${YELLOW}⏳ Waiting for cluster to be ready...${NC}"
kubectl wait --for=condition=Ready nodes --all --timeout=300s

# Verify cluster is working
echo -e "${YELLOW}🔍 Verifying cluster status...${NC}"
kubectl get nodes
kubectl get storageclass

echo -e "${GREEN}🎉 k3d cluster with persistent storage is ready!${NC}"
echo ""
echo -e "${YELLOW}📋 Next steps:${NC}"
echo "1. Deploy applications: kubectl apply -k clusters/k3d/"
echo "2. Check PostgreSQL data persistence after cluster restart"
echo ""
echo -e "${YELLOW}💾 Persistent data locations:${NC}"
echo "PostgreSQL: ${POSTGRES_DIR}"
echo "Vault: ${HOST_DATA_DIR}/vault"
echo "GitLab: ${HOST_DATA_DIR}/gitlab"
