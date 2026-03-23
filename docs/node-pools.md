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
| OVH | Not supported | — |

OVH's `ovh_cloud_project_kube_nodepool` resource does not support labels or taints (as of provider v2.11.0). All workloads on OVH clusters run on general-purpose nodes.

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

**OVH** — No dedicated pool support. All workloads share general-purpose nodes.

## Component-specific guidance

### CNPG (PostgreSQL)

Pin to storage nodes when you want I/O isolation for database workloads. On Hetzner, this also gives local NVMe performance via `fast-rwo`.

For HA, run at least 3 storage nodes so CNPG can spread replicas across nodes (pod anti-affinity). With fewer than 3, some replicas co-locate, reducing fault tolerance.

### Typesense

Typesense uses Raft consensus with persistent data directories. Pin to storage nodes to reduce pod churn affecting the Raft data set, especially on Hetzner where `fast-rwo` gives real NVMe performance for search indexes.

### NATS

NATS JetStream uses persistent file storage for stream data. Pin to storage nodes for isolation. On Hetzner, NATS can use the default storage class (network-attached) even on storage nodes — JetStream doesn't need NVMe-level IOPS for most workloads.

### Dragonfly

Dragonfly is an ephemeral in-memory cache. It stays on general-purpose nodes — there's no persistence benefit from dedicated storage nodes.

## Extending to other pool roles

The convention is extensible. Future pool roles follow the same pattern:

```
k8s-platform/pool-role=gpu
k8s-platform/pool-role=compute
```

Not currently implemented — add the label+taint to new node pools and matching overlays as needed.
