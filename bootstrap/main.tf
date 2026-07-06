terraform {
  required_version = ">= 1.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.23"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.11"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

data "google_client_config" "default" {}

provider "kubernetes" {
  host                   = "https://${google_container_cluster.primary.endpoint}"
  token                  = data.google_client_config.default.access_token
  cluster_ca_certificate = base64decode(google_container_cluster.primary.master_auth[0].cluster_ca_certificate)
}

provider "helm" {
  kubernetes {
    host                   = "https://${google_container_cluster.primary.endpoint}"
    token                  = data.google_client_config.default.access_token
    cluster_ca_certificate = base64decode(google_container_cluster.primary.master_auth[0].cluster_ca_certificate)
  }
}

# Create GCS bucket for Terraform state
resource "google_storage_bucket" "terraform_state" {
  name          = "${var.project_id}-terraform-state"
  location      = var.region
  force_destroy = false

  versioning {
    enabled = true
  }

  uniform_bucket_level_access = true
  public_access_prevention    = "enforced"

  labels = {
    environment = "terraform"
    purpose     = "state"
    managed_by  = "terraform"
  }

  lifecycle {
    prevent_destroy = true
  }
}

# Create service account for Terraform
resource "google_service_account" "terraform" {
  account_id   = "terraform-admin"
  display_name = "Terraform Admin Service Account"
  description  = "Service account for Terraform operations"
}

# Grant roles to service account
resource "google_project_iam_member" "terraform_compute_admin" {
  project = var.project_id
  role    = "roles/compute.admin"
  member  = "serviceAccount:${google_service_account.terraform.email}"
}

resource "google_project_iam_member" "terraform_container_admin" {
  project = var.project_id
  role    = "roles/container.admin"
  member  = "serviceAccount:${google_service_account.terraform.email}"
}

resource "google_project_iam_member" "terraform_iam_admin" {
  project = var.project_id
  role    = "roles/iam.serviceAccountAdmin"
  member  = "serviceAccount:${google_service_account.terraform.email}"
}

resource "google_project_iam_member" "terraform_storage_admin" {
  project = var.project_id
  role    = "roles/storage.admin"
  member  = "serviceAccount:${google_service_account.terraform.email}"
}

resource "google_project_iam_member" "terraform_network_admin" {
  project = var.project_id
  role    = "roles/compute.networkAdmin"
  member  = "serviceAccount:${google_service_account.terraform.email}"
}

# Create service account key
resource "google_service_account_key" "terraform" {
  service_account_id = google_service_account.terraform.name
  public_key_type    = "TYPE_X509_PEM_FILE"
}

# Save key to local file
resource "local_file" "terraform_key" {
  filename        = "${path.module}/terraform-key.json"
  content         = base64decode(google_service_account_key.terraform.private_key)
  file_permission = "0600"

  depends_on = [google_service_account_key.terraform]
}

# Create backend configuration file for main terraform
resource "local_file" "backend_config" {
  filename = "${path.module}/../terraform/backend.tf"
  content  = "terraform {\n  backend \"gcs\" {\n    bucket = \"${google_storage_bucket.terraform_state.name}\"\n    prefix = \"terraform/state\"\n  }\n}\n"

  depends_on = [google_storage_bucket.terraform_state]
}

output "state_bucket_name" {
  description = "Name of the GCS bucket for Terraform state"
  value       = google_storage_bucket.terraform_state.name
}

output "terraform_service_account_email" {
  description = "Email of the Terraform service account"
  value       = google_service_account.terraform.email
}

output "terraform_key_path" {
  description = "Path to the Terraform service account key"
  value       = local_file.terraform_key.filename
  sensitive   = true
}
