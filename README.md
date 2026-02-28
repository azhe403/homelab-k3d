# Homelab k3d Kubernetes Manifests

This repository contains Kubernetes manifests for deploying a complete homelab setup on k3d with Cloudflare tunnel for external access.

## Architecture Overview

The homelab consists of the following components:
- **ArgoCD** - GitOps continuous delivery
- **Cloudflared** - Secure tunnel for external access
- **Keycloak** - Identity and access management
- **Authentik** - Alternative identity provider
- **GitLab** - Git repository management
- **Grafana** - Monitoring and visualization
- **Networking** - Network policies and quotas

## Project Structure

```
├── apps/
│   ├── authentik/          # Authentik identity provider
│   ├── gitlab/             # GitLab CE deployment
│   └── keycloak/           # Keycloak identity provider
├── argocd/                 # ArgoCD GitOps operator
├── cloudflared/            # Cloudflare tunnel configuration
├── grafana/                # Grafana monitoring
├── infra/                  # Infrastructure components
└── networking/             # Network policies and quotas
```

## Deployment Order

### 1. Infrastructure Setup
```bash
# Apply network policies and quotas
kubectl apply -f networking/
```

### 2. ArgoCD Installation
```bash
# Install ArgoCD operator
kubectl apply -f argocd/namespace.yaml
kubectl apply -f argocd/install.yaml
kubectl apply -f argocd/crd.yaml

# Deploy ArgoCD components
kubectl apply -f argocd/bootstrap.yaml
kubectl apply -f argocd/argocd-dex-server.yaml
kubectl apply -f argocd/argocd-repo-server.yaml

# Configure external access
kubectl apply -f argocd/argocd-ingress.yaml
```

### 3. Cloudflare Tunnel Setup
```bash
# Deploy Cloudflared for external access
kubectl apply -f cloudflared/cloudflared-config.yaml
kubectl apply -f cloudflared/cloudflared-deployment.yaml
```

### 4. Application Deployments

#### Keycloak Identity Provider
```bash
kubectl apply -f apps/keycloak/01-namespace.yaml
kubectl apply -f apps/keycloak/02-postgres-deployment.yaml
kubectl apply -f apps/keycloak/03-postgres-service.yaml
kubectl apply -f apps/keycloak/04-postgres-pvc.yaml
kubectl apply -f apps/keycloak/05-keycloak-deployment.yaml
kubectl apply -f apps/keycloak/06-keycloak-service.yaml
kubectl apply -f apps/keycloak/07-keycloak-ingress.yaml
```

#### Authentik Identity Provider
```bash
kubectl apply -f apps/authentik/01-namespace.yaml
kubectl apply -f apps/authentik/02-redis-deployment.yaml
kubectl apply -f apps/authentik/03-redis-service.yaml
kubectl apply -f apps/authentik/04-postgres-deployment.yaml
kubectl apply -f apps/authentik/05-postgres-service.yaml
kubectl apply -f apps/authentik/06-postgres-pvc.yaml
kubectl apply -f apps/authentik/07-authentik-deployment.yaml
kubectl apply -f apps/authentik/08-authentik-service.yaml
kubectl apply -f apps/authentik/09-authentik-ingress.yaml
kubectl apply -f apps/authentik/10-authentik-configmap.yaml
```

#### GitLab CE
```bash
kubectl apply -f apps/gitlab/01-pvc.yaml
kubectl apply -f apps/gitlab/02-deployment.yaml
kubectl apply -f apps/gitlab/03-service.yaml
```

#### Grafana Monitoring
```bash
kubectl apply -f grafana/ingress.yaml
```

## Cloudflare Tunnel DNS Configuration

The following DNS entries are configured in the Cloudflare tunnel (`cloudflared/cloudflared-config.yaml`):

| Service | DNS Hostname | Internal Service URL |
|---------|-------------|---------------------|
| ArgoCD | `argo.azhe.my.id` | `http://argocd-server.argocd.svc.cluster.local:80` |
| Grafana | `grafana.azhe.my.id` | `http://monitoring-grafana.monitoring.svc.cluster.local:80` |
| Authentik | `authentik.azhe.my.id` | `http://authentik-service.authentik.svc.cluster.local:9000` |
| Rancher | `rancher.azhe.my.id` | `http://rancher.cattle-system.svc.cluster.local:80` |
| GitLab | `gitlab.azhe.my.id` | `http://gitlab-service.gitlab.svc.cluster.local:80` |
| Keycloak | `keycloak.azhe.my.id` | `http://keycloak-service.keycloak.svc.cluster.local:8080` |

## Access Information

### ArgoCD
- **Internal URL**: `http://argocd-server.argocd.svc.cluster.local:8080`
- **External URL**: `https://argo.azhe.my.id`
- **Default credentials**: `admin` (password retrieved from `argocd-initial-admin-secret`)

### Keycloak
- **Internal URL**: `http://keycloak-service.keycloak.svc.cluster.local:8080`
- **External URL**: `https://keycloak.azhe.my.id`
- **Admin credentials**: `admin / admin123`

### Authentik
- **Internal URL**: `http://authentik-service.authentik.svc.cluster.local:9000`
- **External URL**: `https://authentik.azhe.my.id`

### GitLab
- **Internal URL**: `http://gitlab-service.gitlab.svc.cluster.local:80`
- **External URL**: `https://gitlab.azhe.my.id`

### Grafana
- **Internal URL**: `http://monitoring-grafana.monitoring.svc.cluster.local:3000`
- **External URL**: `https://grafana.azhe.my.id`

### Rancher (if deployed)
- **Internal URL**: `http://rancher.cattle-system.svc.cluster.local:80`
- **External URL**: `https://rancher.azhe.my.id`

## Prerequisites

- k3d cluster configured
- kubectl configured to access the cluster
- Cloudflare account with tunnel configured
- Domain names pointed to Cloudflare tunnel

## Configuration Notes

- All applications use persistent storage for data persistence
- Network policies restrict inter-service communication
- Resource quotas prevent resource exhaustion
- External access is managed through Cloudflare tunnel for security
- SSL/TLS termination handled by Cloudflare

## Troubleshooting

### External Access Issues
1. Verify Cloudflare tunnel is running: `kubectl logs -n cloudflared deployment/cloudflared`
2. Check DNS records point to Cloudflare tunnel
3. Validate ingress configurations

### Application Issues
1. Check pod status: `kubectl get pods -n <namespace>`
2. Review pod logs: `kubectl logs -n <namespace> <pod-name>`
3. Verify persistent volumes are bound: `kubectl get pv`

### Network Issues
1. Check network policies: `kubectl get networkpolicies`
2. Verify service connectivity: `kubectl exec -it <pod> -- curl <service-name>`

## Status

✅ ArgoCD: Deployed and configured
✅ Cloudflared: Tunnel established
✅ Keycloak: Running with PostgreSQL backend
✅ Authentik: Configured with Redis and PostgreSQL
✅ GitLab: CE deployment ready
✅ Grafana: Ingress configured
✅ Networking: Policies and quotas applied
