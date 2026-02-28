# Homelab Cloudflared YAMLs

1. 01-cloudflared-configmap.yaml  → ConfigMap untuk tunnel + ingress host
2. 02-cloudflared-deployment.yaml → Deployment Cloudflared
3. 03-argocd-ingress.yaml         → Ingress ArgoCD, routing ke argocd-server
4. 04-grafana-ingress.yaml        → Ingress Grafana, routing ke monitoring-grafana

## Keycloak Deployment

5. apps/keycloak/01-namespace.yaml              → Namespace untuk Keycloak
6. apps/keycloak/02-secrets.yaml                → Secrets untuk admin dan database
7. apps/keycloak/03-postgres-deployment.yaml    → PostgreSQL database
8. apps/keycloak/04-postgres-pvc.yaml           → Persistent volume untuk PostgreSQL
9. apps/keycloak/05-postgres-service.yaml       → Service untuk PostgreSQL
10. apps/keycloak/06-keycloak-deployment.yaml   → Keycloak deployment
11. apps/keycloak/07-keycloak-service.yaml      → Service untuk Keycloak
*Note: Keycloak ingress handled by Cloudflared tunnel*

## Apply urut

### Cloudflared & Existing Services
kubectl apply -f cloudflared/cloudflared-config.yaml
kubectl apply -f cloudflared/cloudflared-deployment.yaml
kubectl apply -f 03-argocd-ingress.yaml
kubectl apply -f 04-grafana-ingress.yaml

### Keycloak
kubectl apply -f apps/keycloak/01-namespace.yaml
kubectl apply -f apps/keycloak/02-secrets.yaml
kubectl apply -f apps/keycloak/04-postgres-pvc.yaml
kubectl apply -f apps/keycloak/03-postgres-deployment.yaml
kubectl apply -f apps/keycloak/05-postgres-service.yaml
kubectl apply -f apps/keycloak/06-keycloak-deployment.yaml
kubectl apply -f apps/keycloak/07-keycloak-service.yaml

## Access Keycloak
- **Internal URL**: http://keycloak-service.keycloak.svc.cluster.local:8080
- **External URL**: https://kc.corp.azhe.my.id (requires DNS configuration in Cloudflare)
- **Admin username**: admin
- **Admin password**: admin123

## Status
✅ Keycloak deployment: Running successfully
✅ PostgreSQL database: Running successfully  
✅ Internal connectivity: Working (HTTP 200)
⚠️ External access: Requires Cloudflare DNS setup for kc.corp.azhe.my.id

## Troubleshooting
If external access doesn't work, ensure:
1. DNS record `kc.corp.azhe.my.id` exists in Cloudflare
2. DNS record points to the Cloudflare tunnel
3. Cloudflared tunnel is running and configured correctly
