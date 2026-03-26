data "google_service_account" "monitoring" {
  account_id = split("@", data.terraform_remote_state.cluster.outputs.monitoring_service_account_email)[0]
}

resource "google_service_account_iam_member" "monitoring_workload_identity" {
  service_account_id = data.google_service_account.monitoring.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "serviceAccount:${local.project_id}.svc.id.goog[monitoring/loki]"
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
