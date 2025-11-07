output "hosted_zone_id" {
  description = "ID of the Route53 hosted zone"
  value       = aws_route53_zone.subdomain.zone_id
}

output "hosted_zone_name" {
  description = "Name of the Route53 hosted zone"
  value       = aws_route53_zone.subdomain.name
}

output "name_servers" {
  description = "Name servers for the hosted zone (to configure at domain registrar)"
  value       = aws_route53_zone.subdomain.name_servers
}

output "hosted_zone_arn" {
  description = "ARN of the Route53 hosted zone"
  value       = aws_route53_zone.subdomain.arn
}

output "certificate_arn" {
  description = "ARN of the ACM certificate (wildcard certificate for the subdomain)"
  value       = aws_acm_certificate_validation.wildcard_cert_validation.certificate_arn
}

output "certificate_domain" {
  description = "Primary domain name of the certificate"
  value       = aws_acm_certificate.wildcard_cert.domain_name
}
