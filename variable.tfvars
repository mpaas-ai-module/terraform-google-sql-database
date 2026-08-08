# Sample values for UAT environment - update as per change request

db_root_username = "uat_sqladmin"

instance_name = "uat-sql-instance"

database_version = "POSTGRES_13"

region = "asia-south1"

deletion_protection = false

tier = "db-custom-2-7680"

availability_type = "ZONAL"

disk_size = "50"

disk_autoresize = true

backup_enabled = true

binary_log_enabled = false

ipv4_enabled = false

backup_start_time = "02:00"

database_flags = [
  {
    name  = "log_checkpoints"
    value = "on"
  }
]

insights_config = [
  {
    query_insights_enabled  = true
    query_string_length     = 1024
    record_application_tags = true
    record_client_address   = true
  }
]

maintenance_window = [
  {
    maintenance_window_day          = 7
    maintenance_window_hour         = 3
    maintenance_window_update_track = "stable"
  }
]

# shared_vpc_project_id = "host-project-uat-env-mum"

project_id = "testgcp110012-uat-686007"

private_ip_address_name = "uat-sql-private-ip"

reserved_peering_ranges = "cloudsql-uat-01"

authorized_network = "shared-vpc-uat-01"

host_project_id = "host-project-uat-env-mum"

encryption_key_name = "projects/testgcp110012-uat-686007/locations/asia-south1/keyRings/testgcp110012-uat-686007/cryptoKeys/testgcp110012-uat-key"

point_in_time_recovery_enabled = false

time_zone = "Asia/Kolkata"
