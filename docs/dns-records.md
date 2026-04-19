# DNS Records for Cloudflare Tunnel

All hostnames from the tunnel configuration have been successfully added to Cloudflare DNS.

## 🌐 Configured Hostnames

| Hostname | Status | Service |
|-----------|--------|---------|
| `argo.azhe.my.id` | ✅ Configured | ArgoCD |
| `gitlab.azhe.my.id` | ✅ Configured | GitLab CE |
| `keycloak.azhe.my.id` | ✅ Configured | Keycloak |
| `hashi-vault.azhe.my.id` | ✅ Added | HashiCorp Vault |
| `grafana.azhe.my.id` | ✅ Configured | Grafana |
| `rancher.azhe.my.id` | ✅ Added | Rancher |
| `flipt.azhe.my.id` | ✅ Configured | Flipt v2 |
| `flipt-v1.azhe.my.id` | ✅ Configured | Flipt v1 |
| `pgadmin.azhe.my.id` | ✅ Added | pgAdmin |
| `postgres-01.azhe.my.id` | ✅ Added | PostgreSQL TCP |

## 🔧 Management Commands

### List all DNS records for tunnel:
```bash
cloudflared tunnel route dns <tunnel-id>
```

### Add new hostname:
```bash
cloudflared tunnel route dns e60e7e9c-19f0-404b-809f-ce1fe0f3654f new-hostname.azhe.my.id
```

### Remove hostname:
```bash
cloudflared tunnel route dns e60e7e9c-19f0-404b-809f-ce1fe0f3654f hostname-to-remove.azhe.my.id --overwrite-dns
```

## 📊 Verification

All DNS records are now pointing to the tunnel `e60e7e9c-19f0-404b-809f-ce1fe0f3654f`. 

You can verify external access by:
```bash
# Test each hostname
curl -I https://argo.azhe.my.id
curl -I https://hashi-vault.azhe.my.id
curl -I https://gitlab.azhe.my.id
```

## 🔄 Automation

Use the provided script for future updates:
```bash
./scripts/setup-dns-records.sh
```

This script will automatically extract hostnames from the tunnel config and ensure all DNS records are properly configured.
