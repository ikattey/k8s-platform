output "host" {
  description = "Private IP address of the Cloud SQL instance"
  value       = google_sql_database_instance.postgres.private_ip_address
}

output "port" {
  description = "Cloud SQL PostgreSQL port"
  value       = 5432
}

output "database_name" {
  description = "Database name"
  value       = google_sql_database.app.name
}

output "username" {
  description = "Database user"
  value       = google_sql_user.app.name
}

output "password" {
  description = "Database password"
  value       = random_password.database.result
  sensitive   = true
}

output "write_url" {
  description = "Write connection string"
  value       = "postgresql://${google_sql_user.app.name}:${random_password.database.result}@${google_sql_database_instance.postgres.private_ip_address}:5432/${google_sql_database.app.name}?sslmode=require"
  sensitive   = true
}

output "read_url" {
  description = "Read connection string"
  value       = "postgresql://${google_sql_user.app.name}:${random_password.database.result}@${google_sql_database_instance.postgres.private_ip_address}:5432/${google_sql_database.app.name}?sslmode=require"
  sensitive   = true
}
