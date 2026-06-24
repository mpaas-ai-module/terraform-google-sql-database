terraform {
  required_version = ">=0.13"

  required_providers {
    google = {
      version = "~> 6.41.0"  # PoC fork: standardized (was >= 4.1.0)
      source  = "hashicorp/google"
    }
  }
}