# Cloudflared Setup (Tunnel) + Vault Secret

This repo runs `cloudflared` in Kubernetes and fetches the tunnel credentials from HashiCorp Vault at startup via a Vault Agent initContainer.

The Cloudflared configuration lives in [base/cloudflared/02-cloudflared-config.yaml](file:///mnt/Zuhrah/Projekts/Space/homelab-k3d/base/cloudflared/02-cloudflared-config.yaml) and the Vault Agent template is in [base/cloudflared/05-vault-agent-config.yaml](file:///mnt/Zuhrah/Projekts/Space/homelab-k3d/base/cloudflared/05-vault-agent-config.yaml).

## Prerequisites

- A Cloudflare account with a zone (your domain) set up in Cloudflare DNS
- `cloudflared` installed locally
- `kubectl` access to the cluster
- `vault` CLI installed locally (optional; you can also run commands from inside the Vault pod)

## 1) Create a Cloudflare Tunnel (local)

Login and create a tunnel:

```bash
cloudflared tunnel login
cloudflared tunnel create homelab-k3d
```

Get the tunnel UUID:

```bash
cloudflared tunnel list
```

Cloudflare writes the tunnel credentials file on your machine:

- `~/.cloudflared/<TUNNEL_UUID>.json`

## 2) Configure tunnel + hostnames in this repo

Edit [02-cloudflared-config.yaml](file:///mnt/Zuhrah/Projekts/Space/homelab-k3d/base/cloudflared/02-cloudflared-config.yaml):

- Set `tunnel: <TUNNEL_UUID>`
- Add/update `ingress:` hostnames to the services you want to expose

Cloudflared uses the rendered credentials file:

- `credentials-file: /etc/cloudflared/creds/credentials.json`

## 3) Create DNS records for each hostname (local)

For each hostname in the `ingress:` list:

```bash
cloudflared tunnel route dns <TUNNEL_UUID> argo.example.com
cloudflared tunnel route dns <TUNNEL_UUID> hashi-vault.example.com
```

Optional: use the helper script [scripts/setup-dns-records.sh](file:///mnt/Zuhrah/Projekts/Space/homelab-k3d/scripts/setup-dns-records.sh).

## 4) Store the Cloudflared credentials in Vault (KV v2)

Cloudflared’s Vault Agent reads KV v2 at:

- Secret path: `secret/cloudflared`
- API path used by the template: `secret/data/cloudflared`
- Required keys: `AccountTag`, `TunnelSecret`, `TunnelID`

See the template in [05-vault-agent-config.yaml](file:///mnt/Zuhrah/Projekts/Space/homelab-k3d/base/cloudflared/05-vault-agent-config.yaml#L25-L36).

### 4.1 Port-forward Vault (local)

This repo includes a persistent port-forward script:

```bash
./scripts/port-forward-vault.sh
```

In another terminal:

```bash
export VAULT_ADDR="http://127.0.0.1:18200"
vault login <ROOT_TOKEN>
```

### 4.2 Enable KV v2 at `secret/` (once)

```bash
vault secrets enable -path=secret kv-v2
```

If it already exists, Vault will return an error and you can continue.

### 4.3 Write the tunnel credentials into Vault

Extract values from the credentials JSON file created by `cloudflared`:

```bash
TUNNEL_ID="<TUNNEL_UUID>"
CREDS_FILE="$HOME/.cloudflared/${TUNNEL_ID}.json"

ACCOUNT_TAG="$(jq -r .AccountTag "$CREDS_FILE")"
TUNNEL_SECRET="$(jq -r .TunnelSecret "$CREDS_FILE")"
```

Write them into Vault KV:

```bash
vault kv put secret/cloudflared \
  AccountTag="$ACCOUNT_TAG" \
  TunnelSecret="$TUNNEL_SECRET" \
  TunnelID="$TUNNEL_ID"
```

Verify:

```bash
vault kv get secret/cloudflared
```

## 5) Configure Vault Kubernetes auth for Cloudflared

Cloudflared’s initContainer authenticates via Kubernetes auth:

- Auth mount path: `auth/kubernetes`
- Role name: `cloudflared`
- Kubernetes ServiceAccount: `cloudflared` in namespace `cloudflared` ([04-serviceaccount.yaml](file:///mnt/Zuhrah/Projekts/Space/homelab-k3d/base/cloudflared/04-serviceaccount.yaml))

For a focused guide on creating Vault policies and Kubernetes auth roles, see [vault-kubernetes-auth-role-policy.md](file:///mnt/Zuhrah/Projekts/Space/homelab-k3d/docs/vault-kubernetes-auth-role-policy.md).

### 5.0 How role/policy fit together

- Policy answers: what paths can this token access in Vault?
- Role answers: which Kubernetes identities (ServiceAccount + namespace) are allowed to mint a Vault token, and which policies are attached to that token?

In this repo, the role `cloudflared` issues a Vault token that has the `cloudflared` policy. That policy allows reading the KV v2 secret at `secret/data/cloudflared`, which is then rendered to `/etc/cloudflared/creds/credentials.json` by the Vault Agent template.

### 5.1 Run Vault auth setup from inside the Vault pod

This avoids needing to guess the Kubernetes API URL or CA cert.

Open a shell in the Vault pod:

```bash
kubectl -n vault exec -it deploy/vault -- sh
```

Inside the pod:

```sh
export VAULT_ADDR="http://127.0.0.1:8200"
vault login <ROOT_TOKEN>

vault auth enable kubernetes

vault write auth/kubernetes/config \
  kubernetes_host="https://${KUBERNETES_SERVICE_HOST}:${KUBERNETES_SERVICE_PORT_HTTPS}" \
  token_reviewer_jwt=@/var/run/secrets/kubernetes.io/serviceaccount/token \
  kubernetes_ca_cert=@/var/run/secrets/kubernetes.io/serviceaccount/ca.crt
```

This config uses the Vault pod’s ServiceAccount token as the reviewer JWT for TokenReview calls. The repo binds the Vault ServiceAccount to `system:auth-delegator` so TokenReview works ([08-vault-serviceaccount-rbac.yaml](file:///mnt/Zuhrah/Projekts/Space/homelab-k3d/apps/vault/base/08-vault-serviceaccount-rbac.yaml)).

### 5.2 Create a policy allowing Cloudflared to read its credentials

```sh
vault policy write cloudflared - <<'EOF'
path "secret/data/cloudflared" {
  capabilities = ["read"]
}
EOF
```

KV v2 notes:

- Reading secret values is `secret/data/<name>`
- Listing versions/metadata is `secret/metadata/<name>` (not required for the current template)

Optional stricter version (if you never want list capabilities at all, keep the minimal policy above):

```sh
vault policy write cloudflared - <<'EOF'
path "secret/data/cloudflared" {
  capabilities = ["read"]
}
path "secret/metadata/cloudflared" {
  capabilities = ["read"]
}
EOF
```

### 5.3 Create the Kubernetes auth role used by the Cloudflared Pod

```sh
vault write auth/kubernetes/role/cloudflared \
  bound_service_account_names="cloudflared" \
  bound_service_account_namespaces="cloudflared" \
  policies="cloudflared" \
  ttl="1h"
```

Role hardening options you may want:

```sh
vault write auth/kubernetes/role/cloudflared \
  bound_service_account_names="cloudflared" \
  bound_service_account_namespaces="cloudflared" \
  policies="cloudflared" \
  ttl="15m" \
  max_ttl="1h"
```

### 5.4 Test the role + policy end-to-end

Create a short-lived Kubernetes token for the `cloudflared` ServiceAccount:

```bash
JWT="$(kubectl -n cloudflared create token cloudflared --duration=10m)"
```

Login to Vault using that JWT:

```bash
vault write auth/kubernetes/login role="cloudflared" jwt="$JWT"
```

Use the returned `auth.client_token` to verify access:

```bash
vault login <TOKEN_FROM_LOGIN>
vault kv get secret/cloudflared
```

## 6) Deploy/verify Cloudflared

Apply the Cloudflared base:

```bash
kubectl apply -k base/cloudflared/
```

Watch the initContainer and main container logs:

```bash
kubectl -n cloudflared get pods
kubectl -n cloudflared logs deploy/cloudflared -c vault-agent
kubectl -n cloudflared logs deploy/cloudflared -c cloudflared
```

Verify the credentials file exists in the running pod:

```bash
POD="$(kubectl -n cloudflared get pod -l app=cloudflared -o jsonpath='{.items[0].metadata.name}')"
kubectl -n cloudflared exec -it "$POD" -- sh -c 'ls -l /etc/cloudflared/creds && cat /etc/cloudflared/creds/credentials.json'
```

## Notes

- Do not commit tunnel credentials. Keep `~/.cloudflared/<TUNNEL_UUID>.json` local and store values in Vault.
- This repo uses a Vault Agent initContainer to materialize `/etc/cloudflared/creds/credentials.json` at pod startup; Kubernetes Secret creation via [scripts/setup-cloudflared-credentials.sh](file:///mnt/Zuhrah/Projekts/Space/homelab-k3d/scripts/setup-cloudflared-credentials.sh) is not used by the current Deployment.
