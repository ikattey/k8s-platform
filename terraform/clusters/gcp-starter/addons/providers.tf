terraform {
  required_version = "~> 1.14"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 7.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 3.1"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 3.0"
    }
    kubectl = {
      source  = "alekc/kubectl"
      version = "~> 2.1"
    }
    onepassword = {
      source  = "1Password/onepassword"
      version = "~> 3.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
    time = {
      source  = "hashicorp/time"
      version = "~> 0.13"
    }
  }
}

data "terraform_remote_state" "cluster" {
  backend = "gcs"
  config = {
    bucket = var.state_bucket
    prefix = var.state_key != "" ? var.state_key : "k8s-platform/clusters/gcp-starter/cluster"
  }
}

locals {
  cluster = {
    server                       = data.terraform_remote_state.cluster.outputs.cluster_endpoint != null ? "https://${data.terraform_remote_state.cluster.outputs.cluster_endpoint}" : ""
    "certificate-authority-data" = try(data.terraform_remote_state.cluster.outputs.cluster_ca_certificate, data.terraform_remote_state.cluster.outputs.cluster_certificate_authority_data, "")
  }

  cluster_endpoint = data.terraform_remote_state.cluster.outputs.cluster_endpoint
  cluster_ca_cert  = data.terraform_remote_state.cluster.outputs.cluster_ca_certificate
  project_id       = data.terraform_remote_state.cluster.outputs.project_id
  region           = data.terraform_remote_state.cluster.outputs.region
}

provider "google" {
  project = local.project_id
  region  = local.region
}

data "google_client_config" "default" {}

provider "kubernetes" {
  host                   = "https://${local.cluster_endpoint}"
  cluster_ca_certificate = base64decode(local.cluster_ca_cert)
  token                  = data.google_client_config.default.access_token
}

provider "helm" {
  kubernetes = {
    host                   = "https://${local.cluster_endpoint}"
    cluster_ca_certificate = base64decode(local.cluster_ca_cert)
    token                  = data.google_client_config.default.access_token
  }
}

provider "kubectl" {
  host                   = "https://${local.cluster_endpoint}"
  cluster_ca_certificate = base64decode(local.cluster_ca_cert)
  token                  = data.google_client_config.default.access_token
  load_config_file       = false
}

provider "onepassword" {}
