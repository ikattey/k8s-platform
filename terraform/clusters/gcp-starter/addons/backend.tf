terraform {
  backend "gcs" {
    bucket = "your-tf-state-bucket"
    prefix = "k8s-platform/clusters/gcp-starter/addons"
  }
}
