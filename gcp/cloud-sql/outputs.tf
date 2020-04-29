output "connection_name" {
  value = google_sql_database_instance.platform_db.connection_name
}

output "private_ip" {
  description = "The public IPv4 address of the master instance."
  value       = google_sql_database_instance.platform_db.private_ip_address
}