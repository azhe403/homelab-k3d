#!/bin/bash

# Script to setup DNS records for Cloudflare tunnel
# This script extracts hostnames from tunnel config and creates DNS records

set -e

echo "🌐 Setting up DNS records for Cloudflare tunnel..."

# Extract hostnames from cloudflared config
CONFIG_FILE="base/cloudflared/02-cloudflared-config.yaml"

if [ ! -f "$CONFIG_FILE" ]; then
    echo "❌ Config file not found: $CONFIG_FILE"
    exit 1
fi

# Extract hostnames using yq or grep
echo "📋 Extracting hostnames from tunnel config..."

# Method 1: Using yq if available
if command -v yq &> /dev/null; then
    HOSTNAMES=$(yq e '.data.config.yaml | .ingress[] | select(.hostname != null) | .hostname' "$CONFIG_FILE")
else
    # Method 2: Using grep and sed
    HOSTNAMES=$(grep -A1 "hostname:" "$CONFIG_FILE" | grep -v "hostname:" | grep -v "service:" | sed 's/^[[:space:]]*//' | grep -v "^--$" | grep -v "^$")
fi

echo ""
echo "🔍 Found hostnames:"
echo "$HOSTNAMES"
echo ""

# Check if cloudflared CLI is available
if ! command -v cloudflared &> /dev/null; then
    echo "❌ cloudflared CLI not found. Please install it first."
    echo "Visit: https://github.com/cloudflare/cloudflared/releases"
    exit 1
fi

# Create DNS records for each hostname
echo "🔧 Creating DNS records..."
for hostname in $HOSTNAMES; do
    if [ -n "$hostname" ]; then
        echo "  📍 Setting up: $hostname"
        
        # Extract domain from hostname
        DOMAIN=$(echo "$hostname" | cut -d'.' -f2-)
        
        # Check if DNS record already exists
        if cloudflared tunnel route dns list | grep -q "$hostname"; then
            echo "    ✅ DNS record already exists for $hostname"
        else
            echo "    ➕ Creating DNS record for $hostname"
            cloudflared tunnel route dns e60e7e9c-19f0-404b-809f-ce1fe0f3654f "$hostname" || {
                echo "    ⚠️  Failed to create DNS record for $hostname (may already exist)"
            }
        fi
    fi
done

echo ""
echo "🎉 DNS setup complete!"
echo ""
echo "📊 Current DNS records for tunnel:"
cloudflared tunnel route dns list e60e7e9c-19f0-404b-809f-ce1fe0f3654f
