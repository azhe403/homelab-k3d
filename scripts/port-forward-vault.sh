#!/usr/bin/env bash
set -euo pipefail

NAMESPACE="${NAMESPACE:-vault}"
SERVICE="${SERVICE:-vault-service}"
LOCAL_PORT="${LOCAL_PORT:-8200}"
REMOTE_PORT="${REMOTE_PORT:-8200}"
ADDRESS="${ADDRESS:-127.0.0.1}"

while true; do
  kubectl -n "${NAMESPACE}" port-forward "svc/${SERVICE}" "${LOCAL_PORT}:${REMOTE_PORT}" --address "${ADDRESS}" || true
  sleep 2
done
