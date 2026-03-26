#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

ARGOCD_RENDER="$TMP_DIR/argocd.yaml"
BOOTSTRAP_RENDER="$TMP_DIR/bootstrap-secrets.yaml"
MIDDLEWARE_RENDER="$TMP_DIR/monitoring-middleware.yaml"

helm template root argocd/ \
  --set repoURL="https://github.com/example/repo.git" \
  --set targetRevision="main" \
  --set domain="masenahq.com" \
  --set clusterName="aws-starter" \
  --set onepasswordVaultId="vault-id" \
  --set lokiBucketNames.chunks="bucket-chunks" \
  --set lokiBucketNames.ruler="bucket-ruler" \
  --set databaseEnabled=true \
  --set onepasswordItemUuids.database="db-item-uuid" \
  --set onepasswordItemUuids.monitoringBasicAuth="monitoring-item-uuid" \
  > "$ARGOCD_RENDER"

grep -q 'name: secrets.database.onepasswordItemUuid' "$ARGOCD_RENDER"
grep -q 'value: "db-item-uuid"' "$ARGOCD_RENDER"
grep -q 'onepasswordItemUuid: "monitoring-item-uuid"' "$ARGOCD_RENDER"

helm template bootstrap values/bootstrap-secrets/ \
  -f clusters/aws-starter/bootstrap-secrets.yaml \
  --set onepasswordVaultId="vault-id" \
  --set secrets.database.enabled=true \
  --set secrets.database.onepasswordItemUuid="db-item-uuid" \
  > "$BOOTSTRAP_RENDER"

grep -q 'key: db-item-uuid/DATABASE_WRITE_URL' "$BOOTSTRAP_RENDER"

helm template monitoring-middleware values/monitoring-middleware/ \
  --set onepasswordItemName="monitoring-basic-auth-aws-starter" \
  --set onepasswordItemUuid="monitoring-item-uuid" \
  > "$MIDDLEWARE_RENDER"

grep -q 'key: monitoring-item-uuid/users' "$MIDDLEWARE_RENDER"
