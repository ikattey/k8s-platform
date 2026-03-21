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

resource "kubernetes_service_account_v1" "loki" {
  metadata {
    name      = "loki"
    namespace = kubernetes_namespace_v1.monitoring.metadata[0].name
    annotations = {
      "eks.amazonaws.com/role-arn" = data.terraform_remote_state.cluster.outputs.monitoring_storage_role_arn
    }
    labels = {
      "app.kubernetes.io/managed-by" = "terraform-bootstrap"
    }
  }

  automount_service_account_token = true
}

resource "kubernetes_service_account_v1" "velero" {
  metadata {
    name      = "velero"
    namespace = kubernetes_namespace_v1.velero.metadata[0].name
    annotations = {
      "eks.amazonaws.com/role-arn" = data.terraform_remote_state.cluster.outputs.velero_role_arn
    }
    labels = {
      "app.kubernetes.io/managed-by" = "terraform-bootstrap"
    }
  }

  automount_service_account_token = true
}
