# Quickstart: GCP (GKE)

This quickstart provisions a public starter cluster on Google Kubernetes Engine,
bootstraps ArgoCD, and wires portable storage classes, Cloudflare DNS, 1Password,
OIDC, CNPG, and optional Velero data movement.

## 1. Prerequisites

You need:

- a GCP project with billing enabled
- `gcloud` authenticated as a project admin
- a Cloudflare zone and API token
- a 1Password service-account token and an infra vault for bootstrap secrets
- Terraform 1.14+

Enable the APIs used by the platform if they are not already enabled:

```bash
gcloud services enable   container.googleapis.com   compute.googleapis.com   iamcredentials.googleapis.com   sqladmin.googleapis.com   servicenetworking.googleapis.com   storage.googleapis.com   --project YOUR_GCP_PROJECT
```

## 2. Configure Terraform state

Edit `terraform/clusters/gcp-starter/cluster/backend.tf` and
`terraform/clusters/gcp-starter/addons/backend.tf` to point at your GCS state bucket.

## 3. Create the cluster stage tfvars

Create `terraform/clusters/gcp-starter/cluster/terraform.tfvars` from the example.

Minimum example:

```hcl
project_id   = "your-gcp-project"
cluster_name = "gcp-starter"
region       = "europe-west1"
location     = "europe-west1-b"
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

## 4. Apply the cluster stage

```bash
cd terraform/clusters/gcp-starter/cluster
terraform init
terraform plan
terraform apply
```

After apply, configure `kubectl`:

```bash
gcloud container clusters get-credentials gcp-starter   --location europe-west1-b   --project your-gcp-project
```

## 5. Create the addons stage tfvars

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

Provide secrets through environment variables:

```bash
export TF_VAR_onepassword_service_account_token="op://..."
export TF_VAR_onepassword_infra_vault="k8s-infra"
export TF_VAR_cloudflare_api_token="..."
export TF_VAR_domain="example.com"
```

If you enable OIDC, also set the Grafana / ArgoCD / kubectl client IDs and
secrets through `TF_VAR_...` variables.

## 6. Apply the addons stage

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

## 7. Enable platform components in GitOps

Edit `clusters/gcp-starter/values.yaml` and enable the components you want.
Example:

```yaml
components:
  demoApp: true
  cnpg: true
  velero: true
  dragonfly: true
  nats: true
  typesense: true
```

For production, switch the cluster issuer from staging to production once DNS
and routing are verified.

## 8. Verify storage classes and storage nodes

```bash
kubectl get storageclass
kubectl get nodes -L k8s-platform/pool-role
```

Expected portable aliases:

- `fast-rwo` -> `pd-ssd`
- `standard-rwo` -> `pd-balanced`

The starter cluster creates a dedicated storage node pool labeled
`k8s-platform/pool-role=storage` and tainted `k8s-platform/pool-role=storage:NoSchedule`
so CNPG and other stateful workloads can be isolated. See [node-pools.md](node-pools.md).

## 9. Verify ArgoCD and Grafana access

```bash
kubectl get ingress -A
kubectl get applications -n argocd
```

ArgoCD and Grafana hostnames follow this pattern:

- `argocd-gcp-starter.example.com`
- `grafana-gcp-starter.example.com`

## 10. Managed DB vs CNPG

- `database_provider = "cnpg"`: the demo app consumes the in-cluster
  `database-credentials` secret that Terraform seeds before ArgoCD sync.
- `database_provider = "managed"`: the demo app consumes the same secret
  contract, but Terraform fills it with Cloud SQL connection details.
- `database_provider = "external"`: keep the same secret contract, but create
  `database-credentials` yourself or sync it through External Secrets.
