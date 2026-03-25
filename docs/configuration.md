# Configuration Reference

## Environment files

Build your `.env` from the split example files:

| File | Purpose |
|------|---------|
| `.env.shared.example` | State backend, 1Password, Cloudflare, ArgoCD — shared across clouds |
| `.env.ovh.example` | OVH API + OpenStack credentials |
| `.env.hetzner.example` | Hetzner API + SSH keys |
| `.env.aws.example` | AWS IAM credentials + region |
| `.env.gcp.example` | GCP project + region (auth via `gcloud` ADC) |
| `.env.oidc.example` | OIDC/SSO for kubectl, Grafana, ArgoCD |
| `.env.extras.example` | GHCR registry, GitHub token for private repos |

## Key variables

### State backend (`.env.shared.example`)

- `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY` — S3-compatible state bucket credentials

> `TF_VAR_state_bucket`, `TF_VAR_state_region`, and `TF_VAR_state_endpoint` are **not** used by `terraform init`. The backend is configured by editing the `backend.tf` file in each cluster directory — update the bucket, key, and endpoint to match your state bucket. These three variables are passed to the addons stage so the `data "terraform_remote_state"` block can read cluster outputs from the correct bucket.

- `TF_VAR_state_bucket` — bucket name
- `TF_VAR_state_region` — S3 bucket location code: `gra` for OVH, `fsn1` for Hetzner. Bucket region, not cluster region (e.g. `gra`, not `GRA9`).
- `TF_VAR_state_endpoint` — full URL (e.g. `https://s3.gra.io.cloud.ovh.net`)

### 1Password

- `TF_VAR_onepassword_service_account_token` — service account token
- `TF_VAR_onepassword_vault_id` — vault UUID (find via `op vault list` or in 1Password at Settings > Vaults)

`OP_SERVICE_ACCOUNT_TOKEN` is auto-aliased from `TF_VAR_onepassword_service_account_token`; set the value once.

### Bootstrap

- `TF_VAR_cloudflare_api_token` — Cloudflare API token with DNS edit permissions
- `TF_VAR_domain` — your domain (e.g. `example.com`)
- `TF_VAR_letsencrypt_email` — email for Let's Encrypt notifications
- `TF_VAR_argocd_repo_url` — your fork URL
- `TF_VAR_argocd_target_revision` — Git branch or tag ArgoCD tracks. Defaults to `main`.
- `TF_VAR_cloud_provider` — required by the addons stage. Set to `ovh`, `hetzner`, `aws`, or `gcp` to match your cluster.

### Common infrastructure toggles

Use the same Stage 1 variable names on every cloud:

- `create_backup_bucket` — provision object storage for Loki and CNPG backups
- `enable_storage_node_pool` — add a dedicated node pool for stateful workloads

Cloud-specific Terraform modules can still differ behind the scenes, but these are the user-facing knobs across OVH, Hetzner, AWS, and GCP.

### Team logins vault

`TF_VAR_onepassword_team_logins_vault_id` controls where Terraform writes browser-login items for ArgoCD, Grafana, Prometheus, and Alertmanager. With OIDC enabled, items move to the infra vault as break-glass access; with OIDC disabled, they stay in the team logins vault as the primary login method.

Set this to the same vault as your infra vault, or a separate vault shared with your team. Without it, browser-login items are not created and break-glass credentials come only from Terraform outputs (not available in CI deploys).

## OIDC timing

Configure OIDC before the first cluster apply if using SSO. On Hetzner, OIDC flags are baked into k3s at install time and cannot be changed later. See [oidc.md](oidc.md).

## CI credential mapping

See [ci.md](ci.md#credential-mapping) for GitHub Actions credential mapping per cloud. Secret values map to GitHub **secrets**; non-secret values (cluster name, domain, region) map to GitHub **variables**.

## Common follow-ups

- Private Git repo for ArgoCD: [argocd-guide.md](argocd-guide.md#private-git-repositories)
- Private images or GHCR pulls: [container-registry.md](container-registry.md)
- Access and browser-login items: [credential-flow.md](credential-flow.md)
