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

This repository follows GitOps best practices with a standardized directory structure:

```
├── base/                           # Base configurations for core components
│   ├── argocd/                     # ArgoCD GitOps operator
│   ├── cloudflared/                # Cloudflare tunnel configuration
│   ├── grafana/                    # Grafana monitoring
│   └── networking/                 # Network policies and quotas
├── apps/                           # Application manifests
│   ├── authentik/                  # Authentik identity provider
│   │   └── base/                   # Base authentik configuration
│   ├── gitlab/                     # GitLab CE deployment
│   │   └── base/                   # Base gitlab configuration
│   └── keycloak/                   # Keycloak identity provider
│       └── base/                   # Base keycloak configuration
├── clusters/                       # Cluster-specific configurations
│   └── k3d/                        # k3d cluster configuration
│       ├── base/                   # Base cluster configuration
│       └── kustomization.yaml      # Cluster entrypoint
├── scripts/                        # Utility and setup scripts
├── docs/                           # Documentation and themes
└── environments/                   # Environment-specific overlays
    ├── dev/                        # Development environment
    └── prod/                       # Production environment
```

## Deployment

### Using Kustomize (Recommended)

This repository uses Kustomize for manifest management. Deploy the entire stack with:

```bash
# Deploy to k3d cluster
kubectl apply -k clusters/k3d/

# Or deploy specific components
kubectl apply -k base/argocd/
kubectl apply -k base/cloudflared/
kubectl apply -k apps/authentik/base/
```

### Manual Deployment

If you prefer to apply manifests individually:

#### 1. Infrastructure Setup
```bash
# Apply network policies and quotas
kubectl apply -f base/networking/
```

#### 2. ArgoCD Installation
```bash
# Install ArgoCD operator
kubectl apply -f base/argocd/namespace.yaml
kubectl apply -f base/argocd/install.yaml
kubectl apply -f base/argocd/crd.yaml

# Deploy ArgoCD components
kubectl apply -f base/argocd/bootstrap.yaml
kubectl apply -f base/argocd/argocd-dex-server-deployment.yaml
kubectl apply -f base/argocd/argocd-repo-server.yaml

# Configure external access
kubectl apply -f base/argocd/argocd-ingress.yaml
```

#### 3. Cloudflare Tunnel Setup
```bash
# Deploy Cloudflared for external access
kubectl apply -f base/cloudflared/cloudflared-config.yaml
kubectl apply -f base/cloudflared/cloudflared-deployment.yaml
```

#### 4. Application Deployments

##### Keycloak Identity Provider
```bash
kubectl apply -f apps/keycloak/base/01-namespace.yaml
kubectl apply -f apps/keycloak/base/02-postgres-deployment.yaml
kubectl apply -f apps/keycloak/base/03-postgres-service.yaml
kubectl apply -f apps/keycloak/base/04-postgres-pvc.yaml
kubectl apply -f apps/keycloak/base/05-keycloak-deployment.yaml
kubectl apply -f apps/keycloak/base/06-keycloak-service.yaml
kubectl apply -f apps/keycloak/base/07-keycloak-ingress.yaml
```

##### Authentik Identity Provider
```bash
kubectl apply -f apps/authentik/base/01-namespace.yaml
kubectl apply -f apps/authentik/base/02-redis-deployment.yaml
kubectl apply -f apps/authentik/base/03-redis-service.yaml
kubectl apply -f apps/authentik/base/04-postgres-deployment.yaml
kubectl apply -f apps/authentik/base/05-postgres-service.yaml
kubectl apply -f apps/authentik/base/06-postgres-pvc.yaml
kubectl apply -f apps/authentik/base/07-authentik-deployment.yaml
kubectl apply -f apps/authentik/base/08-authentik-service.yaml
kubectl apply -f apps/authentik/base/09-authentik-ingress.yaml
kubectl apply -f apps/authentik/base/10-authentik-configmap.yaml
```

##### GitLab CE
```bash
kubectl apply -f apps/gitlab/base/01-pvc.yaml
kubectl apply -f apps/gitlab/base/02-deployment.yaml
kubectl apply -f apps/gitlab/base/03-service.yaml
```

##### Grafana Monitoring
```bash
kubectl apply -f base/grafana/ingress.yaml
```

## Cloudflare Tunnel DNS Configuration

The following DNS entries are configured in the Cloudflare tunnel (`base/cloudflared/cloudflared-config.yaml`):

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
