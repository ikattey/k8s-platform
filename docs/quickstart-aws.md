# Quickstart: AWS (EKS)

This quickstart provisions an EKS-based starter cluster, bootstraps ArgoCD,
creates portable storage classes, and wires Cloudflare, 1Password, OIDC,
CNPG, optional RDS, and optional Velero data movement.

## 1. Prerequisites

You need:

- an AWS account with permissions for EKS, VPC, IAM, EBS, S3, and RDS
- AWS CLI credentials for the target account
- a Cloudflare zone and API token
- a 1Password service-account token and infra vault
- Terraform 1.14+

## 2. Configure Terraform state

Edit `terraform/clusters/aws-starter/cluster/backend.tf` and
`terraform/clusters/aws-starter/addons/backend.tf` to point at your state bucket.

## 3. Create the cluster stage tfvars

Create `terraform/clusters/aws-starter/cluster/terraform.tfvars` from the example.

Minimum example:

```hcl
region       = "eu-west-1"
cluster_name = "aws-starter"
environment  = "production"
availability_zones = ["eu-west-1a", "eu-west-1b", "eu-west-1c"]
```

Optional managed PostgreSQL:

```hcl
database_provider = "managed"
rds_instance_class = "db.t4g.small"
rds_multi_az       = false
```

## 4. Apply the cluster stage

```bash
cd terraform/clusters/aws-starter/cluster
terraform init
terraform plan
terraform apply
```

Configure `kubectl` after apply:

```bash
aws eks update-kubeconfig   --region eu-west-1   --name aws-starter
```

## 5. Create the addons stage tfvars

Create `terraform/clusters/aws-starter/addons/terraform.tfvars` from the example.

Typical values:

```hcl
state_bucket      = "your-tf-state-bucket"
state_region      = "eu-west-1"
cloud_provider    = "aws"
cluster_name      = "aws-starter"
domain            = "example.com"
letsencrypt_email = "ops@example.com"
cnpg_enabled      = true
cnpg_instances    = 3
```

Provide sensitive values through `TF_VAR_...` environment variables.

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
- IRSA-backed service accounts for Loki and Velero

## 7. Enable components in GitOps

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

## 8. Verify storage classes and storage nodes

```bash
kubectl get storageclass
kubectl get nodes -L server-usage
```

Expected portable aliases:

- `fast-rwo` -> `gp3` with higher IOPS / throughput
- `standard-rwo` -> baseline `gp3`

The starter cluster creates a dedicated storage node group labeled
`server-usage=storage` and tainted `storage=true:NoSchedule` so CNPG and other
stateful workloads land on the intended nodes.

## 9. Verify ArgoCD and Grafana access

```bash
kubectl get ingress -A
kubectl get applications -n argocd
```

Expected hostnames:

- `argocd-aws-starter.example.com`
- `grafana-aws-starter.example.com`

## 10. Managed DB vs CNPG

- `database_provider = "cnpg"`: Terraform seeds the demo app’s
  `database-credentials` secret for the in-cluster CNPG cluster.
- `database_provider = "managed"`: Terraform seeds the same secret with RDS
  connection details.
- `database_provider = "external"`: keep the same secret contract, but create
  it yourself or sync it through External Secrets.
