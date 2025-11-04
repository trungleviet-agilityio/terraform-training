output "oidc_provider_arn" {
  value       = aws_iam_openid_connect_provider.github_actions.arn
  description = "ARN of the OIDC provider for GitHub Actions."
}

output "oidc_provider_url" {
  value       = aws_iam_openid_connect_provider.github_actions.url
  description = "URL of the OIDC provider."
}

output "oidc_provider_name" {
  value       = aws_iam_openid_connect_provider.github_actions.url
  description = "Name/URL of the OIDC provider (used in trust policies)."
}
