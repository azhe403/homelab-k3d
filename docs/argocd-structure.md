# ArgoCD Monorepo Structure

## Recommended Organization

```
homelab-k3d/
├── base/                           # Core infrastructure
│   ├── argocd/                     # ArgoCD itself
│   ├── cloudflared/                # Cloudflare tunnel
│   ├── networking/                 # Network policies
│   └── monitoring/                 # Prometheus/Grafana
├── apps/                           # Application deployments
│   ├── gitlab/
│   ├── keycloak/
│   ├── rancher/
│   └── vault/
├── clusters/                       # Cluster-specific configs
│   ├── k3d/
│   │   ├── base/                   # Base cluster resources
│   │   └── overlays/               # Environment-specific overlays
│   └── production/
├── environments/                   # Environment configurations
│   ├── dev/
│   └── prod/
└── projects/                       # ArgoCD project definitions
    ├── core/
    ├── apps/
    └── monitoring/
```

## ArgoCD Application Structure

### Root Application (Bootstrap)
```yaml
# clusters/k3d/argocd-root.yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: root
  namespace: argocd
spec:
  destination:
    server: https://kubernetes.default.svc
    namespace: argocd
  source:
    path: clusters/k3d
    repoURL: https://github.com/azhe403/homelab-k3d.git
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
```

### Project-Based Applications
```yaml
# clusters/k3d/apps.yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: apps
  namespace: argocd
spec:
  destination:
    server: https://kubernetes.default.svc
    namespace: argocd
  source:
    path: apps
    repoURL: https://github.com/azhe403/homelab-k3d.git
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
```

## Benefits of Monorepo Approach

1. **Single Source of Truth** - All infrastructure in one place
2. **Atomic Commits** - Related changes can be committed together
3. **Simplified CI/CD** - One pipeline to rule them all
4. **Consistent Standards** - Enforce patterns across all apps
5. **Dependency Management** - Easy to handle inter-service dependencies

## When to Consider Split Repos

Only consider splitting if you have:
- Multiple independent teams
- Different deployment cycles
- Strict compliance requirements
- Very large scale (100+ applications)

## Implementation Steps

1. Create ArgoCD root application
2. Define project-based applications
3. Set up automated sync policies
4. Configure notifications and monitoring
