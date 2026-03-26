# Cloud-portable storage class aliases for OVH MKS.
# fast-rwo     -> high-speed-gen2
# standard-rwo -> classic

resource "kubernetes_storage_class_v1" "fast_rwo" {
  metadata {
    name = "fast-rwo"
    labels = {
      "app.kubernetes.io/managed-by" = "terraform-bootstrap"
      "k8s-platform/storage-tier"    = "high-performance"
    }
  }

  storage_provisioner    = "csi.ovh.net"
  reclaim_policy         = "Delete"
  allow_volume_expansion = true
  volume_binding_mode    = "WaitForFirstConsumer"

  parameters = {
    type   = "high-speed-gen2"
    fsType = "ext4"
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

  storage_provisioner    = "csi.ovh.net"
  reclaim_policy         = "Delete"
  allow_volume_expansion = true
  volume_binding_mode    = "WaitForFirstConsumer"

  parameters = {
    type   = "classic"
    fsType = "ext4"
  }
}
