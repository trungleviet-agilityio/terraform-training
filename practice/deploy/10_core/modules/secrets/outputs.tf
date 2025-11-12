output "secret_arn" {
  value       = aws_secretsmanager_secret.this.arn
  description = "ARN of the secret (for Lambda environment variables)."
}

output "secret_name" {
  value       = aws_secretsmanager_secret.this.name
  description = "Full name of the secret (/practice/<environment>/<layer>/<secret-name> or /practice/<environment>/<secret-name>)."
}

output "secret_id" {
  value       = aws_secretsmanager_secret.this.id
  description = "ID of the secret resource."
}

output "secret_version_id" {
  value       = try(aws_secretsmanager_secret_version.this[0].version_id, null)
  description = "Version ID of the secret version (if created)."
}
