resource "random_string" "sql_server_suffix" {
  length  = 4
  special = false
  upper   = false
  lower   = true
  number  = true
}

resource "random_password" "sql_password" {
  length           = 16
  special          = true
  upper            = true
  lower            = true
  number           = true
  override_special = "-_!#^~%@"
}

resource "google_sql_user" "users" {
  name     = var.db_root_username
  project  = var.project_id
  instance = google_sql_database_instance.instance.name
  password = random_password.sql_password.result
}
data "google_compute_network" "sql-network" {
  name    = var.authorized_network
  project = var.host_project_id
}

resource "google_sql_database_instance" "instance" {
  #ts:skip=AC_GCP_0003 DB SSL needs application level changes
  provider            = google-beta
  name                = "${replace(var.instance_name, "_", "-")}-${random_string.sql_server_suffix.id}"
  database_version    = var.database_version
  region              = var.region
  project             = var.project_id
  deletion_protection = var.deletion_protection
  root_password       = random_password.sql_password.result
  encryption_key_name = var.encryption_key_name == "" ? null : var.encryption_key_name

  settings {
    tier = var.tier
    # edition           = var.edition
    availability_type = var.availability_type
    disk_size         = var.disk_size
    disk_autoresize   = var.disk_autoresize
    # time_zone         = var.time_zone

    backup_configuration {
      enabled                        = var.backup_enabled
      start_time                     = var.backup_start_time
      binary_log_enabled             = var.binary_log_enabled
      point_in_time_recovery_enabled = var.point_in_time_recovery_enabled

    }

    ip_configuration {
      ipv4_enabled       = var.ipv4_enabled
      private_network    = data.google_compute_network.sql-network.id
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
    google_project_service_identity.sa
  ]
  lifecycle {
    ignore_changes = [
      settings[0].activation_policy  
    ]
  }
}

//Create this in the first run, allow google_sql_database_instance to fail. 
//Then add iam binding for this SA in keyring rerun this module again.
resource "google_project_service_identity" "sa" {
  provider = google-beta
  project  = var.project_id
  service  = "sqladmin.googleapis.com"
}

# --- Added from old repo (missing in new as of comparison) ---
data "google_project" "sql_project" {
  project_id = var.project_id
}

# --- Added from old repo (missing in new as of comparison) ---
resource "google_project_iam_binding" "sql_kms_binding" {
  count   = var.encryption_key_name != "" ? 1 : 0
  project = var.project_id

  lifecycle {
    ignore_changes = [members]
  }

  role = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  members = [
    "serviceAccount:service-${data.google_project.sql_project.number}@gcp-sa-cloud-sql.iam.gserviceaccount.com",
  ]
}
