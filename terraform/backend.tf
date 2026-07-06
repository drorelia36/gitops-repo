terraform {
  backend "gcs" {
    bucket = "gitops-dev-dror-terraform-state"
    prefix = "terraform/state"
  }
}
