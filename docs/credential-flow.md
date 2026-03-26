# Credential Flow

## Bootstrap flow

1. Stage 2 Terraform creates the `onepassword-token` Secret for ESO (requires `enable_onepassword_bootstrap = true`, the default).
2. ArgoCD installs ESO.
3. ArgoCD installs the `platform-secrets` app, which creates the
   `ClusterSecretStore`.
4. ArgoCD installs `bootstrap-secrets`.
5. ESO reads 1Password items and writes namespace-local Kubernetes Secrets.
6. ArgoCD installs `monitoring-middleware`, which creates `monitoring/monitoring-basic-auth` (via ExternalSecret from 1Password) and the Traefik basicAuth Middleware that references it.

When CNPG is enabled, Stage 2 also creates the `database` namespace early so bootstrap secrets exist before the CNPG app syncs.

The kit uses 1Password via ESO's `onepasswordSDK` provider. To use a different backend (AWS Secrets Manager, Vault, GCP Secret Manager), update the `ClusterSecretStore` in `values/platform-secrets/templates/cluster-secret-store.yaml`, set `secretStoreName` in each cluster's `bootstrap-secrets.yaml`, and adjust the `onepasswordItem` values to match your backend's key format. The ExternalSecret template uses standard ESO `key`/`property` fields and works across all backends. See [external-secrets-backends.md](external-secrets-backends.md) for a full migration guide.

## How secrets reach workloads

Terraform creates Kubernetes Secrets and syncs them to 1Password. ESO keeps Kubernetes Secrets in sync (refresh interval: 5 minutes). Workloads mounting secrets at startup must restart to pick up rotated values.

## Item types

Infrastructure items (for Kubernetes Secret sync via ESO):

- `grafana-<cluster>` when `TF_VAR_onepassword_vault_id` is set
- `loki-s3-<cluster>` when `TF_VAR_onepassword_vault_id` is set and the cluster stage outputs S3 access/secret key credentials for object storage
- `cnpg-backup-<cluster>` when `TF_VAR_onepassword_vault_id` is set, CNPG is enabled, and the cluster stage outputs S3 credentials
- `cloudflare-dns-<cluster>` when `TF_VAR_onepassword_vault_id` is set
- `monitoring-basic-auth-<cluster>` when `TF_VAR_onepassword_vault_id` is set
- `grafana-oidc-<cluster>` when Grafana OAuth is enabled and `TF_VAR_onepassword_vault_id` is set
- `argocd-oidc-<cluster>` when ArgoCD OIDC is enabled and `TF_VAR_onepassword_vault_id` is set
- `database-<cluster>` when the database contract is enabled and `TF_VAR_onepassword_vault_id` is set

Terraform creates `grafana-admin` at bootstrap. `grafana-<cluster>` is the ESO sync item; `grafana-admin-<cluster>` is the browser-login item.

Browser-login items for human access (written to the infra vault when `TF_VAR_onepassword_vault_id` is set):

- `argocd-<cluster>`
- `grafana-admin-<cluster>`
- `prometheus-<cluster>`
- `alertmanager-<cluster>`

## Managed PostgreSQL credentials

When `database_provider = "managed"`:

1. Stage 1 provisions the platform database and exports the same output contract on every supported managed path:
   AWS uses RDS, GCP uses Cloud SQL, and OVH uses OVH managed PostgreSQL.
2. Stage 2 creates `demo/database-credentials` (`DB_HOST`, `DB_PORT`, `DB_NAME`, `DB_USER`, `DB_PASSWORD`, `DATABASE_WRITE_URL`, `DATABASE_READ_URL`) and writes `database-<cluster>` to 1Password.
3. When `database.enabled: true` in `clusters/<cluster>/bootstrap-secrets.yaml`, ESO keeps the Kubernetes Secret refreshed from 1Password.

When CNPG is used instead, Terraform seeds the same Secret contract from the in-cluster PostgreSQL bootstrap credentials. On Hetzner, `database_provider = "external"` uses that exact same Secret contract, but you provide the backing credentials yourself.

## Required environment

Export the service-account token. `OP_SERVICE_ACCOUNT_TOKEN` is auto-aliased in `.env.shared.example`, so you only set the value once:

```bash
export TF_VAR_onepassword_service_account_token="ops.xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
# OP_SERVICE_ACCOUNT_TOKEN is set automatically via the alias in .env.shared.example
```

Infrastructure vault — the UUID is used by both Terraform (to write items) and ESO's ClusterSecretStore (to read them):

```bash
export TF_VAR_onepassword_vault_id="<vault-uuid>"   # find via: op vault list
```

## Secret consumption

Common Kubernetes Secret bindings:

- external-dns reads `external-dns/cloudflare-api-token`
- Grafana reads `monitoring/grafana-admin`
- Grafana OAuth reads `monitoring/grafana-oauth` (when OAuth is enabled)
- Loki reads `monitoring/loki-storage-credentials` on OVH and Hetzner
- Prometheus and Alertmanager ingress read `monitoring/monitoring-basic-auth`
- demo workloads read `demo/database-credentials` (DATABASE_WRITE_URL, DATABASE_READ_URL, DB_HOST, etc.)
- CNPG uses `database/postgres-app-bootstrap` for the initial application user credentials (the `cnpg_database_user` variable)
- CNPG backups read `database/cnpg-backup-credentials` on every cloud

## Verification

```bash
kubectl get clustersecretstore
kubectl get externalsecret -A
kubectl get secret -n monitoring grafana-admin
kubectl get secret -n monitoring monitoring-basic-auth
kubectl get secret -n database cnpg-backup-credentials
```

## Common issues

- wrong vault UUID (check with `op vault list`)
- missing `TF_VAR_onepassword_service_account_token` (also sets `OP_SERVICE_ACCOUNT_TOKEN` via alias)
- wrong item title or field name in the referenced 1Password item
- duplicate 1Password items with the same title (e.g. from a partial
  `terraform apply` that created items then failed). ESO returns
  `"more than one item matched the secret reference query"`. Fix by
  deleting duplicates, or pin specific item UUIDs via
  `onepasswordItemUuids` in `argocd/values.yaml`
