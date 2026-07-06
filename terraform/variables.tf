variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "region" {
  description = "GCP region"
  type        = string
  default     = "us-central1"
}

variable "cluster_name" {
  description = "Name of the GKE cluster"
  type        = string
  default     = "gitops-cluster"
}

variable "machine_type" {
  description = "Machine type for node pool"
  type        = string
  default     = "e2-standard-4"
}

variable "initial_node_count" {
  description = "Initial number of nodes"
  type        = number
  default     = 3
}

variable "min_node_count" {
  description = "Minimum nodes for autoscaling"
  type        = number
  default     = 2
}

variable "max_node_count" {
  description = "Maximum nodes for autoscaling"
  type        = number
  default     = 10
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "enable_network_policy" {
  description = "Enable network policy"
  type        = bool
  default     = true
}
