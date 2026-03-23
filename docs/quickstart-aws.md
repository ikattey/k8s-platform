# Quickstart: AWS (EKS)

This quickstart provisions an EKS-based starter cluster, bootstraps ArgoCD,
creates portable storage classes, and wires Cloudflare, 1Password, OIDC,
CNPG, optional RDS, and optional Velero data movement.

## 1. Prerequisites

Install:

- `terraform` (~> 1.14)
- `kubectl`
- `helm`
- `aws` CLI

**Required accounts:**

- **AWS** -- an account with permissions for EKS, VPC, IAM, EBS, S3, and RDS (covered in step 2).
- **Cloudflare** -- a domain managed in Cloudflare for DNS automation. [Create an API token](https://dash.cloudflare.com/profile/api-tokens) using the "Edit zone DNS" template, scoped to your domain's zone.
- **1Password** -- a service account with read/write access to an infrastructure vault. Create one in your 1Password admin console under Developer > Service Accounts. You need the vault **UUID** (find via `op vault list` or visible in the URL at Settings > Vaults). Also set up a **team logins vault** (can be the same vault or a separate one shared with your team) — Terraform writes browser-login items here for ArgoCD, Grafana, Prometheus, and Alertmanager so your team can log in via 1Password.

## 2. AWS credentials

**Create an IAM user** in the AWS console under IAM > Users > Create user. Attach the `AdministratorAccess` policy, or grant the minimum required permissions: EKS, VPC, IAM, S3, EBS (EKS managed node groups use EC2), and optionally RDS if you plan to use managed PostgreSQL.

**Generate access keys** under the user's Security credentials tab, or via the CLI:

```bash
aws iam create-access-key --user-name your-iam-user
```

## 3. Create a Terraform state bucket

AWS uses native S3 for Terraform state:

```bash
aws s3 mb s3://your-state-bucket --region eu-north-1
```

Pick a bucket name that is globally unique. The region should match or be close to your cluster region.

## 4. Configure environment

Build your `.env` from the split example files:

```bash
cp .env.shared.example .env
cat .env.aws.example >> .env
```

Optionally append OIDC and extras:

```bash
cat .env.oidc.example >> .env      # SSO for kubectl, Grafana, ArgoCD
cat .env.extras.example >> .env    # GHCR, GitHub token for private repos
```

Fill in the values:

- `AWS_ACCESS_KEY_ID` / `AWS_SECRET_ACCESS_KEY` -- IAM user access keys (from step 2)
- `TF_VAR_state_bucket` / `TF_VAR_state_region` -- state bucket name and region (from step 3)
- `TF_VAR_cloudflare_api_token`, `TF_VAR_domain`, `TF_VAR_letsencrypt_email` -- from `.env.shared.example`
- `TF_VAR_onepassword_service_account_token`, `TF_VAR_onepassword_vault_id` -- from `.env.shared.example`

Then source:

```bash
source .env
```

Never commit `.env` to git. Run the `cp`/`cat` steps once. Delete `.env` before re-running.

> The `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY` in `.env.shared.example` are used for the Terraform state backend (S3-compatible). For AWS clusters, these are the same IAM credentials — you do not need separate state-backend credentials.

## 5. Configure Terraform state

Edit `terraform/clusters/aws-starter/cluster/backend.tf` and
`terraform/clusters/aws-starter/addons/backend.tf` to point at your state bucket.

## 6. Create the cluster stage tfvars

Create `terraform/clusters/aws-starter/cluster/terraform.tfvars` from the example.

Minimum example:

```hcl
region       = "eu-north-1"
cluster_name = "aws-starter"
environment  = "production"
availability_zones = ["eu-north-1a", "eu-north-1b", "eu-north-1c"]
```

Optional managed PostgreSQL:

```hcl
database_provider = "managed"
rds_instance_class = "db.t4g.small"
rds_multi_az       = false
```

## 7. Apply the cluster stage

```bash
cd terraform/clusters/aws-starter/cluster
terraform init
terraform plan
terraform apply
```

Configure `kubectl` after apply:

```bash
aws eks update-kubeconfig --region eu-north-1 --name aws-starter
```

## 8. Create the addons stage tfvars

Create `terraform/clusters/aws-starter/addons/terraform.tfvars` from the example.

Typical values:

```hcl
state_bucket      = "your-tf-state-bucket"
state_region      = "eu-north-1"
cloud_provider    = "aws"
cluster_name      = "aws-starter"
domain            = "example.com"
letsencrypt_email = "ops@example.com"
cnpg_enabled      = true
cnpg_instances    = 3
```

Provide sensitive values through `TF_VAR_...` environment variables (already exported via `.env`).

## 9. Apply the addons stage

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
- IRSA-backed service accounts for Loki and Velero

## 10. Enable components in GitOps

Edit `clusters/aws-starter/values.yaml` and enable the components you want.

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

## 11. Verify storage classes and storage nodes

```bash
kubectl get storageclass
kubectl get nodes -L k8s-platform/pool-role
```

Expected portable aliases:

- `fast-rwo` -> `gp3` with higher IOPS / throughput
- `standard-rwo` -> baseline `gp3`

The starter cluster creates a dedicated storage node group labeled
`k8s-platform/pool-role=storage` and tainted `k8s-platform/pool-role=storage:NoSchedule`
so CNPG and other stateful workloads land on the intended nodes. See [node-pools.md](node-pools.md).

## 12. Verify ArgoCD and Grafana access

```bash
kubectl get ingress -A
kubectl get applications -n argocd
```

Expected hostnames:

- `argocd-aws-starter.example.com`
- `grafana-aws-starter.example.com`

## 13. Managed DB vs CNPG

- `database_provider = "cnpg"`: Terraform seeds the demo app’s
  `database-credentials` secret for the in-cluster CNPG cluster.
- `database_provider = "managed"`: Terraform seeds the same secret with RDS
  connection details.
- `database_provider = "external"`: keep the same secret contract, but create
  it yourself or sync it through External Secrets.
