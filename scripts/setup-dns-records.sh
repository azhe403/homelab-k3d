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
    HOSTNAMES=$(yq e '.data."config.yaml" | from_yaml | .ingress[] | select(.hostname != null) | .hostname' "$CONFIG_FILE")
else
    # Method 2: Using grep and awk
    HOSTNAMES=$(grep -E '^[[:space:]]*-[[:space:]]*hostname:' "$CONFIG_FILE" | awk '{print $3}')
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
        cloudflared tunnel route dns e60e7e9c-19f0-404b-809f-ce1fe0f3654f "$hostname" || {
            echo "    ⚠️  Failed to create DNS record for $hostname"
        }
    fi
done

echo ""
echo "🎉 DNS setup complete!"
