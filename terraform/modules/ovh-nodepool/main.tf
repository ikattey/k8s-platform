resource "random_id" "nodepool_suffix" {
  byte_length = 4

  keepers = {
    flavor = var.flavor
  }
}

resource "ovh_cloud_project_kube_nodepool" "pool" {
  service_name   = var.project_id
  kube_id        = var.cluster_id
  name           = "${var.pool_name}-${random_id.nodepool_suffix.hex}"
  flavor_name    = var.flavor
  desired_nodes  = var.desired_nodes
  min_nodes      = var.min_nodes
  max_nodes      = var.max_nodes
  monthly_billed = false
  autoscale      = var.autoscale

  dynamic "template" {
    for_each = length(var.labels) > 0 || length(var.taints) > 0 ? [1] : []
    content {
      metadata {
        annotations = {}
        finalizers  = []
        labels      = var.labels
      }
      spec {
        taints        = var.taints
        unschedulable = false
      }
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}
