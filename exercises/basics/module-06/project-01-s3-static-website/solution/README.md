# S3 Static Website Project - Solution Documentation

## Project Overview

This solution demonstrates a complete S3 static website deployment using Terraform, including bucket creation, public access configuration, website hosting setup, and automated file upload. The project showcases S3 bucket management, security configuration, and Terraform automation for static website hosting.

## Architecture

The solution creates:
- **S3 Bucket**: Globally unique bucket for static website hosting
- **Public Access Block**: Configured to allow public read access
- **Bucket Policy**: Grants public read permissions for website content
- **Website Configuration**: Enables static website hosting with index and error pages
- **File Objects**: HTML files uploaded via Terraform
- **Output**: Website endpoint URL for access

## File Structure

```
solution/
├── providers.tf     # Terraform and AWS provider configuration
├── s3.tf            # S3 bucket, policies, and website configuration
├── outputs.tf       # Website endpoint output
├── build/           # Static website files
│   ├── index.html   # Homepage
│   └── error.html   # Error page
└── README.md        # This documentation
```

## Configuration Files

### providers.tf
- **Terraform Version**: Requires Terraform ~> 1.6
- **AWS Provider**: HashiCorp AWS provider ~> 5.0
- **Random Provider**: HashiCorp random provider ~> 3.0
- **Region**: eu-west-1 (configurable)

### s3.tf
- **Random ID**: Generates unique bucket suffix for global uniqueness
- **S3 Bucket**: Main bucket for static website hosting
- **Public Access Block**: Disabled to allow public read access
- **Bucket Policy**: Grants s3:GetObject permission to anonymous users
- **Website Configuration**: Sets index.html and error.html documents
- **File Objects**: Uploads HTML files with proper content types

### outputs.tf
- **Website Endpoint**: Outputs the public website URL for access

## Key Features

### Global Uniqueness
- **Random Naming**: Uses random_id resource for unique bucket names
- **Collision Avoidance**: Prevents naming conflicts across deployments
- **Idempotent Deployments**: Consistent naming across re-runs

### Public Access Configuration
- **Public Access Block**: Properly configured for static website hosting
- **Security Balance**: Allows public read while maintaining security
- **Principle of Least Privilege**: Only grants necessary permissions

### Website Hosting
- **Index Document**: Default homepage (index.html)
- **Error Document**: Custom error page (error.html)
- **Content Types**: Proper MIME types for HTML files
- **ETag Management**: Uses filemd5() for change detection

### File Management
- **Automated Upload**: Files uploaded via Terraform resources
- **Version Control**: File changes tracked through Terraform state
- **Content Validation**: Proper content types and metadata

## Deployment Instructions

### Prerequisites
- Terraform ~> 1.6 installed
- AWS CLI configured with appropriate credentials
- AWS region access (eu-west-1)
- S3 permissions for bucket creation and management

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

4. **Get Website URL**:
   ```bash
   terraform output static_website_endpoint
   ```

5. **Test Website**:
   - Open the website URL in your browser
   - Verify index.html loads correctly
   - Test error page by accessing non-existent URL

6. **Cleanup**:
   ```bash
   terraform destroy
   ```

## Resource Details

### S3 Bucket Configuration
- **Bucket Name**: `terraform-s3-static-website-demo-{random-hex}`
- **Region**: eu-west-1
- **Versioning**: Not enabled (can be added if needed)
- **Encryption**: Not configured (can be added for production)

### Public Access Block Settings
- **block_public_acls**: false
- **block_public_policy**: false
- **ignore_public_acls**: false
- **restrict_public_buckets**: false

### Bucket Policy
- **Effect**: Allow
- **Principal**: "*" (anonymous public access)
- **Action**: s3:GetObject
- **Resource**: bucket-arn/* (all objects in bucket)

### Website Configuration
- **Index Document**: index.html
- **Error Document**: error.html
- **Website Endpoint**: bucket-name.s3-website-eu-west-1.amazonaws.com

### File Objects
- **index.html**: Homepage with basic HTML structure
- **error.html**: Error page with basic HTML structure
- **Content Type**: text/html
- **ETag**: MD5 hash for change detection

## Best Practices Demonstrated

### Security Best Practices
- **Dedicated Bucket**: Separate bucket for static website content
- **Limited Permissions**: Only s3:GetObject permission granted
- **Public Access Control**: Carefully configured public access blocks
- **Content Validation**: Only public content hosted

### Terraform Best Practices
- **Random Naming**: Prevents naming conflicts
- **Resource Organization**: Logical separation of concerns
- **State Management**: Proper state file management
- **Output Management**: Useful outputs for CI/CD integration

### Cost Management
- **Resource Cleanup**: Always destroy resources after testing
- **Minimal Resources**: Only necessary resources created
- **Monitoring**: Consider CloudWatch for production use

### File Management
- **Automated Upload**: Files managed through Terraform
- **Change Detection**: ETag-based change detection
- **Content Types**: Proper MIME type configuration
- **Version Control**: File changes tracked in state

## Troubleshooting

### Common Issues
1. **Access Denied**: Check public access block and bucket policy
2. **Bucket Name Conflicts**: Ensure random naming is working
3. **Website Not Loading**: Verify website configuration and endpoint
4. **File Upload Issues**: Check file paths and content types

### Diagnostic Commands
```bash
# Validate configuration
terraform validate

# Check plan
terraform plan

# Show current state
terraform show

# List resources
terraform state list

# Test website endpoint
curl $(terraform output -raw static_website_endpoint)
```

### Access Denied Troubleshooting
1. **Verify Public Access Block**: All blocks should be disabled
2. **Check Bucket Policy**: Ensure policy allows s3:GetObject
3. **Confirm Endpoint**: Use website endpoint, not REST API endpoint
4. **Review Resource ARN**: Ensure /* is included for object access

## Security Considerations

### Public Access
- **Content Validation**: Only host public content
- **Access Monitoring**: Consider CloudTrail for access logs
- **Regular Audits**: Review permissions and access patterns
- **Content Security**: Ensure no sensitive information in files

### Production Recommendations
- **CloudFront**: Add CDN for better performance and security
- **HTTPS**: Use CloudFront for HTTPS support
- **Monitoring**: Implement CloudWatch monitoring
- **Backup**: Consider versioning and backup strategies

## Learning Outcomes

This project demonstrates:
- **S3 Configuration**: Complete S3 static website setup
- **Security Management**: Proper public access configuration
- **Terraform Integration**: End-to-end infrastructure automation
- **File Management**: Automated file upload and versioning
- **Troubleshooting**: Common issues and resolution strategies
- **Global Uniqueness**: S3 bucket naming requirements
- **CI/CD Integration**: Outputs for automation workflows

## Next Steps (TODO)

After completing this project:
1. Add CloudFront distribution for CDN
2. Implement HTTPS with SSL certificates
3. Add monitoring and logging
4. Explore S3 versioning and lifecycle policies
5. Implement automated testing for website deployment
6. Add custom domain configuration
7. Explore S3 website redirects and routing rules
