#!/bin/bash

# Setup script for Cloudflare tunnel credentials
# This script creates the secret locally without committing it

set -e

NAMESPACE="cloudflared"
SECRET_NAME="cloudflared-credentials"

echo "Setting up Cloudflare tunnel credentials..."

# Check if credentials file exists
if [ ! -f "$HOME/.cloudflared/e60e7e9c-19f0-404b-809f-ce1fe0f3654f.json" ]; then
    echo "❌ Cloudflare credentials file not found!"
    echo "Please run: cloudflared tunnel token e60e7e9c-19f0-404b-809f-ce1fe0f3654f"
    exit 1
fi

# Read credentials from the file
ACCOUNT_TAG=$(jq -r '.AccountTag' "$HOME/.cloudflared/e60e7e9c-19f0-404b-809f-ce1fe0f3654f.json")
TUNNEL_SECRET=$(jq -r '.TunnelSecret' "$HOME/.cloudflared/e60e7e9c-19f0-404b-809f-ce1fe0f3654f.json")

# Create the secret
kubectl create secret generic ${SECRET_NAME} \
  --namespace=${NAMESPACE} \
  --from-literal=credentials.json="{\"AccountTag\":\"${ACCOUNT_TAG}\",\"TunnelSecret\":\"${TUNNEL_SECRET}\",\"TunnelID\":\"e60e7e9c-19f0-404b-809f-ce1fe0f3654f\"}" \
  --dry-run=client -o yaml | kubectl apply -f -

echo "✅ Cloudflare credentials secret created successfully!"
echo "⚠️  Remember to add cloudflared-credentials-secret.yaml to .gitignore"
