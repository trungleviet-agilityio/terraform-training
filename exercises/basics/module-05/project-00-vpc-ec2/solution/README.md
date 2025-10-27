# VPC and EC2 Project - Solution Documentation

## Project Overview

This solution demonstrates a complete AWS infrastructure deployment using Terraform, including VPC, subnets, security groups, and an EC2 instance running NGINX. The project showcases Terraform resource management, dependencies, and best practices.

## Architecture

The solution creates:
- **VPC**: Virtual Private Cloud with CIDR block 10.0.0.0/16
- **Public Subnet**: 10.0.0.0/24 with internet access
- **Internet Gateway**: Enables internet connectivity
- **Route Table**: Routes traffic to internet gateway
- **Security Group**: Allows HTTP (80) and HTTPS (443) traffic
- **EC2 Instance**: NGINX server with public IP

## File Structure

```
solution/
├── provider.tf      # Terraform and AWS provider configuration
├── networking.tf     # VPC, subnet, internet gateway, and routing
├── compute.tf        # EC2 instance and security groups
└── README.md         # This documentation
```

## Configuration Files

### provider.tf
- **Terraform Version**: Requires Terraform ~> 1.6
- **AWS Provider**: HashiCorp AWS provider ~> 5.0
- **Region**: eu-west-1 (configurable)

### networking.tf
- **Common Tags**: Centralized tagging strategy using locals
- **VPC**: Main VPC with 10.0.0.0/16 CIDR block
- **Public Subnet**: 10.0.0.0/24 subnet for public resources
- **Internet Gateway**: Enables internet access for VPC
- **Route Table**: Routes 0.0.0.0/0 traffic to internet gateway
- **Route Table Association**: Associates public subnet with route table

### compute.tf
- **EC2 Instance**: NGINX server with t2.micro instance type
- **Security Group**: Allows HTTP and HTTPS traffic from anywhere
- **Root Block Device**: 10GB gp3 volume with termination protection
- **Lifecycle Management**: create_before_destroy for zero-downtime updates

## Key Features

### Resource Dependencies
- **Implicit Dependencies**: Terraform automatically detects dependencies
- **VPC Dependencies**: Subnet depends on VPC, EC2 depends on subnet
- **Security Group Dependencies**: EC2 instance depends on security group

### Tagging Strategy
- **Common Tags**: ManagedBy, Project, CostCenter applied to all resources
- **Resource-Specific Tags**: Name tags for individual resource identification
- **Cost Management**: Enables cost tracking and resource organization

### Security Implementation
- **Security Groups**: Restrictive inbound rules (HTTP/HTTPS only)
- **Public Access**: EC2 instance has public IP for web access
- **Network Isolation**: VPC provides network isolation

### Lifecycle Management
- **create_before_destroy**: Prevents downtime during instance updates
- **Delete on Termination**: Root volume deleted when instance terminates
- **Volume Configuration**: Optimized storage with gp3 volume type

## Deployment Instructions

### Prerequisites
- Terraform ~> 1.6 installed
- AWS CLI configured with appropriate credentials
- AWS region access (eu-west-1)

### Deployment Steps
1. **Initialize Terraform**:
   ```bash
   terraform init
   ```

2. **Review Plan**:
   ```bash
   terraform plan
   ```

3. **Apply Configuration**:
   ```bash
   terraform apply
   ```

4. **Test Access**:
   - Get public IP from Terraform output
   - Access http://<public-ip> for NGINX welcome page
   - Access https://<public-ip> (ignore certificate warning)

5. **Cleanup**:
   ```bash
   terraform destroy
   ```

## Resource Details

### VPC Configuration
- **CIDR Block**: 10.0.0.0/16
- **DNS Support**: Enabled by default
- **DNS Hostnames**: Enabled by default

### Subnet Configuration
- **CIDR Block**: 10.0.0.0/24
- **Availability Zone**: eu-west-1a (default)
- **Public IP**: Auto-assign public IP enabled

### Security Group Rules
- **HTTP (Port 80)**: Allow from 0.0.0.0/0
- **HTTPS (Port 443)**: Allow from 0.0.0.0/0
- **Outbound**: All traffic allowed (default)

### EC2 Instance
- **AMI**: Ubuntu Server 22.04 LTS (ami-0652a081025ec9fee)
- **Instance Type**: t3.micro (cost-effective micro instance)
- **Storage**: 10GB gp3 root volume
- **Public IP**: Automatically assigned
- **User Data**: Installs and configures NGINX automatically

## Best Practices Demonstrated

### Resource Organization
- **Logical Separation**: Networking and compute resources in separate files
- **Clear Naming**: Descriptive resource names and tags
- **Consistent Tagging**: Centralized tag management

### Security Best Practices
- **Principle of Least Privilege**: Minimal security group rules
- **Network Isolation**: VPC provides network boundary
- **Public Access Control**: Only necessary ports exposed

### Cost Management
- **Free Tier Resources**: t2.micro instance and gp3 storage
- **Resource Cleanup**: Always destroy resources after testing
- **Cost Tracking**: Comprehensive tagging for cost allocation

### Terraform Best Practices
- **Version Constraints**: Specific Terraform and provider versions
- **Resource Dependencies**: Leveraging implicit dependencies
- **Lifecycle Management**: Proper resource lifecycle handling
- **Validation**: Always validate before applying

## Troubleshooting

### Common Issues
1. **AMI Not Found**: Ensure you're in the correct region
2. **Security Group Rules**: Verify HTTP/HTTPS ports are open
3. **Public IP Access**: Check if instance has public IP assigned
4. **Certificate Warnings**: Normal for self-signed certificates

### Validation Commands
```bash
# Validate configuration
terraform validate

# Check plan
terraform plan

# Show current state
terraform show

# List resources
terraform state list
```

## Learning Outcomes

This project demonstrates:
- **Resource Definition**: Proper Terraform resource configuration
- **Dependency Management**: How Terraform handles resource dependencies
- **Security Implementation**: Security group configuration
- **Tagging Strategy**: Consistent resource tagging
- **Lifecycle Management**: Resource lifecycle best practices
- **Cost Management**: Resource cleanup and cost tracking

## Next Steps (TODO)

After completing this project:
1. Explore additional AWS resources (RDS, S3, etc.)
2. Implement modules for reusable infrastructure
3. Add variables for configuration flexibility
4. Implement remote state management
5. Explore advanced Terraform features (workspaces, providers)
