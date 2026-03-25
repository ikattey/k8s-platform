# Kubernetes Platform Starter Kit

Terraform + ArgoCD starter kit for production Kubernetes. Fork this repo, follow the quickstart for your cloud, and run the two-stage bootstrap to get a platform with DNS, TLS, secrets, monitoring, and GitOps configured.

[![Terraform Plan](https://github.com/masena-dev/k8s-platform/actions/workflows/terraform-plan.yml/badge.svg)](https://github.com/masena-dev/k8s-platform/actions/workflows/terraform-plan.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

## Supported clouds

| Cloud | Cluster type | Quickstart |
|-------|-------------|------------|
| **OVH Cloud** | Managed Kubernetes (OVH handles the control plane) | [quickstart-ovh.md](docs/quickstart-ovh.md) |
| **Hetzner Cloud** | Self-managed k3s via [kube-hetzner](https://github.com/mysticaltech/terraform-hcloud-kube-hetzner) | [quickstart-hetzner.md](docs/quickstart-hetzner.md) |
| **GCP GKE** | GKE managed Kubernetes | [quickstart-gcp.md](docs/quickstart-gcp.md) |
| **AWS EKS** | EKS managed Kubernetes | [quickstart-aws.md](docs/quickstart-aws.md) |

> **Note**: The Hetzner quickstart defaults to ARM (`cax21`) nodes. Switch to `ccx*` or `cpx*` before running `terraform apply` if your workloads require x86.

## What you get

- **Automated DNS and TLS** — Traefik + cert-manager + external-dns via Cloudflare. Deploy a service with an Ingress and it gets a valid HTTPS certificate and DNS record automatically.
- **Monitoring and logging** — Grafana, Prometheus, and Loki (with S3 backend), plus pre-configured alerts.
- **Secret management via 1Password** — External Secrets Operator syncs secrets from 1Password into Kubernetes. See [credential-flow.md](docs/credential-flow.md).
- **GitOps** — ArgoCD polls your fork and syncs the cluster state via the app-of-apps pattern.
- **Demo app** — verifies ingress, DNS, and TLS end-to-end. When data-layer components are enabled, shows a health status for each: postgres-write, postgres-read, valkey, typesense, and nats. Multi-arch (amd64 + arm64), no imagePullSecrets needed.

An optional data layer (CloudNativePG, Valkey, Typesense, NATS) is included but disabled by default. See [customization.md](docs/customization.md).

## Architecture decisions

- **Cloudflare for DNS** — hardcoded into `external-dns` and `cert-manager` to eliminate manual DNS records. This is a hard dependency.
- **1Password for secrets** — Stage 2 writes bootstrap credentials into 1Password, and ESO reads them back. One store handles human logins and cluster secrets without requiring a separate secrets infrastructure like Vault.
- **S3 state backend** — keeps state cloud-agnostic without provider-specific extras like DynamoDB. Note: OVH and Hetzner S3 do not support state locking (`use_lockfile = false`). Do not run concurrent Terraform applies against the same cluster — without locking, simultaneous applies can corrupt state.
- **ArgoCD over Flux** — Stage 2 installs ArgoCD and creates a single root Application to fan out platform components via sync waves.

## How it works

```
Stage 1 (Terraform)          Stage 2 (Terraform)          Steady state
┌─────────────────────┐      ┌─────────────────────┐      ┌─────────────────────┐
│ Cluster             │      │ ArgoCD              │      │ Git commit          │
│ Node pools          │ ──▶  │ Secret-zero         │ ──▶  │ ArgoCD polls        │
│ Object storage      │      │ Bootstrap secrets   │      │ Platform updates    │
│ Network             │      │                     │      │                     │
└─────────────────────┘      └─────────────────────┘      └─────────────────────┘
```

Stage 1 provisions the cloud infrastructure. Stage 2 bootstraps ArgoCD with a 1Password service account token (the "secret-zero") and creates the initial bootstrap secrets. ArgoCD then syncs the remaining platform components from your fork.

## Getting started

Fork this repo, then follow your cloud's quickstart. ArgoCD connects to your fork as part of Stage 2.

- **[OVH Cloud quickstart](docs/quickstart-ovh.md)**
- **[Hetzner Cloud quickstart](docs/quickstart-hetzner.md)**
- **[AWS quickstart](docs/quickstart-aws.md)**
- **[GCP quickstart](docs/quickstart-gcp.md)**

Each guide covers accounts, credentials, configuration, and deployment.

### Prerequisites

**Accounts:**

- A cloud provider account (Hetzner, OVH, GCP, or AWS)
- **Cloudflare** — a domain managed in Cloudflare for DNS automation
- **1Password** — a service account with an infrastructure vault
- **S3-compatible bucket** — for Terraform state (each quickstart covers which backend to use)

**Tools:**

```
terraform   ~> 1.14
kubectl
helm
aws CLI     (S3-compatible state backends — works with any S3 provider)
packer      (Hetzner only — MicroOS node images)
hcloud CLI  (Hetzner only)
```

## Repo layout

```
terraform/
  clusters/
    ovh-starter/
      cluster/     # Stage 1: cloud resources + Kubernetes cluster
      addons/      # Stage 2: ArgoCD + secret-zero bootstrap
    hetzner-starter/
      cluster/     # Stage 1: kube-hetzner + object storage
      addons/      # Stage 2: ArgoCD + secret-zero bootstrap
  modules/         # Shared Terraform modules (ArgoCD bootstrap, Cloud SQL, etc.)
  platforms/       # Per-cloud resource definitions (node groups, networking, storage)

argocd/            # Root App-of-Apps Helm chart
clusters/          # Per-cluster GitOps overlays (values.yaml)
values/            # Helm values per component
demo-app/          # Minimal Go app that verifies the full stack
docs/              # Setup guides, reference, troubleshooting
```

## Documentation

| Topic | Guide |
|-------|-------|
| OVH deployment | [quickstart-ovh.md](docs/quickstart-ovh.md) |
| Hetzner deployment | [quickstart-hetzner.md](docs/quickstart-hetzner.md) |
| GCP deployment | [quickstart-gcp.md](docs/quickstart-gcp.md) |
| AWS deployment | [quickstart-aws.md](docs/quickstart-aws.md) |
| CI workflows | [ci.md](docs/ci.md) |
| Environment and variables | [configuration.md](docs/configuration.md) |
| OIDC / SSO | [oidc.md](docs/oidc.md) |
| Monitoring | [monitoring.md](docs/monitoring.md) |
| Secrets and 1Password | [credential-flow.md](docs/credential-flow.md) |
| Enabling/disabling components | [customization.md](docs/customization.md) |
| ArgoCD and private repos | [argocd-guide.md](docs/argocd-guide.md) |
| CNPG backups | [backups.md](docs/backups.md) |
| Private images (GHCR) | [container-registry.md](docs/container-registry.md) |
| Troubleshooting | [troubleshooting.md](docs/troubleshooting.md) |

## CI

Pull requests run `terraform validate` and `helm lint` automatically. The manual dispatch workflow handles `plan` and `apply` for OVH and Hetzner. See [ci.md](docs/ci.md).

## License

MIT. See [LICENSE](LICENSE).
