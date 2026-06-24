variable "db_root_username" {
  type        = string
  description = "The root username for the database instance"
}

# variable "network_id" {
#   description = "The id of the vpc"
#   type        = string
# }

variable "instance_name" {
  description = "The name of the database instance"
  type        = string
}
# variable "edition" {
#   description = "The name of the edition instance"
#   type        = string
# }

variable "database_version" {
  description = "The MySQL, PostgreSQL or SQL Server version to use. Supported values include MYSQL_5_6, MYSQL_5_7, MYSQL_8_0, POSTGRES_9_6,POSTGRES_10, POSTGRES_11, POSTGRES_12, POSTGRES_13, SQLSERVER_2017_STANDARD, SQLSERVER_2017_ENTERPRISE, SQLSERVER_2017_EXPRESS, SQLSERVER_2017_WEB. SQLSERVER_2019_STANDARD, SQLSERVER_2019_ENTERPRISE, SQLSERVER_2019_EXPRESS, SQLSERVER_2019_WEB"
  type        = string
}

variable "region" {
  description = "The region the instance will sit in"
  type        = string
}

variable "deletion_protection" {
  description = "Whether or not to allow Terraform to destroy the instance"
  type        = bool
}

variable "tier" {
  description = "The machine type to use"
  type        = string
}

variable "availability_type" {
  description = "The availability type of the Cloud SQL instance, high availability (REGIONAL) or single zone (ZONAL)"
  type        = string
}

variable "disk_size" {
  description = "The size of data disk, in GB. Size of a running instance cannot be reduced but can be increased"
  type        = string
}

variable "disk_autoresize" {
  description = "Configuration to increase storage size automatically"
  type        = bool
}

variable "backup_enabled" {
  description = "True if backup configuration is enabled"
  type        = bool
}

variable "binary_log_enabled" {
  description = "True if backup configuration is enabled"
  type        = bool
}

variable "ipv4_enabled" {
  description = "True if backup configuration is enabled"
  type        = bool
  default     = false
}

variable "backup_start_time" {
  description = "HH:MM format time indicating when backup configuration starts"
  type        = string
}

variable "database_flags" {
  description = "The id of the vpc"
  type = list(object({
    name  = string
    value = string
  }))
}

variable "insights_config" {
  description = "The id of the vpc"
  type = list(object({
    query_insights_enabled  = bool
    query_string_length     = number
    record_application_tags = bool
    record_client_address   = bool
  }))
}

variable "maintenance_window" {
  description = "Subblock for instances declares a one-hour maintenance window when an Instance can automatically restart to apply updates"
  type = list(object({
    maintenance_window_day          = number
    maintenance_window_hour         = number
    maintenance_window_update_track = string
  }))
}

variable "shared_vpc_project_id" {
  description = "Shared VPC project"
  type        = string
}

variable "project_id" {
  description = "The project where the database lives"
  type        = string
}

variable "private_ip_address_name" {
  description = "The name of the static private ip for the database"
  type        = string
}

variable "reserved_peering_ranges" {
  description = "List of peering ranges"
  type        = string
}
variable "authorized_network" {
  description = "authorized_network"
  type        = string
}
variable "host_project_id" {
  description = "host_project_id"
  type        = string
}

variable "encryption_key_name" {
  type        = string
  description = "the Customer Managed Encryption Key used to encrypt the boot disk attached to each node in the node pool"
  default     = ""
}
variable "point_in_time_recovery_enabled" {
  type    = bool
  default = false
}
# variable "time_zone" {
#   type = string

# }