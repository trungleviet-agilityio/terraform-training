# Module 06 – Deploying an S3 Static Website

## Learning Objectives
- Understand how to create and configure S3 buckets for static website hosting
- Learn about S3 bucket naming requirements and global uniqueness
- Master S3 public access configuration and security considerations
- Understand S3 bucket policies for public read access
- Learn S3 website configuration and error handling
- Explore Terraform outputs for CI/CD integration
- Troubleshoot common "Access Denied" errors in S3 static websites

## Session Notes

### 1. S3 Bucket Creation
- **Global Uniqueness**: S3 bucket names must be globally unique across all AWS accounts and regions
- **Naming Challenge**: No two S3 buckets in the entire world can share the same name
- **Automation Requirement**: Need programmatic uniqueness for CI/CD and multiple deployments
- **Exercise Reference**: `exercises/basics/module-06/project-01-s3-static-website/README.md`

#### Ensuring Unique Bucket Names
- **Random Provider**: Use `random_id` or `random_string` resources for programmatic uniqueness
- **Deterministic Randomness**: Generated values stored in state file, ensuring idempotent deployments
- **Collision Avoidance**: Prevents naming conflicts across environments and team members
- **Best Practice**: Combine random generation with project/environment variables for readable names

#### Random ID Resource Example
```hcl
resource "random_id" "bucket_suffix" {
  byte_length = 4
}

resource "aws_s3_bucket" "static_website_bucket" {
  bucket = "terraform-s3-static-website-demo-${random_id.bucket_suffix.hex}"
}
```

#### Random String Resource Example
```hcl
resource "random_string" "bucket_suffix" {
  length  = 8
  special = false
  upper   = false
}

resource "aws_s3_bucket" "static_website_bucket" {
  bucket = "my-website-${random_string.bucket_suffix.result}"
}
```

#### Key Benefits of Random Naming
- **Idempotent Deployments**: Re-runs don't create new buckets unless forced
- **Multi-Environment Support**: Different environments get unique bucket names
- **Team Collaboration**: Multiple developers can deploy without conflicts
- **CI/CD Integration**: Automated deployments work reliably

### 2. Public Access and Bucket Policy
- **Public Access Block**: AWS safety mechanism to prevent accidental public exposure
- **Static Website Requirement**: Must disable public access blocks for website hosting
- **Security Considerations**: Balance between public access and security
- **Exercise Reference**: `exercises/basics/module-06/project-01-s3-static-website/solution/s3.tf`

#### Understanding Public Access Block
- **Purpose**: Guardrail to prevent accidental public exposure of sensitive data
- **Override Behavior**: Blocks public access even if bucket policy allows it
- **Static Website Impact**: Must be disabled for public website access
- **Security Layer**: Additional protection against misconfigurations

#### Public Access Block Configuration
```hcl
resource "aws_s3_bucket_public_access_block" "static_website" {
  bucket                  = aws_s3_bucket.static_website_bucket.id
  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}
```

#### Security Implications for Developers
- **Dedicated Buckets**: Use separate buckets for static websites
- **Limited Permissions**: Restrict to `s3:GetObject` only
- **Specific Buckets**: Disable public access only for website buckets
- **CloudFront Integration**: Consider CDN for additional control

#### Safe Static Website Pattern
- **Non-Sensitive Content**: Only host public content in website buckets
- **Read-Only Access**: Limit permissions to object retrieval
- **Isolated Resources**: Separate website buckets from sensitive data
- **Monitoring**: Implement logging and monitoring for access patterns

### 3. S3 Website Configuration
- **Website Hosting**: Enable S3 bucket to serve static website content
- **Index Document**: Define default homepage (index.html)
- **Error Document**: Define custom error page (error.html)
- **Website Endpoint**: Generate public URL for website access
- **Exercise Reference**: `exercises/basics/module-06/project-01-s3-static-website/solution/s3.tf`

#### S3 Website Configuration Resource
```hcl
resource "aws_s3_bucket_website_configuration" "static_website" {
  bucket = aws_s3_bucket.static_website_bucket.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "error.html"
  }
}
```

#### Website Configuration Components
- **Index Document**: Default page served when accessing root URL
- **Error Document**: Custom error page for 404 and other errors
- **Website Endpoint**: Public URL format: `bucket-name.s3-website-region.amazonaws.com`
- **Content Types**: Proper MIME types for HTML files

#### File Upload with Terraform
```hcl
resource "aws_s3_object" "index_html" {
  bucket       = aws_s3_bucket.static_website_bucket.id
  key          = "index.html"
  source       = "build/index.html"
  etag         = filemd5("build/index.html")
  content_type = "text/html"
}

resource "aws_s3_object" "error_html" {
  bucket       = aws_s3_bucket.static_website_bucket.id
  key          = "error.html"
  source       = "build/error.html"
  etag         = filemd5("build/error.html")
  content_type = "text/html"
}
```

#### File Upload Best Practices
- **ETag Management**: Use `filemd5()` for proper change detection
- **Content Types**: Set appropriate MIME types for files
- **Source Paths**: Use relative paths from Terraform working directory
- **Version Control**: Track file changes through Terraform state

### 4. Bucket Policy for Public Access
- **Public Read Policy**: Allow anonymous users to read website content
- **Principle of Least Privilege**: Grant only necessary permissions
- **Resource Scope**: Apply policy to all objects in bucket
- **Security Considerations**: Balance accessibility with security

#### Public Read Bucket Policy
```hcl
resource "aws_s3_bucket_policy" "static_website_public_read_access" {
  bucket = aws_s3_bucket.static_website_bucket.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.static_website_bucket.arn}/*"
      }
    ]
  })
}
```

#### Bucket Policy Components
- **Effect**: "Allow" - explicitly permit the action
- **Principal**: "*" - anonymous public access
- **Action**: "s3:GetObject" - read-only access to objects
- **Resource**: "bucket-arn/*" - applies to all objects in bucket

#### Policy Security Considerations
- **Read-Only Access**: Only allow `s3:GetObject`, not `s3:PutObject` or `s3:DeleteObject`
- **Object-Level**: Apply to objects (`/*`) not bucket itself
- **No List Access**: Avoid `s3:ListBucket` unless specifically needed
- **Audit Trail**: Consider CloudTrail for access monitoring

### 5. Terraform Outputs for CI/CD
- **Website Endpoint**: Output the public URL for website access
- **CI/CD Integration**: Enable automation workflows to access deployed website
- **Testing Automation**: Allow automated testing of deployed website
- **Deployment Validation**: Verify successful deployment through outputs

#### Website Endpoint Output
```hcl
output "static_website_endpoint" {
  value = aws_s3_bucket_website_configuration.static_website.website_endpoint
}
```

#### CI/CD Integration Benefits
- **Automated Testing**: Use endpoint URL for automated website testing
- **Deployment Validation**: Verify website is accessible after deployment
- **Notification Systems**: Send deployment URLs to team members
- **Monitoring Integration**: Set up monitoring for website availability

#### Output Usage Examples
- **Testing**: `curl $(terraform output -raw static_website_endpoint)`
- **Documentation**: Include endpoint in deployment documentation
- **Monitoring**: Configure health checks using endpoint URL
- **Integration**: Pass endpoint to other systems in CI/CD pipeline

### 6. Troubleshooting "Access Denied" Errors
- **Common Issue**: Most frequent problem with S3 static websites
- **Root Cause**: Usually permissions chain problem, not deployment issue
- **Diagnostic Steps**: Systematic approach to identify and resolve issues
- **Prevention**: Proper configuration prevents most access issues

#### Common Causes of Access Denied Errors
- **Public Access Block**: Still enabled, blocking public access
- **Bucket Policy Issues**: Missing or incorrect policy configuration
- **Wrong Endpoint**: Using REST API endpoint instead of website endpoint
- **Object ACL**: Conflicting ACL settings
- **Resource ARN**: Missing `/*` in resource specification

#### Diagnostic Checklist
1. **Verify Public Access Block**: Ensure all blocks are disabled
2. **Check Bucket Policy**: Validate policy JSON syntax and permissions
3. **Confirm Endpoint**: Use website endpoint, not REST API endpoint
4. **Review Resource ARN**: Ensure `/*` is included for object access
5. **Test Policy**: Use AWS Policy Simulator if available

#### Bucket Policy Troubleshooting
- **Effect**: Must be "Allow", not "Deny"
- **Principal**: Must be "*" for public access
- **Action**: Must include "s3:GetObject"
- **Resource**: Must end with `/*` for object access
- **JSON Syntax**: Ensure valid JSON format

#### Common Policy Mistakes
- **Missing `/*`**: Resource points to bucket, not objects
- **Wrong Principal**: Specific AWS account instead of "*"
- **Missing Action**: No `s3:GetObject` permission
- **Deny Statements**: Conflicting deny rules
- **Syntax Errors**: Invalid JSON in policy document

### 7. Complete S3 Static Website Project
- **Project Goal**: Deploy a complete static website using S3 and Terraform
- **Learning Focus**: End-to-end static website deployment
- **Components**: Bucket creation, public access, website configuration, file upload
- **Exercise Reference**: `exercises/basics/module-06/project-01-s3-static-website/README.md`

#### Project Steps Overview
1. **Create S3 Bucket**: With unique name using random provider
2. **Disable Public Access Block**: Allow public read access
3. **Create Bucket Policy**: Grant public read permissions
4. **Configure Website Hosting**: Set index and error documents
5. **Upload Website Files**: Deploy HTML files to bucket
6. **Test Website**: Verify public access and functionality
7. **Output Endpoint**: Provide website URL for access
8. **Clean Up**: Destroy resources to avoid costs

#### Project Learning Outcomes
- **S3 Configuration**: Complete understanding of S3 static website setup
- **Security Management**: Proper public access configuration
- **Terraform Integration**: End-to-end infrastructure automation
- **File Management**: Automated file upload and versioning
- **Troubleshooting**: Common issues and resolution strategies

## Key S3 Static Website Concepts

### Essential Components
- **S3 Bucket**: Container for website files
- **Public Access Block**: Security configuration for public access
- **Bucket Policy**: Permissions for public read access
- **Website Configuration**: Index and error document settings
- **File Objects**: HTML files uploaded to bucket
- **Website Endpoint**: Public URL for website access

### Security Best Practices
- **Dedicated Buckets**: Use separate buckets for static websites
- **Limited Permissions**: Grant only necessary read access
- **Content Validation**: Ensure only public content is hosted
- **Access Monitoring**: Implement logging and monitoring
- **Regular Audits**: Review permissions and access patterns

### Terraform Best Practices
- **Random Naming**: Use random providers for unique bucket names
- **State Management**: Proper state file management for consistency
- **Output Management**: Provide useful outputs for CI/CD integration
- **Resource Tagging**: Implement consistent tagging strategy
- **Cleanup**: Always destroy resources to avoid costs

## Common Issues and Solutions

### Access Denied Errors
- **Cause**: Public access block enabled or incorrect bucket policy
- **Solution**: Disable public access blocks and verify bucket policy
- **Prevention**: Use Terraform to ensure consistent configuration

### Bucket Name Conflicts
- **Cause**: Non-unique bucket names across deployments
- **Solution**: Use random providers for unique naming
- **Prevention**: Implement naming conventions with random suffixes

### Website Not Loading
- **Cause**: Missing website configuration or incorrect endpoint
- **Solution**: Configure website hosting and use correct endpoint
- **Prevention**: Include website configuration in Terraform

### File Upload Issues
- **Cause**: Incorrect file paths or missing content types
- **Solution**: Use relative paths and set proper content types
- **Prevention**: Validate file paths and content types in Terraform

## Key Takeaways
- **Global Uniqueness**: S3 bucket names must be globally unique
- **Public Access**: Proper configuration required for public website access
- **Security Balance**: Balance accessibility with security considerations
- **Terraform Integration**: Complete automation of static website deployment
- **CI/CD Ready**: Outputs enable integration with automation workflows
- **Troubleshooting**: Systematic approach to resolve common issues
- **Best Practices**: Follow security and operational best practices

## Practical Learning Path
1. **Start Simple**: Begin with basic S3 bucket creation
2. **Add Public Access**: Configure public access blocks and policies
3. **Enable Website Hosting**: Set up website configuration
4. **Upload Content**: Deploy HTML files using Terraform
5. **Test and Validate**: Verify website accessibility
6. **Integrate CI/CD**: Use outputs for automation workflows
7. **Troubleshoot Issues**: Practice resolving common problems

## Practical Exercises Summary
- **Project 1**: S3 Static Website - Complete static website deployment with Terraform

## Exercise References
- **Project 1**: `exercises/basics/module-06/project-01-s3-static-website/README.md`
- **Solution Reference**: `exercises/basics/module-06/project-01-s3-static-website/solution/`
