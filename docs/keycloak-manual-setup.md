# Manual Keycloak Setup for ArgoCD

## Step 1: Create Client in Keycloak

1. Access Keycloak Admin Console: https://keycloak.azhe.my.id/admin/
2. Login with: admin
3. Go to Master realm → Clients
4. Click "Create"
5. Fill in:
   - Client ID: `argocd`
   - Client Protocol: `openid-connect`
   - Root URL: `http://argo.azhe.my.id`
6. Click "Save"

## Step 2: Configure Client

In the client settings:
1. Access Type: `confidential`
2. Standard Flow Enabled: `ON`
3. Direct Access Grants Enabled: `ON` 
4. Service Accounts Enabled: `ON`
5. Valid Redirect URIs: 
   - `https://argo.azhe.my.id/auth/callback`
   - `http://argo.azhe.my.id/auth/callback`
   - `https://argo.azhe.my.id/*`
   - `http://argo.azhe.my.id/*`
6. Web Origins: 
   - `https://argo.azhe.my.id`
   - `http://argo.azhe.my.id`
   - `+`
7. Click "Save"

## Step 2.1: Configure Client Scopes

1. Go to the "Client Scopes" tab
2. Click on the "argocd-dedicated" scope (if it exists) or go to "Scope" tab
3. Make sure the following scopes are enabled:
   - `openid`
   - `profile` 
   - `email`
4. If using dedicated scopes, ensure they are assigned to the client

## Step 3: Get Client Secret

1. Go to the "Credentials" tab
2. Copy the "Client Secret"

## Step 4: Update ArgoCD Configuration

Replace `your-client-secret-here` with the actual client secret:

```bash
kubectl patch configmap argocd-cm -n argocd --type merge -p '{"data":{"oidc.config":"{\"name\":\"Keycloak\",\"issuer\":\"https://keycloak.azhe.my.id/realms/master\",\"clientID\":\"argocd\",\"clientSecret\":\"tFlepOkuCyNi1yo29mJOcto0AeaW3rTg\",\"requestedScopes\":[\"openid\",\"profile\",\"email\"]}"}}'
```

## Step 5: Restart ArgoCD

```bash
kubectl rollout restart deployment argocd-server -n argocd
kubectl rollout restart deployment argocd-dex-server -n argocd
```

## Step 6: Test

Access ArgoCD at http://argo.azhe.my.id and click "Login with Keycloak"
