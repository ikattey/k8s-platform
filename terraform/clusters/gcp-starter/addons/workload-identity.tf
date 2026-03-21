resource "kubernetes_namespace_v1" "velero" {
  metadata {
    name = "velero"
    labels = {
      "app.kubernetes.io/managed-by" = "terraform-bootstrap"
    }
  }

  lifecycle {
    ignore_changes = [metadata[0].annotations]
  }

  depends_on = [time_sleep.external_secrets_destroy_grace_period]
}

data "google_service_account" "monitoring" {
  account_id = split("@", data.terraform_remote_state.cluster.outputs.monitoring_service_account_email)[0]
}

data "google_service_account" "velero" {
  account_id = split("@", data.terraform_remote_state.cluster.outputs.velero_service_account_email)[0]
}

data "google_service_account" "cnpg" {
  account_id = split("@", data.terraform_remote_state.cluster.outputs.cnpg_service_account_email)[0]
}

resource "google_service_account_iam_member" "monitoring_workload_identity" {
  service_account_id = data.google_service_account.monitoring.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "serviceAccount:${local.project_id}.svc.id.goog[monitoring/loki]"
}

resource "google_service_account_iam_member" "velero_workload_identity" {
  service_account_id = data.google_service_account.velero.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "serviceAccount:${local.project_id}.svc.id.goog[velero/velero]"
}

resource "google_service_account_iam_member" "cnpg_workload_identity" {
  service_account_id = data.google_service_account.cnpg.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "serviceAccount:${local.project_id}.svc.id.goog[${var.cnpg_namespace}/${var.cnpg_cluster_name}]"
}

resource "kubernetes_service_account_v1" "loki" {
  metadata {
    name      = "loki"
    namespace = kubernetes_namespace_v1.monitoring.metadata[0].name
    annotations = {
      "iam.gke.io/gcp-service-account" = data.terraform_remote_state.cluster.outputs.monitoring_service_account_email
    }
    labels = {
      "app.kubernetes.io/managed-by" = "terraform-bootstrap"
    }
  }

  automount_service_account_token = true

  depends_on = [google_service_account_iam_member.monitoring_workload_identity]
}

resource "kubernetes_service_account_v1" "velero" {
  metadata {
    name      = "velero"
    namespace = kubernetes_namespace_v1.velero.metadata[0].name
    annotations = {
      "iam.gke.io/gcp-service-account" = data.terraform_remote_state.cluster.outputs.velero_service_account_email
    }
    labels = {
      "app.kubernetes.io/managed-by" = "terraform-bootstrap"
    }
  }

  automount_service_account_token = true

  depends_on = [google_service_account_iam_member.velero_workload_identity]
}
