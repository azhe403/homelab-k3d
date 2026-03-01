#!/bin/bash

# Keycloak Admin Credentials
KEYCLOAK_URL="https://keycloak.azhe.my.id"
ADMIN_USER="admin"
ADMIN_PASSWORD="admin"
REALM="master"
CLIENT_ID="argocd"

# Get admin token
echo "Getting admin token..."
TOKEN=$(curl -s -k -X POST "$KEYCLOAK_URL/realms/master/protocol/openid-connect/token" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "username=$ADMIN_USER&password=$ADMIN_PASSWORD&grant_type=password&client_id=admin-cli" | jq -r '.access_token')

if [ "$TOKEN" == "null" ]; then
    echo "Failed to get admin token"
    exit 1
fi

echo "Creating ArgoCD client in Keycloak..."

# Create the client
curl -s -X POST "$KEYCLOAK_URL/admin/realms/$REALM/clients" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "clientId": "'$CLIENT_ID'",
    "name": "ArgoCD",
    "description": "ArgoCD GitOps Platform",
    "enabled": true,
    "clientAuthenticatorType": "client-secret",
    "secret": "argocd-client-secret-123",
    "redirectUris": ["http://argo.azhe.my.id/api/dex/callback"],
    "webOrigins": ["http://argo.azhe.my.id"],
    "protocol": "openid-connect",
    "publicClient": false,
    "standardFlowEnabled": true,
    "directAccessGrantsEnabled": true,
    "serviceAccountsEnabled": true,
    "fullScopeAllowed": false,
    "attributes": {
      "saml.assertion.signature": "false",
      "saml.multivalued.roles": "false",
      "saml.force.post.binding": "false",
      "saml.server.signature": "false",
      "saml.server.signature.keyinfo.ext": "false",
      "exclude.session.state.from.auth.response": "false",
      "saml.force.name.id.format": "false",
      "saml.client.signature": "false",
      "tls.client.certificate.bound.access.tokens": "false",
      "saml.authnstatement": "false",
      "display.on.consent.screen": "false",
      "saml.onetimeuse.condition": "false"
    }
  }'

echo "Client created. Now updating ArgoCD configuration with the correct secret..."

# Update ArgoCD config with the actual client secret
kubectl patch configmap argocd-cm -n argocd --type merge -p '{"data":{"oidc.config":"{\"name\":\"Keycloak\",\"issuer\":\"https://keycloak.azhe.my.id/realms/master\",\"clientID\":\"argocd\",\"clientSecret\":\"argocd-client-secret-123\",\"requestedScopes\":[\"openid\",\"profile\",\"email\",\"groups\"]}"}}'

# Update Dex config
kubectl patch configmap argocd-dex-server-config -n argocd --type merge -p '{"data":{"config.yaml":"issuer: https://keycloak.azhe.my.id/realms/master\nstorage:\n  type: memory\nweb:\n  http: 0.0.0.0:5556\nconnectors:\n- type: oidc\n  id: keycloak\n  name: Keycloak\n  config:\n    issuer: https://keycloak.azhe.my.id/realms/master\n    clientID: argocd\n    clientSecret: argocd-client-secret-123\n    requestedScopes: [\"openid\", \"profile\", \"email\", \"groups\"]\nstaticClients:\n- id: argocd\n  redirectURIs:\n  - http://argo.azhe.my.id/api/dex/callback\n  name: ArgoCD\n  secret: ZXhhbXBsZWFwcHNlY3JldA=="}}'

# Restart ArgoCD server and Dex
kubectl rollout restart deployment argocd-server -n argocd
kubectl rollout restart deployment argocd-dex-server -n argocd

echo "Keycloak client setup completed!"
echo "ArgoCD will now use Keycloak for authentication."
echo "Access ArgoCD at: http://argo.azhe.my.id"
