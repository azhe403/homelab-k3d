#!/bin/bash

# Security Check Script for Homelab Repository
# This script checks for potentially sensitive files that might be accidentally committed

set -e

echo "🔒 Running security check on repository..."
echo ""

# Colors for output
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

# Track if any issues found
ISSUES_FOUND=false

# Function to check for sensitive patterns
check_sensitive_files() {
    echo "🔍 Checking for sensitive files..."
    
    # Check for common sensitive file patterns
    local sensitive_patterns=(
        "*-secret*.yaml"
        "*-credentials*.yaml"
        "*.pem"
        "*.key"
        "*.crt"
        "*.tfvars"
        ".env*"
        "api-keys*"
        "tokens*"
        "vault-unseal-keys*"
        "cloudflared-credentials*"
    )
    
    for pattern in "${sensitive_patterns[@]}"; do
        if find . -name "$pattern" -not -path "./.git/*" -not -path "./scripts/*" | grep -q .; then
            echo -e "${RED}❌ Found files matching pattern: $pattern${NC}"
            find . -name "$pattern" -not -path "./.git/*" -not -path "./scripts/*" | sed 's/^/   /'
            ISSUES_FOUND=true
        fi
    done
    
    # Check for potential secrets in YAML files
    echo ""
    echo "🔍 Checking for potential secrets in YAML files..."
    
    local secret_patterns=(
        "password:"
        "secret:"
        "token:"
        "key:"
        "credentials:"
        "AccountTag:"
        "TunnelSecret:"
    )
    
    for yaml_file in $(find . -name "*.yaml" -o -name "*.yml" | grep -v ".git" | grep -v "scripts"); do
        for pattern in "${secret_patterns[@]}"; do
            if grep -q "$pattern" "$yaml_file" 2>/dev/null; then
                echo -e "${YELLOW}⚠️  Potential secret found in: $yaml_file${NC}"
                grep -n "$pattern" "$yaml_file" | head -5 | sed 's/^/   /'
            fi
        done
    done
}

# Function to check git status for uncommitted sensitive files
check_git_status() {
    echo ""
    echo "🔍 Checking git status for sensitive files..."
    
    if git status --porcelain 2>/dev/null | grep -q .; then
        echo -e "${YELLOW}⚠️  Uncommitted changes found:${NC}"
        git status --porcelain | head -10
    else
        echo -e "${GREEN}✅ No uncommitted changes${NC}"
    fi
}

# Function to check .gitignore effectiveness
check_gitignore() {
    echo ""
    echo "🔍 Checking .gitignore effectiveness..."
    
    if [ ! -f ".gitignore" ]; then
        echo -e "${RED}❌ No .gitignore file found${NC}"
        ISSUES_FOUND=true
        return
    fi
    
    echo -e "${GREEN}✅ .gitignore file exists${NC}"
    
    # Check if critical patterns are in .gitignore
    local critical_patterns=(
        "*-secret*"
        "*-credentials*"
        "*.key"
        ".env"
        "*.tfstate"
    )
    
    for pattern in "${critical_patterns[@]}"; do
        if grep -q "$pattern" .gitignore; then
            echo -e "${GREEN}✅ Pattern '$pattern' found in .gitignore${NC}"
        else
            echo -e "${RED}❌ Pattern '$pattern' missing from .gitignore${NC}"
            ISSUES_FOUND=true
        fi
    done
}

# Function to provide security recommendations
security_recommendations() {
    echo ""
    echo "📋 Security Recommendations:"
    echo ""
    echo "1. 🔄 Use external secrets management (Vault, AWS Secrets Manager, etc.)"
    echo "2. 🔐 Enable Git pre-commit hooks to prevent sensitive file commits"
    echo "3. 🛡️  Use Sealed Secrets or External Secrets Operator for Kubernetes"
    echo "4. 🔑 Rotate API keys and tokens regularly"
    echo "5. 📝 Document secret management procedures"
    echo "6. 🔍 Regular security audits of repository"
    echo ""
}

# Main execution
main() {
    check_sensitive_files
    check_git_status
    check_gitignore
    
    if [ "$ISSUES_FOUND" = true ]; then
        echo ""
        echo -e "${RED}🚨 SECURITY ISSUES FOUND! Please review and fix before committing.${NC}"
        security_recommendations
        exit 1
    else
        echo ""
        echo -e "${GREEN}✅ Security check passed! No obvious issues detected.${NC}"
        security_recommendations
    fi
}

# Run main function
main "$@"
