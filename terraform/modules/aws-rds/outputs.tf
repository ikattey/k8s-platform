output "host" {
  description = "RDS hostname"
  value       = aws_db_instance.postgres.address
}

output "port" {
  description = "RDS port"
  value       = aws_db_instance.postgres.port
}

output "database_name" {
  description = "Database name"
  value       = aws_db_instance.postgres.db_name
}

output "username" {
  description = "Database user"
  value       = aws_db_instance.postgres.username
}

output "password" {
  description = "Database password"
  value       = random_password.master.result
  sensitive   = true
}

output "write_url" {
  description = "Write connection string"
  value       = "postgresql://${aws_db_instance.postgres.username}:${random_password.master.result}@${aws_db_instance.postgres.address}:${aws_db_instance.postgres.port}/${aws_db_instance.postgres.db_name}?sslmode=require"
  sensitive   = true
}

output "read_url" {
  description = "Read connection string"
  value       = "postgresql://${aws_db_instance.postgres.username}:${random_password.master.result}@${aws_db_instance.postgres.address}:${aws_db_instance.postgres.port}/${aws_db_instance.postgres.db_name}?sslmode=require"
  sensitive   = true
}
