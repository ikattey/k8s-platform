# Security

> **Default posture**: The starter defaults allow unrestricted API server access to simplify initial setup. Before production use, restrict access using the cloud-specific settings below.

This document covers the security features built into the k8s-starter-kit platform.

## API Server Access Restriction

Each cloud provider offers a way to restrict access to the Kubernetes API server:

### AWS EKS

```hcl
# terraform/clusters/aws-starter/cluster/terraform.tfvars
cluster_endpoint_public_access       = true
cluster_endpoint_private_access      = true
cluster_endpoint_public_access_cidrs = ["203.0.113.0/24"]  # Your office/VPN CIDR
```

### GCP GKE

```hcl
# terraform/clusters/gcp-starter/cluster/terraform.tfvars
master_authorized_cidr_blocks = [
  {
    cidr_block   = "203.0.113.0/24"
    display_name = "Office"
  }
]
```

### Hetzner (kube-hetzner)

The kube-hetzner module manages firewall rules. Add API server restrictions via `extra_firewall_rules` in the cluster variables.

### OVH

```hcl
# terraform/clusters/ovh-starter/cluster/terraform.tfvars
api_server_ip_restrictions = ["203.0.113.0/24"]
```

## Pod Security Standards

The platform does not enforce Pod Security Standards by default. To apply the `baseline` level to a namespace, add the following label:

```yaml
pod-security.kubernetes.io/enforce: baseline
```

This prevents common privilege escalation vectors including privileged containers, host namespace sharing, and host path mounts. Apply to any namespace where you deploy application workloads:

```bash
kubectl label namespace demo pod-security.kubernetes.io/enforce=baseline
```

## Network Policies

All four clouds support Kubernetes NetworkPolicy enforcement:

| Cloud | CNI | How Enforcement Works |
|-------|-----|----------------------|
| AWS EKS | VPC CNI | Native NetworkPolicy via `ENABLE_NETWORK_POLICY = "true"` env flag on the VPC CNI addon |
| GCP GKE | Dataplane V2 (eBPF) | Built-in via `datapath_provider = "ADVANCED_DATAPATH"` on the cluster |
| Hetzner | Cilium (k3s) | Built-in, no configuration needed |
| OVH | Cilium | Built-in, no configuration needed |

Example deny-all policy for a namespace:

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: deny-all
  namespace: demo
spec:
  podSelector: {}
  policyTypes:
    - Ingress
    - Egress
```

## Audit Logging

| Cloud | Implementation | Notes |
|-------|---------------|-------|
| AWS EKS | CloudWatch (opt-in) | Set `enable_cloudwatch_logging = true` to enable all 5 log types (api, audit, authenticator, controllerManager, scheduler). Off by default to avoid cost. EKS control plane logs are only available via CloudWatch — Loki captures pod/node logs only. |
| GCP GKE | Cloud Audit Logs | Always on by default, no configuration required |
| Hetzner | k3s audit log | Control plane logs are on the nodes. Configure via k3s extra args |
| OVH | OVH managed logging | Available via OVH control panel |

## Secrets Management

The platform uses a zero-trust approach to secrets:

1. **Secret Zero**: A single 1Password service account token bootstrapped via Terraform
2. **External Secrets Operator (ESO)**: Syncs secrets from 1Password to Kubernetes
3. **No secrets in git**: All sensitive values flow through 1Password → ESO → K8s Secrets

See [quickstart guides](quickstart-hetzner.md) for the bootstrap process.
