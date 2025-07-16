terraform {
  required_version = ">= 1.3.0"

  backend "gcs" {
    bucket  = "pk-tf-state"  # Must be created manually beforehand, check Readme.md
    prefix  = "state"          
  }

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.20"  # Locked to latest stable major version (as of 2024-2025)
    }
  }
}

provider "google" {
  project     = var.project_id
  region      = var.region
}
