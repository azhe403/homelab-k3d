# ArgoCD Setup Guide

## Bootstrap Process

### 1. Initial Setup
```bash
# Apply the initial cluster configuration
kubectl apply -k clusters/k3d/

# This will create:
# - ArgoCD namespace and deployment
# - Core infrastructure (cloudflared, networking)
# - All applications
# - ArgoCD projects and applications
```

### 2. ArgoCD Access
```bash
# Get ArgoCD admin password
kubectl get secret argocd-initial-admin-secret -n argocd -o jsonpath="{.data.password}" | base64 -d

# Port forward to access ArgoCD UI
kubectl port-forward svc/argocd-server -n argocd 8080:443
```

### 3. Application Structure

#### Root Application
- **Name:** `root`
- **Purpose:** Deploys cluster-wide infrastructure
- **Path:** `clusters/k3d`

#### Projects Application
- **Name:** `projects`
- **Purpose:** Creates ArgoCD projects for organization
- **Path:** `projects`

#### Infrastructure Application
- **Name:** `infrastructure`
- **Purpose:** Deploys core infrastructure components
- **Path:** `base`

#### Apps Application
- **Name:** `apps`
- **Purpose:** Deploys all applications
- **Path:** `apps`

#### Individual Applications
Each app has its own ArgoCD Application manifest:
- `rancher` - Kubernetes management
- `keycloak` - Alternative identity provider
- `gitlab` - Git repository management
- `vault` - Secrets management

### 4. Project Organization

#### Core Project
- **Name:** `core`
- **Purpose:** Core infrastructure components
- **Resources:** Cluster-wide resources

#### Applications Project
- **Name:** `applications`
- **Purpose:** Application deployments
- **Resources:** Application-specific resources

#### Monitoring Project
- **Name:** `monitoring`
- **Purpose:** Monitoring and observability
- **Resources:** Monitoring stack

### 5. Sync Policies

All applications use automated sync with:
- **Prune:** Automatically removes deleted resources
- **Self-Heal:** Automatically fixes drift
- **Retry:** Configurable retry logic
- **CreateNamespace:** Creates namespaces as needed

### 6. Benefits

#### GitOps Workflow
- All changes tracked in git
- Automated deployments
- Declarative configuration

#### App-of-Apps Pattern
- Hierarchical application management
- Separation of concerns
- Scalable organization

#### Project-Based Organization
- Resource isolation
- Team-based access control
- Consistent policies

### 7. Monitoring

```bash
# Check ArgoCD applications
kubectl get applications -n argocd

# Check sync status
kubectl get applications -n argocd -o wide

# View application details
argocd app get <app-name>

# Sync manually if needed
argocd app sync <app-name>
```

### 8. Troubleshooting

#### Common Issues
1. **Sync Failures:** Check application logs
2. **Permission Issues:** Verify RBAC settings
3. **Network Issues:** Check connectivity to git repo

#### Commands
```bash
# Check ArgoCD server logs
kubectl logs -n argocd deployment/argocd-server

# Check application controller logs
kubectl logs -n argocd deployment/argocd-application-controller

# Force sync application
argocd app sync <app-name> --force

# Refresh application
argocd app refresh <app-name>
```
