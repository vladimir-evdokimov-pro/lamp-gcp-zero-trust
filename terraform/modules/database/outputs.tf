output "db_name" {
  description = "Database name"
  value       = google_sql_database.pmadb.name
}

output "db_user" {
  description = "Database username"
  value       = google_sql_user.pmausr.name
}

output "db_private_ip" {
  description = "Private IP about SQL instance"
  value       = google_compute_address.psc_ip.address
}