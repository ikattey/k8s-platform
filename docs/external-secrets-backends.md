# Using a different secrets backend

The starter kit ships with [1Password](https://1password.com/) as the default ESO backend. If you use a different secret manager, you can swap the backend without changing anything else — the ExternalSecret resources, refresh intervals, and secret-to-namespace mapping stay the same.

The only things you change are:

1. **The ClusterSecretStore** — point it at your backend instead of 1Password
2. **The authentication secret** — provide credentials for your backend
3. **The `remoteRef` format** — each backend has its own key/property syntax

Everything below assumes ESO is already installed (the starter kit handles this via ArgoCD).

## Architecture

```
┌──────────────────┐     ┌────────────────────┐     ┌──────────────────┐
│  Secret Manager  │◄────│  ClusterSecretStore │◄────│  ExternalSecret  │
│  (1Password,     │     │  (one per cluster)  │     │  (one per secret)│
│   AWS SM, Vault) │     └────────────────────┘     └──────────────────┘
└──────────────────┘              │                          │
                                 │                          ▼
                          authenticates             creates/updates
                          via token/role            Kubernetes Secret
```

The starter kit defines ExternalSecrets in `values/bootstrap-secrets/`. They reference a ClusterSecretStore by name (`onepassword` by default). To switch backends, you replace the ClusterSecretStore and update the `remoteRef` paths in your per-cluster values.

## AWS Secrets Manager

### ClusterSecretStore

Replace `values/platform-secrets/templates/cluster-secret-store.yaml`:

```yaml
apiVersion: external-secrets.io/v1
kind: ClusterSecretStore
metadata:
  name: aws-secrets-manager
spec:
  provider:
    aws:
      service: SecretsManager
      region: eu-west-1  # your region
      auth:
        jwt:
          serviceAccountRef:
            name: external-secrets
            namespace: external-secrets
```

Authentication uses IRSA (IAM Roles for Service Accounts). The ESO service account needs `secretsmanager:GetSecretValue` and `secretsmanager:ListSecrets` permissions.

### Terraform setup

Instead of writing secrets to 1Password, write them to AWS Secrets Manager:

```hcl
resource "aws_secretsmanager_secret" "grafana_admin" {
  name = "grafana-${var.cluster_name}"
}

resource "aws_secretsmanager_secret_version" "grafana_admin" {
  secret_id = aws_secretsmanager_secret.grafana_admin.id
  secret_string = jsonencode({
    username = "admin"
    password = random_password.grafana.result
  })
}
```

### ExternalSecret remoteRef format

AWS Secrets Manager stores JSON blobs. The `remoteRef` uses `key` for the secret name and `property` for the JSON field:

```yaml
# Per-cluster override (clusters/<name>/bootstrap-secrets.yaml)
secretStoreName: aws-secrets-manager

secrets:
  grafanaAdmin:
    enabled: true
    onepasswordItem: "grafana-my-cluster"  # this becomes the AWS secret name
    data:
      - secretKey: username
        remoteRef:
          property: username  # JSON field inside the AWS secret
      - secretKey: password
        remoteRef:
          property: password
```

The `onepasswordItem` field name is a misnomer when using non-1Password backends — it maps to the `key` in the ESO remoteRef. A future refactor could rename this to `remoteKey`.

## GCP Secret Manager

### ClusterSecretStore

```yaml
apiVersion: external-secrets.io/v1
kind: ClusterSecretStore
metadata:
  name: gcp-secret-manager
spec:
  provider:
    gcpsm:
      projectID: your-gcp-project-id
      auth:
        workloadIdentity:
          clusterLocation: europe-west2
          clusterName: your-cluster
          clusterProjectID: your-gcp-project-id
          serviceAccountRef:
            name: external-secrets
            namespace: external-secrets
```

Authentication uses GKE Workload Identity. The ESO service account needs `roles/secretmanager.secretAccessor`.

### Terraform setup

```hcl
resource "google_secret_manager_secret" "grafana_admin" {
  secret_id = "grafana-${var.cluster_name}"
  replication {
    auto {}
  }
}

resource "google_secret_manager_secret_version" "grafana_admin" {
  secret      = google_secret_manager_secret.grafana_admin.id
  secret_data = jsonencode({
    username = "admin"
    password = random_password.grafana.result
  })
}
```

### ExternalSecret remoteRef format

GCP Secret Manager stores opaque payloads. For JSON secrets, the `property` field extracts individual fields:

```yaml
secretStoreName: gcp-secret-manager

secrets:
  grafanaAdmin:
    enabled: true
    onepasswordItem: "grafana-my-cluster"
    data:
      - secretKey: username
        remoteRef:
          property: username
      - secretKey: password
        remoteRef:
          property: password
```

## HashiCorp Vault

### ClusterSecretStore

```yaml
apiVersion: external-secrets.io/v1
kind: ClusterSecretStore
metadata:
  name: vault
spec:
  provider:
    vault:
      server: "https://vault.example.com"
      path: "secret"
      version: "v2"
      auth:
        kubernetes:
          mountPath: "kubernetes"
          role: "external-secrets"
          serviceAccountRef:
            name: external-secrets
            namespace: external-secrets
```

### ExternalSecret remoteRef format

Vault KV v2 uses `key` for the path and `property` for the field:

```yaml
secretStoreName: vault

secrets:
  grafanaAdmin:
    enabled: true
    onepasswordItem: "k8s/grafana-my-cluster"  # Vault path
    data:
      - secretKey: username
        remoteRef:
          property: username
      - secretKey: password
        remoteRef:
          property: password
```

## Switching backends: step-by-step

1. **Choose your backend** and create the secrets there (manually or via Terraform)

2. **Replace the ClusterSecretStore template** in `values/platform-secrets/templates/cluster-secret-store.yaml` with the template for your backend

3. **Update platform-secrets values** in `values/platform-secrets/values.yaml` — remove 1Password-specific fields, add your backend's auth config

4. **Update per-cluster bootstrap-secrets values** in `clusters/<name>/bootstrap-secrets.yaml`:
   - Set `secretStoreName` to match your ClusterSecretStore name
   - Set each secret's `onepasswordItem` to the key/path in your backend

5. **Update Terraform addons** — remove the 1Password token creation and item writes, replace with your backend's secret creation

6. **Remove the 1Password service account token** from your Terraform variables if you're no longer using it

The ExternalSecret templates in `values/bootstrap-secrets/templates/` do not need to change — they use standard ESO `remoteRef.key` and `remoteRef.property` fields which work across all backends.
