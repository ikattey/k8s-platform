terraform {
  backend "s3" {
    bucket       = "your-tf-state-bucket"
    key          = "k8s-platform/clusters/aws-starter/addons.tfstate"
    region       = "eu-west-1"
    use_lockfile = true
    encrypt      = true
  }
}
