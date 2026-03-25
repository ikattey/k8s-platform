#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

ARGOCD_RENDER="$TMP_DIR/argocd.yaml"
DEMO_RENDER="$TMP_DIR/demo-app.yaml"
NATS_RENDER="$TMP_DIR/nats.yaml"

helm template root argocd/ \
  -f argocd/values.yaml \
  -f clusters/aws-starter/values.yaml \
  --set repoURL="https://github.com/example/repo.git" \
  --set targetRevision="main" \
  --set domain="masenahq.com" \
  --set clusterName="aws-starter" \
  --set onepasswordVaultId="vault-id" \
  --set letsencryptEmail="ops@example.com" \
  --set lokiBucketNames.chunks="bucket-chunks" \
  --set lokiBucketNames.ruler="bucket-ruler" \
  > "$ARGOCD_RENDER"

grep -q 'name: valkey' "$ARGOCD_RENDER"
grep -q 'name: typesense-cluster' "$ARGOCD_RENDER"
grep -q 'name: nats' "$ARGOCD_RENDER"
grep -q 'valkey:' "$ARGOCD_RENDER"
grep -q 'typesense:' "$ARGOCD_RENDER"
grep -q 'nats:' "$ARGOCD_RENDER"
grep -q '\$values/clusters/aws-starter/demo-app-values.yaml' "$ARGOCD_RENDER"

helm template demo-app values/demo-app/ \
  -f clusters/aws-starter/demo-app-values.yaml \
  --set databaseSecret.enabled=true \
  --set valkey.enabled=true \
  --set typesense.enabled=true \
  --set nats.enabled=true \
  > "$DEMO_RENDER"

grep -q 'name: TYPESENSE_API_KEY' "$DEMO_RENDER"
grep -q 'value: "aws-starter-e2e-typesense-key"' "$DEMO_RENDER"

helm template nats values/nats/ \
  -f clusters/aws-starter/nats-values.yaml \
  > "$NATS_RENDER"

grep -q 'replicas: 1' "$NATS_RENDER"
