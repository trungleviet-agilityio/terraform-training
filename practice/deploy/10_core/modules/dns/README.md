# Route53 DNS Module

This module creates a Route53 hosted zone for a subdomain and an ACM certificate for SSL/TLS.

## Resources

- Route53 Hosted Zone (for subdomain: `{environment}.{domain_name}`)
- ACM Certificate (wildcard certificate: `{environment}.{domain_name}` and `*.{environment}.{domain_name}`)
- DNS validation records for certificate validation

## Usage

```hcl
module "dns" {
  source = "../modules/dns"

  project_name = var.project_name
  environment  = var.environment
  domain_name  = "example.com"  # Creates hosted zone for dev.example.com

  tags = var.tags
}
```

**Note:** The hosted zone will be created for `{environment}.{domain_name}` (e.g., `dev.example.com`).

## Variables

- `project_name`: Project name for resource naming
- `environment`: Environment name (dev, stage, prod)
- `domain_name`: Base domain name (e.g., example.com). The hosted zone will be created for `{environment}.{domain_name}`
- `tags`: Tags to apply to resources

## Outputs

- `hosted_zone_id`: ID of the Route53 hosted zone
- `hosted_zone_name`: Name of the Route53 hosted zone (e.g., `dev.example.com`)
- `name_servers`: Name servers for the hosted zone (configure at domain registrar)
- `hosted_zone_arn`: ARN of the Route53 hosted zone
- `certificate_arn`: ARN of the ACM certificate (wildcard certificate)
- `certificate_domain`: Primary domain name of the certificate

## Important Notes

### ACM Certificate Region

**For API Gateway Custom Domains:** ACM certificates used with API Gateway **MUST** be created in the `us-east-1` region, regardless of where your API Gateway is deployed.

### Practice Mode (Default Provider)

For practice and ALB/NLB use cases, use the default provider (no special configuration needed):

```hcl
module "dns" {
  source = "../modules/dns"

  project_name = var.project_name
  environment  = var.environment
  domain_name  = "example.com"

  tags = var.tags
}
```

The certificate will be created in the default provider region (e.g., `ap-southeast-1` for Singapore).

### Production Mode (API Gateway - us-east-1)

For API Gateway custom domains, use a `providers` block to create the certificate in `us-east-1`:

```hcl
# First, add provider alias in your providers.tf
provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"

  default_tags {
    tags = {
      Environment = var.environment
      Project     = var.project_name
      ManagedBy   = "Terraform"
    }
  }
}

# Then use providers block in module call
module "dns" {
  source = "../modules/dns"

  providers = {
    aws = aws.us_east_1  # Create certificate in us-east-1
  }

  project_name = var.project_name
  environment  = var.environment
  domain_name  = "example.com"

  tags = var.tags
}
```

**Note:** Route53 hosted zone will still be created in your default region (Route53 is global). Only the ACM certificate is created in `us-east-1`.

**For CloudFront:** ACM certificates for CloudFront also require `us-east-1`.

**For ALB/NLB:** ACM certificates can be created in the same region as your load balancer.

### DNS Configuration

1. After creating the hosted zone, configure the name servers at your domain registrar
2. The certificate will automatically validate via DNS records created in Route53
3. The certificate covers both the root domain (`dev.example.com`) and wildcard (`*.dev.example.com`)

### Certificate Validation

The module automatically creates DNS validation records for both:
- Root domain: `{environment}.{domain_name}`
- Wildcard domain: `*.{environment}.{domain_name}`

Certificate validation typically takes 5-30 minutes after DNS records are created.

## Integration with API Gateway

To use this certificate with API Gateway custom domain:

1. **Set `use_us_east_1_certificate = true`** in `10_core/main/variables.tf` or `terraform.tfvars` to create certificate in `us-east-1`
2. Get the certificate ARN from module outputs
3. Use the certificate ARN in API Gateway custom domain configuration (in `20_infra` layer)

The `20_infra` layer automatically reads the certificate ARN from `10_core` remote state and creates the API Gateway custom domain. See `deploy/20_infra/modules/api-gateway/README.md` for details.

**Example configuration in `10_core/environments/dev/terraform.tfvars`:**

```hcl
# For API Gateway custom domains, set this to true
use_us_east_1_certificate = true

dns_config = {
  domain_name = "example.com"
}
```

The certificate will be automatically created in `us-east-1` and the `20_infra` layer will use it for API Gateway custom domain configuration.
