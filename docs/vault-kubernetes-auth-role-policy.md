# Vault Kubernetes Auth: Roles and Policies

This doc explains how to create a Vault policy and bind it to a Kubernetes auth role, so pods can read specific secrets safely.

It assumes Vault is running inside the cluster and you can authenticate as an admin (root token or equivalent).

## Concepts

- Policy: permissions in Vault (what paths can be read/written/listed).
- Role (Kubernetes auth): a mapping from Kubernetes identity (ServiceAccount + namespace) to one or more Vault policies.
- Login flow:
  - A pod (or Vault Agent) presents a Kubernetes ServiceAccount JWT to Vault.
  - Vault verifies the JWT with the Kubernetes API (TokenReview).
  - Vault returns a Vault token with the policies configured on the role.

## Prerequisites

- Vault Kubernetes auth is enabled at `auth/kubernetes`
- Vault can call TokenReview on the Kubernetes API
- The target app has a Kubernetes ServiceAccount

In this repo, Vault’s ServiceAccount is bound to `system:auth-delegator` so TokenReview works: [08-vault-serviceaccount-rbac.yaml](file:///mnt/Zuhrah/Projekts/Space/homelab-k3d/apps/vault/base/08-vault-serviceaccount-rbac.yaml).

## 1) Enable Kubernetes auth (once)

Run (as admin):

```bash
vault auth enable kubernetes
```

## 2) Configure Kubernetes auth (TokenReview)

Recommended: run this from inside the Vault pod so you can reuse in-cluster env vars and mounted CA/token files.

```bash
kubectl -n vault exec -it deploy/vault -- sh
```

Inside the pod:

```sh
export VAULT_ADDR="http://127.0.0.1:8200"
vault login <ADMIN_TOKEN>

vault write auth/kubernetes/config \
  kubernetes_host="https://${KUBERNETES_SERVICE_HOST}:${KUBERNETES_SERVICE_PORT_HTTPS}" \
  token_reviewer_jwt=@/var/run/secrets/kubernetes.io/serviceaccount/token \
  kubernetes_ca_cert=@/var/run/secrets/kubernetes.io/serviceaccount/ca.crt
```

## 3) Write a policy (least privilege)

### KV v2 read policy

If you use KV v2 mounted at `secret/` and you want to read `secret/<name>`, the data endpoint is:

- `secret/data/<name>`

Example: allow reading only `secret/cloudflared`:

```bash
vault policy write cloudflared - <<'EOF'
path "secret/data/cloudflared" {
  capabilities = ["read"]
}
EOF
```

Optional: if you need metadata reads (usually not needed for templating a single secret):

```bash
vault policy write cloudflared - <<'EOF'
path "secret/data/cloudflared" {
  capabilities = ["read"]
}
path "secret/metadata/cloudflared" {
  capabilities = ["read"]
}
EOF
```

## 4) Create a Kubernetes auth role

A role binds Kubernetes identity to policies.

Example role for:

- ServiceAccount: `cloudflared`
- Namespace: `cloudflared`
- Policy: `cloudflared`

```bash
vault write auth/kubernetes/role/cloudflared \
  bound_service_account_names="cloudflared" \
  bound_service_account_namespaces="cloudflared" \
  policies="cloudflared" \
  ttl="15m" \
  max_ttl="1h"
```

Hardening guidelines:

- Bind to exact ServiceAccount names and namespaces (avoid `*`).
- Keep `ttl` short; set `max_ttl` to a reasonable upper bound.
- Use a dedicated policy per workload.

## 5) Test the role + policy

Create a short-lived token for the workload ServiceAccount:

```bash
JWT="$(kubectl -n cloudflared create token cloudflared --duration=10m)"
```

Login to Vault using that JWT:

```bash
vault write auth/kubernetes/login role="cloudflared" jwt="$JWT"
```

Use the returned `auth.client_token` to verify permissions:

```bash
vault login <TOKEN_FROM_LOGIN>
vault kv get secret/cloudflared
```

If the policy is too restrictive or wrong path (KV v1 vs v2), this step fails with permission denied.

## Related docs in this repo

- Cloudflared + Vault end-to-end setup: [cloudflared-vault-setup.md](file:///mnt/Zuhrah/Projekts/Space/homelab-k3d/docs/cloudflared-vault-setup.md)
