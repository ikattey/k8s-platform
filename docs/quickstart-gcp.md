# Quickstart: GCP (GKE)

This quickstart provisions a public starter cluster on Google Kubernetes Engine,
bootstraps ArgoCD, and wires portable storage classes, Cloudflare DNS, 1Password,
OIDC, CNPG, and optional Velero data movement.

## 1. Prerequisites

Install:

- `terraform` (~> 1.14)
- `kubectl`
- `helm`
- `gcloud` CLI ([install guide](https://cloud.google.com/sdk/docs/install))

**Required accounts:**

- **GCP** -- a project with billing enabled (covered in steps 2--4).
- **Cloudflare** -- a domain managed in Cloudflare for DNS automation. [Create an API token](https://dash.cloudflare.com/profile/api-tokens) using the "Edit zone DNS" template, scoped to your domain's zone.
- **1Password** -- a service account with read/write access to an infrastructure vault. Create one in your 1Password admin console under Developer > Service Accounts. You need the vault **UUID** (find via `op vault list` or visible in the URL at Settings > Vaults). Also set up a **team logins vault** (can be the same vault or a separate one shared with your team) — Terraform writes browser-login items here for ArgoCD, Grafana, Prometheus, and Alertmanager so your team can log in via 1Password.

## 2. GCP authentication

Both commands are required. `auth login` authenticates the `gcloud` CLI; `application-default login` gives Terraform access via Application Default Credentials.

```bash
gcloud auth login
gcloud auth application-default login
```

Set your active project:

```bash
gcloud config set project YOUR_GCP_PROJECT
```

## 3. Enable required APIs

```bash
gcloud services enable \
  container.googleapis.com \
  compute.googleapis.com \
  iamcredentials.googleapis.com \
  sqladmin.googleapis.com \
  servicenetworking.googleapis.com \
  storage.googleapis.com \
  --project YOUR_GCP_PROJECT
```

## 4. Create a Terraform state bucket

GCP uses GCS for Terraform state:

```bash
gcloud storage buckets create gs://your-state-bucket \
  --project=your-gcp-project \
  --location=europe-west2
```

Pick a bucket name that is globally unique.

## 5. Configure environment

Build your `.env` from the split example files:

```bash
cp .env.shared.example .env
cat .env.gcp.example >> .env
```

Optionally append OIDC and extras:

```bash
cat .env.oidc.example >> .env      # SSO for kubectl, Grafana, ArgoCD
cat .env.extras.example >> .env    # GHCR, GitHub token for private repos
```

Fill in the values:

- `TF_VAR_project_id` -- your GCP project ID
- `TF_VAR_state_bucket` -- GCS bucket name (from step 4)
- `TF_VAR_cloudflare_api_token`, `TF_VAR_domain`, `TF_VAR_letsencrypt_email` -- from `.env.shared.example`
- `TF_VAR_onepassword_service_account_token`, `TF_VAR_onepassword_vault_id` -- from `.env.shared.example`

> GCP uses Application Default Credentials (set via `gcloud auth application-default login`) rather than API keys. The `AWS_ACCESS_KEY_ID` / `AWS_SECRET_ACCESS_KEY` fields in `.env.shared.example` are not used for GCP clusters — leave them empty or omit them.

Then source:

```bash
source .env
```

Never commit `.env` to git. Run the `cp`/`cat` steps once. Delete `.env` before re-running.

## 6. Configure Terraform state

Edit `terraform/clusters/gcp-starter/cluster/backend.tf` and
`terraform/clusters/gcp-starter/addons/backend.tf` to point at your GCS state bucket.

## 7. Create the cluster stage tfvars

Create `terraform/clusters/gcp-starter/cluster/terraform.tfvars` from the example.

Minimum example:

```hcl
project_id   = "your-gcp-project"
cluster_name = "gcp-starter"
region       = "europe-west2"
location     = "europe-west2-a"
environment  = "production"
```

Optional managed PostgreSQL:

```hcl
database_provider = "managed"
cloud_sql_tier    = "db-custom-2-4096"
```

Leave `database_provider = "cnpg"` to keep PostgreSQL in-cluster.
Use `database_provider = "external"` when you will provide the
`database-credentials` secret by other means.

## 8. Apply the cluster stage

```bash
cd terraform/clusters/gcp-starter/cluster
terraform init
terraform plan
terraform apply
```

After apply, configure `kubectl`:

```bash
gcloud container clusters get-credentials gcp-starter \
  --location europe-west2-a \
  --project your-gcp-project
```

## 9. Create the addons stage tfvars

Create `terraform/clusters/gcp-starter/addons/terraform.tfvars` from the example.

Typical values:

```hcl
state_bucket      = "your-tf-state-bucket"
cloud_provider    = "gcp"
cluster_name      = "gcp-starter"
domain            = "example.com"
letsencrypt_email = "ops@example.com"
cnpg_enabled      = true
cnpg_instances    = 3
```

Provide sensitive values through `TF_VAR_...` environment variables (already exported via `.env`).

If you enable OIDC, also set the Grafana / ArgoCD / kubectl client IDs and
secrets through `TF_VAR_...` variables.

## 10. Apply the addons stage

```bash
cd ../addons
terraform init
terraform plan
terraform apply
```

This stage bootstraps:

- ArgoCD app-of-apps
- bootstrap secrets for Cloudflare, Grafana, and optional OIDC
- portable storage classes `fast-rwo` and `standard-rwo`
- Workload Identity bindings for Loki, CNPG backups, and Velero

## 11. Enable platform components in GitOps

Edit `clusters/gcp-starter/values.yaml` and enable the components you want.
Example:

```yaml
components:
  demoApp: true
  cnpg: true
  velero: true
  valkey: true
  nats: true
  typesense: true
```

For production, switch the cluster issuer from staging to production once DNS
and routing are verified.

### Velero on GCP

When `velero: true`, the addons stage creates a dedicated GCP service account and Workload Identity binding. Set the service account email in `clusters/gcp-starter/values.yaml`:

```yaml
veleroGcpServiceAccount: "velero@your-gcp-project.iam.gserviceaccount.com"
```

The bucket name is read from `veleroBucketName` (set by Terraform at bootstrap). Velero v1.14+ includes CSI support natively — no additional init container is needed. See [backups.md](backups.md#velero) for full configuration details.

## 12. Verify storage classes and storage nodes

```bash
kubectl get storageclass
kubectl get nodes -L k8s-platform/pool-role
```

Expected portable aliases:

- `fast-rwo` -> `pd-ssd`
- `standard-rwo` -> `pd-balanced`

If you enabled `enable_storage_node_pool = true` in Stage 1, you'll also see nodes labeled
`k8s-platform/pool-role=storage` and tainted `k8s-platform/pool-role=storage:NoSchedule`.
By default, all workloads run on general nodes. See [node-pools.md](node-pools.md) for opt-in storage targeting.

## 13. Verify ArgoCD and Grafana access

```bash
kubectl get ingress -A
kubectl get applications -n argocd
```

ArgoCD and Grafana hostnames follow this pattern:

- `argocd-gcp-starter.example.com`
- `grafana-gcp-starter.example.com`

## 14. Managed DB vs CNPG

- `database_provider = "cnpg"`: the demo app consumes the in-cluster
  `database-credentials` secret that Terraform seeds before ArgoCD sync.
- `database_provider = "managed"`: the demo app consumes the same secret
  contract, but Terraform fills it with Cloud SQL connection details.
- `database_provider = "external"`: keep the same secret contract, but create
  `database-credentials` yourself or sync it through External Secrets.
