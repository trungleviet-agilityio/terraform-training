/**
 * # DNS Module
 *
 * This module manages a Route53 hosted zone for a subdomain in the format:
 * {var.environment}.{var.domain_name}
 * 
 * It also creates separate SSL certificates for:
 * 1. The root domain: {var.environment}.{var.domain_name}
 * 2. The wildcard subdomain: *.{var.environment}.{var.domain_name}
 *
 * Note: For API Gateway custom domains, the certificate MUST be created in us-east-1.
 */

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

locals {
  domain_name = "${var.environment}.${var.domain_name}"
}

resource "aws_route53_zone" "subdomain" {
  name = local.domain_name

  tags = merge(
    var.tags,
    {
      Name        = local.domain_name
      Environment = var.environment
    }
  )
}


# Create an SSL certificate for the wildcard subdomain
# For API Gateway: certificate MUST be in us-east-1 (use providers block in module call)
# For ALB/NLB: certificate can be in same region as load balancer
resource "aws_acm_certificate" "wildcard_cert" {
  domain_name               = local.domain_name
  subject_alternative_names = ["*.${local.domain_name}"]
  validation_method         = "DNS"

  lifecycle {
    create_before_destroy = true
  }

  tags = merge(
    var.tags,
    {
      Name        = "wildcard.${local.domain_name}"
      Environment = var.environment
    }
  )
}


# Create DNS validation record for the wildcard subdomain certificate
# ACM certificates with SANs require validation records for each domain
resource "aws_route53_record" "wildcard_cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.wildcard_cert.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  zone_id = aws_route53_zone.subdomain.zone_id
  name    = each.value.name
  type    = each.value.type
  records = [each.value.record]
  ttl     = 60
}


# Validate the wildcard subdomain certificate
resource "aws_acm_certificate_validation" "wildcard_cert_validation" {
  certificate_arn         = aws_acm_certificate.wildcard_cert.arn
  validation_record_fqdns = [for record in aws_route53_record.wildcard_cert_validation : record.fqdn]
}
