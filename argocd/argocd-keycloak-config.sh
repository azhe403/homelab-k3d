#!/bin/bash

# Update this with your actual client secret from Keycloak
CLIENT_SECRET="your-client-secret-here"

echo "Updating ArgoCD configuration for Keycloak..."
echo "Make sure you have created the 'argocd' client in Keycloak first!"
echo "See keycloak-manual-setup.md for instructions"
echo ""

# Update ArgoCD config
kubectl patch configmap argocd-cm -n argocd --type merge -p '{"data":{"oidc.config":"{\"name\":\"Keycloak\",\"issuer\":\"https://keycloak.azhe.my.id/realms/master\",\"clientID\":\"argocd\",\"clientSecret\":\"'$CLIENT_SECRET'\",\"requestedScopes\":[\"openid\",\"profile\",\"email\",\"groups\"]}"}}'

# Update Dex config
kubectl patch configmap argocd-dex-server-config -n argocd --type merge -p '{"data":{"config.yaml":"issuer: https://keycloak.azhe.my.id/realms/master\nstorage:\n  type: memory\nweb:\n  http: 0.0.0.0:5556\nconnectors:\n- type: oidc\n  id: keycloak\n  name: Keycloak\n  config:\n    issuer: https://keycloak.azhe.my.id/realms/master\n    clientID: argocd\n    clientSecret: '$CLIENT_SECRET'\n    requestedScopes: [\"openid\", \"profile\", \"email\", \"groups\"]\nstaticClients:\n- id: argocd\n  redirectURIs:\n  - http://argo.azhe.my.id/api/dex/callback\n  name: ArgoCD\n  secret: ZXhhbXBsZWFwcHNlY3JldA=="}}'

# Restart services
echo "Restarting ArgoCD services..."
kubectl rollout restart deployment argocd-server -n argocd
kubectl rollout restart deployment argocd-dex-server -n argocd

echo "Configuration updated!"
echo "Access ArgoCD at: http://argo.azhe.my.id"
