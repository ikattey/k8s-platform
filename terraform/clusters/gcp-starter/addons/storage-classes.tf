# Cloud-portable storage class aliases for GKE.
# fast-rwo     -> pd-ssd
# standard-rwo -> pd-balanced

resource "kubernetes_storage_class_v1" "fast_rwo" {
  metadata {
    name = "fast-rwo"
    labels = {
      "app.kubernetes.io/managed-by" = "terraform-bootstrap"
      "k8s-platform/storage-tier"    = "high-performance"
    }
  }

  storage_provisioner    = "pd.csi.storage.gke.io"
  reclaim_policy         = "Delete"
  allow_volume_expansion = true
  volume_binding_mode    = "WaitForFirstConsumer"

  parameters = {
    type   = "pd-ssd"
    fstype = "ext4"
  }
}

resource "kubernetes_storage_class_v1" "standard_rwo" {
  metadata {
    name = "standard-rwo"
    labels = {
      "app.kubernetes.io/managed-by" = "terraform-bootstrap"
      "k8s-platform/storage-tier"    = "standard"
    }
  }

  storage_provisioner    = "pd.csi.storage.gke.io"
  reclaim_policy         = "Delete"
  allow_volume_expansion = true
  volume_binding_mode    = "WaitForFirstConsumer"

  parameters = {
    type   = "pd-balanced"
    fstype = "ext4"
  }

  lifecycle {
    # GKE auto-creates standard-rwo without fstype; ignore parameter drift
    # to avoid destroy/recreate cycles on the cluster default StorageClass.
    ignore_changes = [parameters]
  }
}
