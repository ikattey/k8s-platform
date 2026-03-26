# Customization

## Where to change things

- `argocd/values.yaml`: shared defaults
- `clusters/<cluster>/values.yaml`: per-cluster overrides, including `components:` flags
- `clusters/<cluster>/cnpg-values.yaml`: per-cluster CNPG overrides (database name, storage size, replicas, backup schedule, pooler settings, node targeting)
- `clusters/<cluster>/typesense-values.yaml`: per-cluster Typesense overrides (storage class, node targeting)
- `clusters/<cluster>/nats-values.yaml`: per-cluster NATS overrides (storage class, node targeting)
- `values/<component>/values.yaml`: component-specific Helm values
- `values/<component>/values-<cloud>.yaml`: cloud-specific component overrides
- `terraform/clusters/<cluster>/cluster/terraform.tfvars`: cloud and cluster infrastructure
- `terraform/clusters/<cluster>/addons/terraform.tfvars`: ArgoCD bootstrap inputs

The demo app does not use per-cluster values files. Its ingress, TLS, cluster issuer, and data-layer flags are injected by the ArgoCD template from `clusters/<cluster>/values.yaml` via `components:` flags. There is no `demo-app-values.yaml` per cluster.

Data-layer services are opt-in on every cloud. The starter defaults to `demoApp: true` and keeps `cnpg`, `valkey`, `nats`, and `typesense` disabled until you explicitly enable and configure them.

## Component toggles

Current toggles live under `components:` in `argocd/values.yaml`:

- `certManager`
- `externalSecrets`
- `platformSecrets`
- `bootstrapSecrets`
- `traefik`
- `externalDns`
- `monitoring`
- `grafanaOAuth`
- `monitoringMiddleware`
- `argocdIngress`
- `demoApp`
- `cnpg`
- `valkey`
- `typesense`
- `nats`
- `platformAlerts`

Example:

```yaml
components:
  demoApp: false
  cnpg: true
```

## Versions

Pinned chart versions also live in `argocd/values.yaml`.

Change a version there, commit, and let ArgoCD reconcile it.

## Common changes

### Change the cluster issuer

```yaml
# clusters/<cluster>/values.yaml
clusterIssuer: "letsencrypt-production"
```

### Enable or disable the demo app

```yaml
components:
  demoApp: true
```

When enabled, the demo app checks health for all five data-layer services (postgres-write, postgres-read, valkey, typesense, nats). A service only appears in the health check when its corresponding `components:` flag is true. The image is multi-arch (amd64 + arm64) and hosted publicly — no `imagePullSecrets` are needed.

### Enable CNPG

Set `cnpg: true` in `clusters/<cluster>/values.yaml` and `cnpg_enabled = true` in your addons `terraform.tfvars`:

```yaml
# clusters/<cluster>/values.yaml
components:
  cnpg: true
```

```hcl
# terraform/clusters/<cluster>/addons/terraform.tfvars
cnpg_enabled = true
```

CNPG backups require object storage. Set `create_backup_bucket = true` in your cluster `terraform.tfvars` if it isn't already. See [backups.md](backups.md) for backup configuration.

CNPG uses the cluster's default storage class. For higher I/O performance, opt in to `fast-rwo` in your per-cluster `cnpg-values.yaml` — see [Storage classes](#storage-classes) below. On Hetzner, the storage-class aliases are enabled by default in the addons stage; use `enable_storage_class_aliases = false` only if you explicitly want to opt out.

### NATS authentication

NATS ships with auth disabled by default for simplicity. For production, enable token auth and provide the token via ESO:

```yaml
# values/nats/values.yaml (or a per-cluster override)
nats:
  auth:
    enabled: true
    tokenSecretRef:
      name: nats-auth-token
      key: token
```

Add this to `clusters/<cluster>/bootstrap-secrets.yaml`:

```yaml
secrets:
  natsAuthToken:
    enabled: true
    onepasswordItem: "nats-auth-<cluster>"
```

Create the matching 1Password item with a `token` field, and ESO will sync it to `messaging/nats-auth-token`.

### Typesense admin key

Typesense requires an admin key. The starter now fails fast if the chart is still using the placeholder value.

For the 1Password/ESO path, disable the inline Secret and add this to `clusters/<cluster>/typesense-values.yaml`:

```yaml
typesense:
  auth:
    createSecret: false
```

Then add this to `clusters/<cluster>/bootstrap-secrets.yaml`:

```yaml
secrets:
  typesenseAdminKey:
    enabled: true
    onepasswordItem: "typesense-admin-<cluster>"
```

Create the matching 1Password item with an `api_key` field, and ESO will sync it to `search/typesense-admin-key`.

### Typesense version

Typesense is pinned to **v29.0**. v30.1 has a known segfault on x86_64 — do not upgrade to v30.x until an upstream fix is confirmed. To upgrade, update `typesense.image` in `values/typesense/values.yaml`:

```yaml
typesense:
  image: typesense/typesense:29.0
```

Check the [Typesense changelog](https://typesense.org/docs/guide/updating-typesense.html) before bumping versions.

### External-DNS ownership and domain scope

`txtOwnerId` and `domainFilters` are injected automatically per cluster by the ArgoCD template:

- `txtOwnerId` defaults to `k8s-platform-<clusterName>` — prevents DNS record conflicts when multiple clusters share the same Cloudflare account.
- `externalDns.txtOwnerId` can override that default for clusters that must adopt pre-existing TXT ownership.
- `domainFilters` is scoped to `<domain>` from your cluster values — prevents one cluster from deleting DNS records owned by another cluster.

These are not set in `values/external-dns/values.yaml`. Do not add them there; they are always overridden by the template.

### Change Traefik or monitoring values

Edit the component values directly:

- `values/traefik/values.yaml`
- `values/kube-prometheus-stack/values.yaml`
- `values/loki/values.yaml`

Example: Traefik replica count belongs under `deployment.replicas`, not a
top-level `replicas` key.

## Adding an application

### From this repo (monorepo pattern)

1. Create a Helm chart or Kustomize overlay under `values/<your-app>/`
2. Add an ArgoCD Application in `argocd/templates/applications.yaml`:

   ```yaml
   apiVersion: argoproj.io/v1alpha1
   kind: Application
   metadata:
     name: my-app
     namespace: argocd
     annotations:
       argocd.argoproj.io/sync-wave: "3"
   spec:
     project: apps
     sources:
       - repoURL: {{ "{{ .Values.repoURL }}" }}
         targetRevision: {{ "{{ .Values.targetRevision }}" }}
         path: values/my-app
     destination:
       server: https://kubernetes.default.svc
       namespace: my-app
     syncPolicy:
       automated:
         prune: true
         selfHeal: true
       syncOptions:
         - CreateNamespace=true
   ```

3. Commit and push — ArgoCD syncs automatically.

### From a separate repo (multi-repo pattern)

```yaml
spec:
  project: apps
  source:
    repoURL: https://github.com/your-org/your-app
    targetRevision: main
    path: k8s/overlays/production
  destination:
    server: https://kubernetes.default.svc
    namespace: my-app
```

If the repo is private, set `github_token` in the addons stage. See
[argocd-guide.md](argocd-guide.md#private-git-repositories).

- For private images: [container-registry.md](container-registry.md)
- `values/demo-app/` provides ingress, TLS, health checks, and database credential injection patterns

## Changing cluster infrastructure

Edit the cluster-stage `terraform.tfvars`, then apply Stage 1 again:

```bash
terraform -chdir=terraform/clusters/$CLUSTER/cluster apply
```

Typical examples:

- OVH node flavor or autoscaling limits
- Hetzner server type or node counts
- enabling a storage node pool
- enabling managed PostgreSQL on AWS, GCP, or OVH

## Database contract

The cluster stage exports `database_host`, `database_port`, `database_name`, `database_username`, `database_password`. The addons stage turns those into the bootstrap secret contract consumed by the demo app and related workloads.

## Database options

| Option | Provider | Managed by | Best for |
|--------|----------|------------|----------|
| Managed PostgreSQL | AWS / GCP / OVH | AWS RDS / Cloud SQL / OVH | Operational simplicity, cloud-managed HA and backups |
| External PostgreSQL | Any cloud | You | Reusing an existing database service |
| CNPG | Any cloud | You (via operator) | Full control, lower cost, multi-cloud portability |

**Managed PostgreSQL** — set `database_provider = "managed"` in cluster
`terraform.tfvars`. AWS provisions RDS, GCP provisions Cloud SQL, and OVH
provisions OVH managed PostgreSQL. Hetzner does not ship a managed database
module in this starter; use `database_provider = "external"` there.

**CNPG** — set `cnpg: true` in `clusters/<cluster>/values.yaml` and configure
backups. See [backups.md](backups.md) for backup/restore/tuning.

## Connection pooling

The CNPG chart deploys a PgBouncer pooler by default in transaction mode (`values/cnpg/cluster/values.yaml`):

```yaml
pooler:
  enabled: true
  type: rw
  instances: 2
  pgbouncer:
    poolMode: transaction
    parameters:
      max_client_conn: "1000"
      default_pool_size: "20"
```

Applications connect through the pooler service instead of the cluster service directly. Find the service name:

```bash
kubectl get svc -n database -l cnpg.io/poolerName
```

PgBouncer maintains a pool of `default_pool_size` backend connections per database/user combination, shared across up to `max_client_conn` application connections.

### When to adjust

- **High connection count**: increase `max_client_conn` and add pooler instances
- **Long transactions or prepared statements**: switch `poolMode` to `session` (disables connection sharing)
- **Read-heavy workloads with replicas**: a read-only pooler (`pooler-ro.yaml`) is already included in `values/cnpg/cluster/templates/` and activates automatically when `cluster.instances > 1` — no extra manifest needed

### Disabling the pooler

```yaml
pooler:
  enabled: false
```

Applications then connect directly to the CNPG cluster service.

## Storage class abstraction

Components use the cluster default storage class. On Hetzner with dedicated nodes, the addons stage can create portable aliases for tiered storage:

| Alias | Backing | Use case |
|-------|---------|----------|
| `fast-rwo` | Longhorn (local NVMe) | PostgreSQL, search indexes |
| `standard-rwo` | Hetzner CSI (network) | Message queues, general workloads |

Enable in the cluster stage `terraform.tfvars`:

```hcl
enable_storage_node_pool = true    # Longhorn needs dedicated nodes
```

Enable in the addons stage `terraform.tfvars` only if you want to override the
Hetzner default:

```hcl
enable_storage_class_aliases = true   # Optional; true by default on Hetzner
longhorn_replica_count       = 2    # Match your storage_node_count for redundancy
```

Then opt in to fast storage in per-cluster overlays:

```yaml
# clusters/<cluster>/cnpg-values.yaml (uncomment to enable)
# cluster:
#   storage:
#     storageClass: fast-rwo
#   walStorage:
#     storageClass: fast-rwo
```

Aliases work across all clouds. On Hetzner with dedicated storage nodes, `fast-rwo` maps to Longhorn (local NVMe) and `standard-rwo` maps to Hetzner CSI. On AWS/GCP, aliases are always available.

## Running workloads on dedicated storage nodes

All clouds use the `k8s-platform/pool-role` label and taint to isolate stateful workloads on dedicated storage node pools:

```
Label:  k8s-platform/pool-role=storage
Taint:  k8s-platform/pool-role=storage:NoSchedule
```

Workload targeting is configured in per-cluster overlay files, not cloud-level overlays. By default, all data layer components run on general nodes. To pin CNPG to storage nodes:

```yaml
# clusters/<cluster>/cnpg-values.yaml (uncomment to enable)
# cluster:
#   storage:
#     storageClass: fast-rwo
#   walStorage:
#     storageClass: fast-rwo
#   nodeSelector:
#     k8s-platform/pool-role: storage
#   tolerations:
#     - key: k8s-platform/pool-role
#       operator: Equal
#       value: storage
#       effect: NoSchedule
```

Both `nodeSelector` and `tolerations` are required — storage nodes are tainted. The same pattern applies to Typesense and NATS if needed.

See [node-pools.md](node-pools.md) for full details on the convention, per-cloud tradeoffs, and component-specific guidance.

## Hetzner firewall rules

Hetzner clusters restrict outbound traffic to DNS (53), HTTP/HTTPS (80, 443), NTP (123), and ICMP. To open additional ports:

```hcl
extra_firewall_rules = [
  {
    direction       = "out"
    port            = "587"
    protocol        = "tcp"
    source_ips      = []
    destination_ips = ["0.0.0.0/0", "::/0"]
    description     = "Allow outbound SMTP for email services"
  }
]
```

Common ports you may need:

| Port | Protocol | Use case |
|------|----------|----------|
| 587 | TCP | SMTP submission (email sending) |
| 5432 | TCP | PostgreSQL (external database) |
| 6379 | TCP | Redis (external cache) |
| 9093 | TCP | Alertmanager webhook receivers |

## Resource requests and limits

CPU limits are set on high-throughput components (Traefik, Prometheus, Grafana, Loki, Alloy) and omitted on lightweight services (AlertManager, cert-manager, external-dns, external-secrets) to avoid throttling.

Override resources in the component's values file:

```yaml
# values/<component>/values.yaml
resources:
  requests:
    cpu: 200m
    memory: 256Mi
  limits:
    memory: 512Mi
```

For CNPG PostgreSQL, resources are in `values/cnpg/cluster/values.yaml` under `cluster.resources`. PostgreSQL parameters are auto-tuned from memory limits — increase `limits.memory` to get larger shared_buffers and effective_cache_size automatically.

### Defaults

| Component | CPU req | Mem req | CPU limit | Mem limit | Values file |
|-----------|---------|---------|-----------|-----------|-------------|
| Traefik | 100m | 128Mi | 500m | 256Mi | `values/traefik/` |
| Prometheus | 200m | 512Mi | 1000m | 2Gi | `values/kube-prometheus-stack/` |
| Grafana | 100m | 256Mi | 500m | 512Mi | `values/kube-prometheus-stack/` |
| AlertManager | 50m | 64Mi | — | 128Mi | `values/kube-prometheus-stack/` |
| Loki (gateway) | 50m | 64Mi | 200m | 128Mi | `values/loki/` |
| Loki (single) | 150m | 384Mi | 750m | 768Mi | `values/loki/` |
| Alloy | 100m | 128Mi | 200m | 256Mi | `values/alloy/` |
| CNPG Operator | 100m | 128Mi | — | 256Mi | `values/cnpg/operator/` |
| CNPG PostgreSQL | 500m | 1Gi | — | 2Gi | `values/cnpg/cluster/` |
| Cert-Manager | 50m | 64Mi | — | 128Mi | `values/cert-manager/` |
| External DNS | 25m | 32Mi | — | 128Mi | `values/external-dns/` |
| External Secrets | 25m | 128Mi | — | 256Mi | `values/external-secrets/` |
| Demo App | 10m | 32Mi | — | 64Mi | `values/demo-app/` |
