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

resource "kubectl_manifest" "standard_rwo" {
  # GKE auto-creates standard-rwo as a default StorageClass; use server-side
  # apply so Terraform adds our labels without failing when the SC already exists.
  server_side_apply = true
  yaml_body = yamlencode({
    apiVersion = "storage.k8s.io/v1"
    kind       = "StorageClass"
    metadata = {
      name = "standard-rwo"
      labels = {
        "app.kubernetes.io/managed-by" = "terraform-bootstrap"
        "k8s-platform/storage-tier"    = "standard"
      }
    }
    provisioner           = "pd.csi.storage.gke.io"
    reclaimPolicy         = "Delete"
    allowVolumeExpansion  = true
    volumeBindingMode     = "WaitForFirstConsumer"
    parameters = {
      type = "pd-balanced"
    }
  })
}
