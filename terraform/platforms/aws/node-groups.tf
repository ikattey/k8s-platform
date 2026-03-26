locals {
  eks_managed_node_groups = merge(
    {
      general = {
        name           = "general"
        instance_types = var.general_instance_types
        capacity_type  = var.enable_spot_instances ? "SPOT" : "ON_DEMAND"
        ami_type       = "AL2023_x86_64_STANDARD"

        min_size     = var.general_min_size
        max_size     = var.general_max_size
        desired_size = var.general_desired_size

        labels = {
          "k8s-platform/pool-role" = "general"
        }

        tags = {
          "k8s.io/cluster-autoscaler/enabled"             = "true"
          "k8s.io/cluster-autoscaler/${var.cluster_name}" = "owned"
        }
      }
    },
    var.enable_storage_node_pool ? {
      storage = {
        name           = "storage"
        instance_types = var.storage_instance_types
        capacity_type  = "ON_DEMAND"
        ami_type       = "AL2023_x86_64_STANDARD"

        min_size     = var.storage_min_size
        max_size     = var.storage_max_size
        desired_size = var.storage_desired_size

        labels = {
          "k8s-platform/pool-role" = "storage"
        }

        taints = {
          storage = {
            key    = "k8s-platform/pool-role"
            value  = "storage"
            effect = "NO_SCHEDULE"
          }
        }

        tags = {
          "k8s.io/cluster-autoscaler/enabled"             = "true"
          "k8s.io/cluster-autoscaler/${var.cluster_name}" = "owned"
        }
      }
    } : {}
  )
}
