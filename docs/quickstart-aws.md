# Quickstart: AWS (EKS)

This quickstart provisions an EKS-based starter cluster, bootstraps ArgoCD,
creates portable storage classes, and wires Cloudflare, 1Password, OIDC,
CNPG, and optional RDS.

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
cat .env.oidc.example >> .env      # SSO for Grafana and ArgoCD
cat .env.extras.example >> .env    # GHCR, GitHub token for private repos
```

For AWS, leave `TF_VAR_kubectl_oidc_client_id` and
`TF_VAR_kubectl_oidc_client_secret` empty. EKS access should use
`aws eks update-kubeconfig`, not the kubectl OIDC bootstrap path used on OVH
and Hetzner.

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
deletion_protection = false
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
- AWS-native monitoring storage integration for Loki

## 10. Enable components in GitOps

Edit `clusters/aws-starter/values.yaml` and enable the components you want.

Example:

```yaml
components:
  demoApp: true
  cnpg: true
  valkey: true
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

If you enabled `enable_storage_node_pool = true` in Stage 1, you'll also see nodes labeled
`k8s-platform/pool-role=storage` and tainted `k8s-platform/pool-role=storage:NoSchedule`.
By default, all workloads run on general nodes. See [node-pools.md](node-pools.md) for opt-in storage targeting.

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

## Teardown

Destroy in reverse order -- addons first, then cluster:

```bash
# 1. Destroy addons (ArgoCD, platform components)
terraform -chdir=terraform/clusters/aws-starter/addons destroy -auto-approve

# 2. Destroy cluster infrastructure
terraform -chdir=terraform/clusters/aws-starter/cluster destroy -auto-approve
```

> **RDS deletion protection**: If you provisioned RDS (`database_provider = "managed"`), the
> instance is protected against accidental deletion by default. Before running `terraform destroy`
> on the cluster stage, set `deletion_protection = false` in your `terraform.tfvars` and apply
> the cluster stage once to remove the protection:
>
> ```bash
> # In terraform/clusters/aws-starter/cluster/terraform.tfvars, add:
> deletion_protection = false
>
> terraform -chdir=terraform/clusters/aws-starter/cluster apply -auto-approve
> # Then destroy:
> terraform -chdir=terraform/clusters/aws-starter/cluster destroy -auto-approve
> ```

Destroy includes intentional pauses (60s for external-secrets cleanup, 180s for ArgoCD) -- expect it to take several minutes. If destroy fails with a timeout after the pauses, re-run the same command -- transient API errors are common.

If you enabled RDS deletion protection manually, set `deletion_protection = false`
and apply the cluster stage before running `terraform destroy`.

Delete stale `heritage=external-dns` TXT records and any stale `*-aws-starter`
DNS records in your Cloudflare dashboard before redeploying to the same domain.

EBS volumes created by PersistentVolumeClaims are not always removed by Terraform destroy. Check the EC2 console under Elastic Block Store > Volumes and delete any orphaned volumes tagged with your cluster name.

IAM roles and policies created by the EKS module (for IRSA) are destroyed with the cluster stage. If you attached custom policies manually, remove them before running destroy to avoid dependency errors.

The CI workflow does not include a destroy action. Run teardown locally.
