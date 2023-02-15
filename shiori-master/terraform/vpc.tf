variable "project_id" {
  description = "project id"
}

provider "google" {
  project = var.project_id
}

# VPC
resource "google_compute_network" "vpc" {
  name                    = "${var.project_id}-vpc"
  auto_create_subnetworks = "true"
}
