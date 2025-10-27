# AMI Data Source Exercise - Solution

## Quick Reference

This solution demonstrates multiple AWS data sources working together:

### Data Sources Used
- **AMI**: Ubuntu ARM64 AMI selection (`t4g.micro` compatible)
- **Caller Identity**: Current AWS account information
- **Region**: Current AWS region (eu-west-1)
- **VPC**: Existing VPC by `Env = "Prod"` tag
- **Availability Zones**: Available AZs in region
- **IAM Policy Document**: S3 public read policy

### Key Configuration
- **Architecture**: ARM64 AMI + t4g.micro instance (cost-effective)
- **AMI Owner**: Canonical (099720109477) for Ubuntu
- **Prerequisites**: VPC with `Env = "Prod"` tag must exist

### Quick Commands
```bash
terraform init
terraform plan
terraform apply
terraform output
terraform destroy
```

### Expected Outputs
- `ubuntu_ami_data`: Selected AMI ID
- `aws_caller_identity`: Account/user information
- `aws_region`: Current region details
- `aws_vpc_id`: Existing VPC ID
- `azs`: Available availability zones
- `iam_policy`: Generated policy JSON

## Troubleshooting
- **VPC Not Found**: Create VPC with `Env = "Prod"` tag
- **Architecture Mismatch**: AMI and instance type must match (ARM64)
- **AMI Not Found**: Check Ubuntu ARM64 availability in region
