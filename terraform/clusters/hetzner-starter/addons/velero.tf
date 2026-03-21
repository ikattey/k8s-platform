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

resource "kubernetes_secret_v1" "velero_cloud_credentials" {
  metadata {
    name      = "velero-cloud-credentials"
    namespace = kubernetes_namespace_v1.velero.metadata[0].name
    labels = {
      "app.kubernetes.io/managed-by" = "terraform-bootstrap"
    }
  }

  data = {
    cloud = <<-EOT
[default]
aws_access_key_id=${var.object_storage_access_key}
aws_secret_access_key=${var.object_storage_secret_key}
EOT
  }

  depends_on = [kubernetes_namespace_v1.velero]
}

resource "kubernetes_service_account_v1" "velero" {
  metadata {
    name      = "velero"
    namespace = kubernetes_namespace_v1.velero.metadata[0].name
    labels = {
      "app.kubernetes.io/managed-by" = "terraform-bootstrap"
    }
  }

  automount_service_account_token = true
}
