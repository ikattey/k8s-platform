# Node Pool Targeting

## Convention

The platform uses a single label+taint key for all pool-role-based scheduling:

```
Label:  k8s-platform/pool-role=storage
Taint:  k8s-platform/pool-role=storage:NoSchedule
```

Same key for both — tolerations always mirror `nodeSelector`. Workloads that set `nodeSelector` must also set the matching toleration, or pods stay Pending.

## Enabling storage nodes

| Cloud | Variable | Where |
|-------|----------|-------|
| Hetzner | `enable_storage_nodes = true` | `terraform/clusters/<cluster>/cluster/terraform.tfvars` |
| AWS | `storage_enabled = true` | `terraform/clusters/<cluster>/cluster/terraform.tfvars` |
| GCP | `enable_storage_node_pool = true` | `terraform/clusters/<cluster>/cluster/terraform.tfvars` |
| OVH | `enable_storage_pool = true` | `terraform/clusters/<cluster>/cluster/terraform.tfvars` |

## How workloads target pools

Node targeting is set in per-cluster overlay files under `clusters/<cluster>/`:

| Component | Overlay file | Key path |
|-----------|-------------|----------|
| CNPG | `cnpg-values.yaml` | `cluster.nodeSelector`, `cluster.tolerations` |
| Typesense | `typesense-values.yaml` | `typesense.nodeSelector`, `typesense.tolerations` |
| NATS | `nats-values.yaml` | `nats.nodeSelector`, `nats.tolerations` |

Example (any component):

```yaml
# clusters/<cluster>/typesense-values.yaml
typesense:
  nodeSelector:
    k8s-platform/pool-role: storage
  tolerations:
    - key: k8s-platform/pool-role
      operator: Equal
      value: storage
      effect: NoSchedule
```

To remove pool targeting, empty the per-cluster file. The component schedules on any node using the default storage class.

## Per-cloud tradeoffs

**Hetzner** — Storage nodes use local NVMe via Longhorn. `fast-rwo` maps to real local disk with ~5000+ IOPS. This is where dedicated nodes give a genuine I/O advantage.

**AWS / GCP** — Storage nodes use network-attached volumes (EBS gp3, PD-SSD). The IOPS gain over general nodes is minimal since both use the same backing storage. The benefit is workload isolation — database pods don't compete with application pods for CPU/memory.

**OVH** — Storage nodes use network-attached volumes. Like AWS/GCP, the benefit is workload isolation rather than I/O performance.

## Component-specific guidance

### CNPG (PostgreSQL)

Optional. Pin to storage nodes for I/O isolation when running production database workloads. On Hetzner, this also gives local NVMe performance via `fast-rwo`. By default, CNPG runs on general nodes with the cluster default storage class.

For HA with dedicated storage, run at least 3 storage nodes so CNPG can spread replicas across nodes (pod anti-affinity).

### Typesense

Optional. Runs well on general-purpose nodes with default storage. Pin to storage nodes only if you need workload isolation from application pods.

### NATS

Optional. Runs well on general-purpose nodes. JetStream persistence is modest — it doesn't need NVMe-level IOPS for most workloads.

### Valkey

Not recommended. Valkey is an in-memory cache — there's no persistence benefit from dedicated storage nodes.

## Extending to other pool roles

The convention is extensible. Future pool roles follow the same pattern:

```
k8s-platform/pool-role=gpu
k8s-platform/pool-role=compute
```

Not currently implemented — add the label+taint to new node pools and matching overlays as needed.
