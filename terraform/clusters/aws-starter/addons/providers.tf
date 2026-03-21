terraform {
  required_version = "~> 1.14"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
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
      version = "~> 3.8"
    }
    time = {
      source  = "hashicorp/time"
      version = "~> 0.13"
    }
  }
}

data "terraform_remote_state" "cluster" {
  backend = "s3"
  config = {
    bucket       = var.state_bucket
    key          = var.state_key != "" ? var.state_key : "k8s-platform/clusters/aws-starter/cluster.tfstate"
    region       = var.state_region
    use_lockfile = true
    encrypt      = true
  }
}

locals {
  cluster = {
    server                       = data.terraform_remote_state.cluster.outputs.cluster_endpoint != null ? "https://${data.terraform_remote_state.cluster.outputs.cluster_endpoint}" : ""
    "certificate-authority-data" = try(data.terraform_remote_state.cluster.outputs.cluster_ca_certificate, data.terraform_remote_state.cluster.outputs.cluster_certificate_authority_data, "")
  }

  region = data.terraform_remote_state.cluster.outputs.region
}

provider "aws" {
  region = local.region
}

data "aws_eks_cluster" "cluster" {
  name = local.cluster_name
}

data "aws_eks_cluster_auth" "cluster" {
  name = local.cluster_name
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.cluster.token
}

provider "helm" {
  kubernetes = {
    host                   = data.aws_eks_cluster.cluster.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority[0].data)
    token                  = data.aws_eks_cluster_auth.cluster.token
  }
}

provider "kubectl" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.cluster.token
  load_config_file       = false
}

provider "onepassword" {}
