# Security Guide for Homelab Repository

This guide outlines security best practices for managing secrets and sensitive data in your homelab Kubernetes repository.

## 🔒 Security Overview

### Current Security Measures

1. **Comprehensive .gitignore**: All sensitive files are excluded from version control
2. **Security Check Script**: Automated detection of potential security issues
3. **External Secret Management**: Templates and scripts for secure credential handling

## 🛡️ Security Rules

### Files That Should NEVER Be Committed

- **Kubernetes Secrets**: Any `*-secret.yaml` files with actual credentials
- **API Keys/Tokens**: Cloudflare, GitHub, or other service credentials
- **TLS Certificates**: `.pem`, `.key`, `.crt` files
- **Database Credentials**: Connection strings and passwords
- **Vault Unseal Keys**: Root tokens and unseal keys
- **Terraform State**: `.tfstate` files with infrastructure data

### Files That ARE Safe to Commit

- **Secret Templates**: Files with placeholder values (e.g., `*-template.yaml`)
- **Configuration**: Non-sensitive Kubernetes manifests
- **Documentation**: README files and guides
- **Scripts**: Automation and setup scripts

## 🔧 Security Tools

### 1. Security Check Script

Run the security checker before committing:

```bash
./scripts/security-check.sh
```

This script checks for:
- Sensitive file patterns
- Potential secrets in YAML files
- Git status issues
- .gitignore effectiveness

### 2. Credential Setup Scripts

Use these scripts for secure credential management:

```bash
# Setup Cloudflare credentials (doesn't commit secrets)
./scripts/setup-cloudflared-credentials.sh

# Setup DNS records for tunnel
./scripts/setup-dns-records.sh
```

## 📋 Security Checklist

### Before Committing Changes

- [ ] Run `./scripts/security-check.sh`
- [ ] Review `git status` for sensitive files
- [ ] Ensure no actual credentials in YAML files
- [ ] Verify .gitignore covers all sensitive patterns

### After Deploying Services

- [ ] Store unseal keys securely (password manager)
- [ ] Rotate default passwords
- [ ] Update documentation with new credentials
- [ ] Test external access through tunnel

## 🔐 Recommended Secret Management

### 1. HashiCorp Vault (Current Setup)

- **Root Token**: `hvs.[PLACEHOLDER]` (store securely)
- **Unseal Keys**: 5 keys, 3 required threshold
- **Storage**: File-based persistent storage
- **Access**: `https://hashi-vault.azhe.my.id`

### 2. Kubernetes Secrets

For production, consider:
- **External Secrets Operator**: Sync from external secret stores
- **Sealed Secrets**: Encrypt secrets before committing
- **Vault Agent Injector**: Inject secrets directly into pods

### 3. Environment-Specific Configs

Use different configurations for:
- **Development**: Local/test credentials
- **Staging**: Pre-production environment
- **Production**: Real credentials with strict access

## 🚨 Security Incidents

### If Sensitive Data is Committed

1. **Immediate Actions**:
   ```bash
   # Remove sensitive file from history
   git filter-branch --force --index-filter 'git rm --cached --ignore-unmatch sensitive-file.yaml' --prune-empty --tag-name-filter cat -- --all
   
   # Force push to remove from remote
   git push origin --force --all
   ```

2. **Rotate Compromised Credentials**:
   - Change all exposed passwords/tokens
   - Update Vault root token
   - Regenerate Cloudflare tunnel credentials
   - Notify any affected services

3. **Prevent Future Issues**:
   - Add pre-commit hooks
   - Review .gitignore rules
   - Implement security training

## 🔄 Regular Security Tasks

### Monthly

- [ ] Review and rotate API keys
- [ ] Audit service credentials
- [ ] Update security documentation
- [ ] Run security check script

### Quarterly

- [ ] Security audit of repository
- [ ] Review access permissions
- [ ] Update security tools
- [ ] Test incident response procedures

## 📞 Security Contacts

For security issues or questions:
- Repository maintainers
- Security team (if applicable)
- Cloudflare support for tunnel issues

## 📚 Additional Resources

- [Cloudflare Tunnel Security](https://developers.cloudflare.com/cloudflare-one/connections/connect-apps/install-and-run/tunnel-security/)
- [HashiCorp Vault Best Practices](https://learn.hashicorp.com/tutorials/vault/identity-entities-groups)
- [Kubernetes Security Best Practices](https://kubernetes.io/docs/concepts/security/)
