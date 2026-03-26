# OIDC and OAuth

The kit supports three separate auth paths:

- Kubernetes API access for `kubectl`
- Grafana OAuth
- ArgoCD OIDC

They are independent. Enable only the ones you need. Create OAuth/OIDC clients in your identity provider:

| Path | OVH | Hetzner | AWS | GCP |
| --- | --- | --- | --- | --- |
| `kubectl` OIDC | Supported | Supported | Not supported | Not supported |
| Grafana OAuth | Supported | Supported | Supported | Supported |
| ArgoCD OIDC | Supported | Supported | Supported | Supported |

| Client | Type | Redirect URI | Clouds |
| --- | --- | --- | --- |
| `kubectl` | Desktop app | `http://localhost:8000`, `http://localhost:18000` | OVH, Hetzner |
| `grafana` | Web application | `https://grafana-<cluster>.<domain>/login/generic_oauth` | All clouds |
| `argocd` | Web application | `https://argocd-<cluster>.<domain>/auth/callback` | All clouds |

Defaults in this repo are tuned for Google, but the flow is provider-agnostic.

## Setup

1. Create only the OAuth/OIDC clients you need from the table above. See [Creating Google OAuth clients](#creating-google-oauth-clients) below.
2. Fill in the OIDC variables in `.env` (append `.env.oidc.example` to your `.env` if you haven't already).
3. For **OVH** and **Hetzner** kubectl OIDC only: set `enable_oidc = true` and `oidc_client_id` in cluster `terraform.tfvars` before the first apply.
4. Apply both stages: cluster then addons.
5. For **OVH** and **Hetzner** kubectl OIDC only: install kubelogin with `brew install kubelogin`, then use kubelogin directly with the OIDC issuer and your kubectl client ID to authenticate.
6. For **AWS**: use `aws eks update-kubeconfig --region <region> --name <cluster>`.
7. For **GCP**: use `gcloud container clusters get-credentials <cluster> --location <location> --project <project>`.

For GCP, OIDC in this starter applies to ArgoCD and Grafana only. `kubectl`
uses the native GKE auth flow instead of a starter-managed kubectl OIDC client.

See [credential-flow.md](credential-flow.md) for details on which 1Password
items are created and when.

## Creating Google OAuth clients

The kit defaults to Google as the identity provider. Create the OAuth clients you need for the auth paths you plan to enable.

**1. Configure the OAuth consent screen** (one-time per GCP project)

Go to **Google Cloud Console > APIs & Services > OAuth consent screen** (or Google Auth Platform > Overview).

- User type: **Internal** if your team is on Google Workspace — this is the primary security gate that restricts login to your org domain. Use **External** only for personal Google accounts or cross-org teams (requires adding test users manually).

> **Important**: Setting the consent screen to Internal is the only reliable way to restrict which Google accounts can access ArgoCD, Grafana, and kubectl. Neither ArgoCD nor kubectl validate email domains — they trust any token issued by the identity provider. Grafana's `allowed_domains` provides an additional safety net but should not be relied upon as the sole gate.
- Fill in App name, user support email, and developer contact email.
- Scopes: add `email`, `profile`, `openid`.
- For External apps, the app starts in **testing** mode. Add each team member's Google account as a test user under **Audience > Test users** before they log in. Publish the app to remove this restriction (requires OAuth verification for sensitive scopes, but `email`/`profile`/`openid` do not require verification).

**2. Create the clients**

Go to **Google Cloud Console > APIs & Services > Credentials** and create three **OAuth 2.0 Client IDs**, one per row:

| Client name | Application type | Authorized redirect URIs | Clouds |
| --- | --- | --- | --- |
| `oidc-{cluster}-kubectl` | Desktop app | `http://localhost:8000`, `http://localhost:18000` | OVH, Hetzner |
| `oidc-{cluster}-grafana` | Web application | `https://grafana-{cluster}.{domain}/login/generic_oauth` | All clouds |
| `oidc-{cluster}-argocd` | Web application | `https://argocd-{cluster}.{domain}/auth/callback` | All clouds |

Replace `{cluster}` with your cluster name (e.g. `aws-starter`) and `{domain}` with your domain.

For each client, after creation Google shows a dialog with the **Client ID** and **Client secret** — copy both immediately. Skip the kubectl client entirely on AWS and GCP.

**3. Fill in `.env`**

Add the client IDs and secrets to your `.env`:

```bash
export TF_VAR_kubectl_oidc_client_id="<kubectl-client-id>"
export TF_VAR_kubectl_oidc_client_secret="<kubectl-client-secret>"
export TF_VAR_grafana_oauth_client_id="<grafana-client-id>"
export TF_VAR_grafana_oauth_client_secret="<grafana-client-secret>"
export TF_VAR_argocd_oidc_client_id="<argocd-client-id>"
export TF_VAR_argocd_oidc_client_secret="<argocd-client-secret>"
export TF_VAR_oidc_allowed_domains="your-domain.com"
```

The `kubectl` client values are only used on OVH and Hetzner. Leave them empty
on AWS and GCP. The client ID is also needed in cluster `terraform.tfvars`
(Stage 1) as `oidc_client_id`. For Hetzner, this must be set before the first
apply.

## Environment

```bash
export TF_VAR_oidc_issuer_url="https://accounts.google.com"

# OVH / Hetzner only. Leave empty on AWS / GCP:
export TF_VAR_kubectl_oidc_client_id=""
export TF_VAR_kubectl_oidc_client_secret=""

export TF_VAR_oidc_allowed_domains=""                # e.g. "example.com" — used by Grafana as safety net

export TF_VAR_grafana_oauth_client_id=""
export TF_VAR_grafana_oauth_client_secret=""
# Optional — defaults to Google. Override for other providers.
# export TF_VAR_grafana_oauth_auth_url="https://accounts.google.com/o/oauth2/v2/auth"
# export TF_VAR_grafana_oauth_token_url="https://oauth2.googleapis.com/token"
# export TF_VAR_grafana_oauth_api_url="https://openidconnect.googleapis.com/v1/userinfo"
# export TF_VAR_grafana_oauth_scopes="openid email profile"

export TF_VAR_argocd_oidc_client_id=""
export TF_VAR_argocd_oidc_client_secret=""
```

`TF_VAR_oidc_allowed_domains` is used by Grafana as a safety net — it
rejects logins from email domains that don't match. ArgoCD does **not**
support domain filtering; any user who can authenticate with the identity
provider gets at least `role:readonly` access. The primary domain gate must
be configured at the identity provider level (e.g., Google OAuth consent
screen set to "Internal" for Google Workspace). See the setup section above.

## kubectl OIDC

Supported only on OVH and Hetzner. AWS and GCP do not configure API-server OIDC
in this starter, so `kubectl` does not use the same OIDC flow as ArgoCD or
Grafana there.

For OVH and Hetzner, Stage 1 must enable OIDC on the API server:

```hcl
enable_oidc     = true
oidc_client_id  = "your-kubectl-client-id"
oidc_issuer_url = "https://accounts.google.com"
```

**Hetzner:** OIDC is immutable after cluster creation. Set `enable_oidc = true` before the first apply; changing it later requires destroy and recreate. OVH does not have this constraint.

In Stage 2 on OVH and Hetzner, set:

```bash
export TF_VAR_kubectl_oidc_client_id="your-kubectl-client-id"
export TF_VAR_kubectl_oidc_client_secret="your-kubectl-client-secret"
```

Install the client plugin on each machine:

```bash
brew install kubelogin
```

or:

```bash
kubectl krew install oidc-login
```

After the addons apply, each team member installs kubelogin and authenticates directly using the OIDC issuer URL and kubectl client ID. Use `kubectl oidc-login setup` or configure the exec credential plugin in your kubeconfig manually. The kubeconfig server URL and CA data are available from `terraform output` in the cluster stage.

### AWS and GCP

Use the cloud-native kubeconfig commands instead:

```bash
# AWS
aws eks update-kubeconfig --region <region> --name <cluster>

# GCP
gcloud container clusters get-credentials <cluster> --location <location> --project <project>
```

The starter does not publish a kubectl OIDC kubeconfig item for AWS or GCP. On
GCP, run `gcloud container clusters get-credentials ...` and use the generated
kubeconfig context directly.

## Grafana OAuth

When `TF_VAR_grafana_oauth_client_id` is set, Terraform creates `Secret/monitoring/grafana-oauth`, writes `grafana-oidc-<cluster>` to the infra vault, and enables `components.grafanaOAuth` (which injects `auth.generic_oauth` into Grafana values).

The browser-login item is `grafana-admin-<cluster>`. With Grafana OAuth enabled and an infra vault configured, that item moves to the infra vault as break-glass access.

## ArgoCD OIDC

When `TF_VAR_argocd_oidc_client_id` is set, Terraform creates `Secret/argocd/argocd-oidc-secret`, writes `argocd-oidc-<cluster>` to the infra vault, and configures ArgoCD to read `clientSecret` from that Kubernetes Secret.

The browser-login item is `argocd-<cluster>`. With ArgoCD OIDC enabled and an infra vault configured, that item moves to the infra vault as break-glass access.

## RBAC

Set these in addons `terraform.tfvars` before applying on OVH or Hetzner:

```hcl
oidc_viewers = ["dev@example.com"]
oidc_admins  = ["ops@example.com"]
```

`oidc_admins` get `cluster-admin`. `oidc_viewers` get `view` (read-only across all namespaces). Both accept email addresses or group identifiers. The default username prefix is `oidc:`.

AWS and GCP do not support these OIDC RBAC shortcuts in this starter; use the native cloud auth path instead.

### Verifying RBAC

After applying, confirm bindings exist and test permissions:

```bash
# Check bindings
kubectl get clusterrolebindings | grep oidc

# Test as the authenticated user
kubectl auth whoami
kubectl auth can-i '*' '*' --all-namespaces   # admin: yes, viewer: no
kubectl get pods -A                            # both roles: allowed
kubectl delete pod -n argocd <pod>             # viewer: Forbidden
```

### ArgoCD RBAC

Kubernetes RBAC and ArgoCD RBAC are independent. OIDC users get read-only ArgoCD access by default. To grant admin access:

```bash
kubectl edit configmap argocd-rbac-cm -n argocd
```

Add a policy:

```yaml
data:
  policy.csv: |
    g, oidc:ops@example.com, role:admin
  policy.default: role:readonly
```

The `oidc:` prefix matches `oidc_username_prefix`, configured in both the cluster and addons stages — the value must be identical in both `terraform.tfvars` files.

## Vault behavior

See [credential-flow.md](credential-flow.md#item-types) for which items are created and which vault they land in.

## Troubleshooting

- no SSO button in Grafana: check `TF_VAR_grafana_oauth_client_id`,
  `TF_VAR_oidc_allowed_domains`, and the `grafana-oauth` Secret
- no SSO button in ArgoCD: check `TF_VAR_argocd_oidc_client_id` and re-run the
  addons apply
- "Required email domain not fulfilled" in Grafana: your Google account
  domain doesn't match `TF_VAR_oidc_allowed_domains`
- `interactiveMode must be specified`: re-run the addons apply and re-fetch the
  OIDC kubeconfig item
- `Forbidden` after successful login: the user is not in `oidc_viewers` or
  `oidc_admins`
