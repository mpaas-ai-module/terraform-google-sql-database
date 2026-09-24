resource "random_string" "sql_server_suffix" {
  length  = 4
  special = false
  upper   = false
  lower   = true
  numeric = true
}

locals {
  is_sql_server = substr(var.database_version, 0, 9) == "SQLSERVER"
  is_mysql      = substr(var.database_version, 0, 5) == "MYSQL"
  is_postgres   = substr(var.database_version, 0, 8) == "POSTGRES"
}

# =========================================================
# Project
# =========================================================

data "google_project" "current" {
  project_id = var.project_id
}

# =========================================================
# KMS - Auto Fetch
# =========================================================

data "google_kms_key_ring" "project_keyring" {
  project  = var.project_id
  name     = var.project_id
  location = var.region
}

data "google_kms_crypto_key" "project_key" {
  name     = "${data.google_project.current.name}-key"
  key_ring = data.google_kms_key_ring.project_keyring.id
}

# =========================================================
# Required APIs
# =========================================================

resource "google_project_service" "sqladmin" {
  project            = var.project_id
  service            = "sqladmin.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "servicenetworking" {
  project            = var.project_id
  service            = "servicenetworking.googleapis.com"
  disable_on_destroy = false
}

# =========================================================
# Cloud SQL Service Identity
# =========================================================

resource "google_project_service_identity" "sqladmin" {
  provider = google-beta
  project  = var.project_id
  service  = "sqladmin.googleapis.com"

  depends_on = [
    google_project_service.sqladmin
  ]
}

# =========================================================
# Service Networking Service Identity
# =========================================================

resource "google_project_service_identity" "servicenetworking" {
  provider = google-beta
  project  = var.project_id
  service  = "servicenetworking.googleapis.com"

  depends_on = [
    google_project_service.servicenetworking
  ]
}

# =========================================================
# Wait for Google Service Agents
# =========================================================

resource "time_sleep" "wait_for_service_identities" {
  create_duration = "60s"

  depends_on = [
    google_project_service_identity.sqladmin,
    google_project_service_identity.servicenetworking
  ]
}

# =========================================================
# SERVICE NETWORKING IAM
# IMPORTANT:
# This MUST be on the CONSUMER/SERVICE PROJECT
# =========================================================

resource "google_project_iam_member" "service_networking_service_agent" {
  project = var.project_id

  role = "roles/servicenetworking.serviceAgent"

  member = google_project_service_identity.servicenetworking.member

  depends_on = [
    time_sleep.wait_for_service_identities
  ]

  lifecycle {
    prevent_destroy = false
  }
}

# =========================================================
# Shared VPC Host Project
# Cloud SQL Service Agent -> Compute Network User
# =========================================================

resource "google_project_iam_member" "compute_network_user" {
  project = var.host_project_id

  role = "roles/compute.networkUser"

  member = google_project_service_identity.sqladmin.member

  depends_on = [
    time_sleep.wait_for_service_identities
  ]

  lifecycle {
    prevent_destroy = false
  }
}

# =========================================================
# Random Password
# =========================================================

resource "random_password" "sql_password" {
  length           = 16
  special          = true
  upper            = true
  lower            = true
  numeric          = true
  override_special = "-_!#^~%@"
}

# =========================================================
# Shared VPC Network
# =========================================================

data "google_compute_network" "sql_network" {
  name    = var.authorized_network
  project = var.host_project_id
}

# =========================================================
# KMS IAM
# Cloud SQL Service Agent -> KMS Encrypt/Decrypt
# =========================================================

resource "google_kms_crypto_key_iam_member" "sql_cmek" {
  crypto_key_id = data.google_kms_crypto_key.project_key.id

  role = "roles/cloudkms.cryptoKeyEncrypterDecrypter"

  member = google_project_service_identity.sqladmin.member

  depends_on = [
    time_sleep.wait_for_service_identities
  ]

  lifecycle {
    ignore_changes = [
      member
    ]
  }
}

# =========================================================
# Cloud SQL Instance
# =========================================================

resource "google_sql_database_instance" "instance" {
  #ts:skip=AC_GCP_0003 DB SSL needs application level changes

  provider = google-beta

  name                = "${var.instance_name}-${random_string.sql_server_suffix.id}"
  database_version    = var.database_version
  region              = var.region
  project             = var.project_id
  deletion_protection = var.deletion_protection

  root_password = random_password.sql_password.result

  encryption_key_name = data.google_kms_crypto_key.project_key.id

  settings {
    tier              = var.tier
    availability_type = var.availability_type
    disk_size         = var.disk_size
    disk_autoresize   = var.disk_autoresize
    edition           = local.is_postgres ? var.edition : null

    time_zone = local.is_sql_server ? var.time_zone : null

    backup_configuration {
      enabled                        = var.backup_enabled
      start_time                     = var.backup_start_time
      binary_log_enabled             = local.is_mysql ? var.binary_log_enabled : null
      point_in_time_recovery_enabled = var.point_in_time_recovery_enabled
    }

    ip_configuration {
      ipv4_enabled       = var.ipv4_enabled
      private_network    = data.google_compute_network.sql_network.id
      allocated_ip_range = var.reserved_peering_ranges
    }

    dynamic "database_flags" {
      for_each = var.database_flags

      content {
        name  = database_flags.value.name
        value = database_flags.value.value
      }
    }

    dynamic "insights_config" {
      for_each = var.insights_config

      content {
        query_insights_enabled  = insights_config.value.query_insights_enabled
        query_string_length     = insights_config.value.query_string_length
        record_application_tags = insights_config.value.record_application_tags
        record_client_address   = insights_config.value.record_client_address
      }
    }

    dynamic "maintenance_window" {
      for_each = var.maintenance_window

      content {
        day          = maintenance_window.value.maintenance_window_day
        hour         = maintenance_window.value.maintenance_window_hour
        update_track = maintenance_window.value.maintenance_window_update_track
      }
    }
  }

  depends_on = [
    google_kms_crypto_key_iam_member.sql_cmek,
    google_project_iam_member.service_networking_service_agent,
    google_project_iam_member.compute_network_user
  ]

  lifecycle {
    ignore_changes = [
      settings[0].activation_policy
    ]
  }
}

# =========================================================
# Cloud SQL User
# =========================================================

resource "google_sql_user" "users" {
  name     = var.db_root_username
  project  = var.project_id
  instance = google_sql_database_instance.instance.name
  password = random_password.sql_password.result

  depends_on = [
    google_sql_database_instance.instance
  ]
}