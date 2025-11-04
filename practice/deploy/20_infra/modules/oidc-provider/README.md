# OIDC Provider Module

This module creates an AWS IAM OpenID Connect (OIDC) identity provider for GitHub Actions, enabling GitHub Actions workflows to authenticate to AWS without storing long-lived credentials.

## Resources Created

- `aws_iam_openid_connect_provider`: OIDC identity provider for GitHub Actions

## Usage

```hcl
module "oidc_provider" {
  source = "../modules/oidc-provider"

  name   = "oidc-provider-github-actions"
  tags = {
    Project     = "terraform-practice"
    Environment = "dev"
    ManagedBy   = "Terraform"
  }
}
```

## Inputs

| Name | Type | Description | Default | Required |
|------|------|-------------|---------|----------|
| `name` | `string` | Name for the OIDC provider resource | `oidc-provider-github-actions` | No |
| `thumbprint_list` | `list(string)` | List of server certificate thumbprints | GitHub Actions thumbprints | No |
| `tags` | `map(string)` | Tags to apply to the OIDC provider | `{}` | No |

## Outputs

| Name | Description |
|------|-------------|
| `oidc_provider_arn` | ARN of the OIDC provider (use in trust policies) |
| `oidc_provider_url` | URL of the OIDC provider |
| `oidc_provider_name` | Name/URL of the OIDC provider |

## Notes

- The OIDC provider URL is fixed to `https://token.actions.githubusercontent.com` (GitHub Actions)
- Client ID list is set to `["sts.amazonaws.com"]` (AWS STS)
- Default thumbprints are GitHub Actions root certificates (updated as of 2024)
- The provider ARN is used in IAM role trust policies to allow GitHub Actions to assume roles

## References

- [AWS Documentation: Creating OIDC Identity Providers](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_providers_create_oidc.html)
- [GitHub Actions: Configuring OpenID Connect in Amazon Web Services](https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/configuring-openid-connect-in-amazon-web-services)
