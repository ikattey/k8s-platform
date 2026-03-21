# Cloud-portable storage class aliases for EKS.
# fast-rwo     -> gp3 (higher IOPS / throughput)
# standard-rwo -> gp3 (baseline)

resource "kubernetes_storage_class_v1" "fast_rwo" {
  metadata {
    name = "fast-rwo"
    labels = {
      "app.kubernetes.io/managed-by" = "terraform-bootstrap"
      "k8s-platform/storage-tier"    = "high-performance"
    }
  }

  storage_provisioner    = "ebs.csi.aws.com"
  reclaim_policy         = "Delete"
  allow_volume_expansion = true
  volume_binding_mode    = "WaitForFirstConsumer"

  parameters = {
    type       = "gp3"
    iops       = "6000"
    throughput = "250"
    fsType     = "ext4"
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

  storage_provisioner    = "ebs.csi.aws.com"
  reclaim_policy         = "Delete"
  allow_volume_expansion = true
  volume_binding_mode    = "WaitForFirstConsumer"

  parameters = {
    type       = "gp3"
    iops       = "3000"
    throughput = "125"
    fsType     = "ext4"
  }
}
