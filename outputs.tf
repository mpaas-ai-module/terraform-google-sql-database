output "sql_password" {
  value     = random_password.sql_password.result
  sensitive = true
}

output "sql_name" {
  value = google_sql_database_instance.instance.name
}

output "sql_private_ip" {
  value = google_sql_database_instance.instance.private_ip_address
}