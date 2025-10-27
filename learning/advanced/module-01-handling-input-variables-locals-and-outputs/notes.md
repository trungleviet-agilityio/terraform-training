# Module 01 – Handling Input Variables, Locals, and Outputs

## Learning Objectives
- Master Terraform input variables for dynamic configuration customization
- Understand variable types, validation, and sensitivity handling
- Learn variable precedence and override mechanisms
- Implement locals for reusable computed values
- Create and manage outputs for resource information exposure
- Apply best practices for multi-environment deployments

## Session Notes

### 1. Understanding Terraform Input Variables

#### What are Input Variables?
- **Purpose**: Enable customization of Terraform configurations without modifying code
- **Benefits**: 
  - Reusability across environments (dev, staging, prod)
  - Dynamic configuration without code changes
  - Environment-agnostic deployments
  - Team collaboration and configuration management

#### Variable Declaration Syntax
```hcl
variable "variable_name" {
  type        = string
  description = "Description of the variable"
  default     = "default_value"
  
  validation {
    condition     = contains(["value1", "value2"], var.variable_name)
    error_message = "Custom error message"
  }
}
```

### 2. Variable Types and Validation

#### Common Variable Types
| Type | Use Case | Example |
|------|----------|---------|
| `string` | Text values | `region`, `environment` |
| `number` | Numeric values | `instance_count`, `volume_size` |
| `bool` | True/false flags | `enable_monitoring` |
| `list` | Ordered collections | `availability_zones` |
| `map` | Key-value pairs | `tags` |
| `object` | Structured data | `volume_config` |
| `any` | Flexible inputs | Use sparingly |

#### Object Type Example
```hcl
variable "ec2_volume_config" {
  type = object({
    size = number
    type = string
  })
  description = "EC2 volume configuration"
  
  default = {
    size = 10
    type = "gp3"
  }
}
```

#### Variable Validation
```hcl
variable "ec2_instance_type" {
  type        = string
  default     = "t2.micro"
  description = "EC2 instance type"
  
  validation {
    condition     = contains(["t2.micro", "t3.micro", "t3.large"], var.ec2_instance_type)
    error_message = "Only t2.micro, t3.micro, and t3.large instances are supported"
  }
}
```

### 3. Sensitive Variables

#### Why Mark Variables as Sensitive?
- **Security**: Prevent exposure in logs, CLI output, and state diffs
- **Compliance**: Meet security requirements for sensitive data
- **Team Safety**: Avoid accidental secret exposure

#### Sensitive Variable Declaration
```hcl
variable "my_sensitive_value" {
  type      = string
  sensitive = true
}
```

#### Sensitive Output
```hcl
output "sensitive_var" {
  sensitive = true
  value     = var.my_sensitive_value
}
```

#### Limitations and Considerations
- **State File**: Sensitive data still exists in plaintext in state files
- **Remote Backend**: Use encrypted remote backends (S3 + DynamoDB, Terraform Cloud)
- **Propagation**: Derived values automatically become sensitive
- **Usage Restrictions**: Cannot use in certain expressions requiring plaintext
- **CI/CD**: Raw values still passed to cloud APIs

### 4. Variable Precedence and Overrides

#### Order of Precedence (Highest to Lowest)
1. **CLI `-var` flag**: `terraform apply -var="region=us-east-1"`
2. **CLI `-var-file` flag**: `terraform apply -var-file="prod.tfvars"`
3. **Auto-loaded `.auto.tfvars` files**: `production.auto.tfvars`
4. **`terraform.tfvars` file**: Standard project defaults
5. **Environment variables**: `TF_VAR_region="us-west-2"`
6. **Default values**: `default = "dev"`

#### File-Based Variable Loading
```hcl
# terraform.tfvars
ec2_instance_type = "t2.micro"
ec2_volume_config = {
  size = 10
  type = "gp2"
}
additional_tags = {
  Environment = "dev"
}
```

```hcl
# prod.auto.tfvars (automatically loaded)
ec2_instance_type = "t3.large"
ec2_volume_config = {
  size = 20
  type = "gp3"
}
additional_tags = {
  Environment = "production"
}
```

### 5. Working with Locals

#### What are Locals?
- **Purpose**: Define computed values reusable within a module
- **Benefits**: 
  - Avoid repetition
  - Centralize configuration
  - Improve readability
  - Enable complex expressions

#### Local Declaration
```hcl
locals {
  project       = "advanced-input-vars-locals-outputs"
  project_owner = "terraform-course"
  cost_center   = "1234"
  managed_by    = "Terraform"
}
```

#### Common Tags Pattern
```hcl
locals {
  common_tags = {
    project       = local.project
    project_owner = local.project_owner
    cost_center   = local.cost_center
    managed_by    = local.managed_by
  }
}
```

#### Using Locals in Resources
```hcl
resource "aws_instance" "compute" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = var.ec2_instance_type
  
  tags = merge(local.common_tags, var.additional_tags)
}

resource "aws_s3_bucket" "project_bucket" {
  bucket = "${local.project}-${random_id.project_bucket_suffix.hex}"
  
  tags = merge(local.common_tags, var.additional_tags)
}
```

### 6. Working with Outputs

#### What are Outputs?
- **Purpose**: Expose information about resources and modules
- **Benefits**:
  - Resource information access
  - Integration with other systems
  - State inspection
  - Module communication

#### Output Declaration
```hcl
output "s3_bucket_name" {
  value       = aws_s3_bucket.project_bucket.bucket
  description = "The name of the S3 bucket"
  sensitive   = false
}
```

#### Sensitive Outputs
```hcl
output "sensitive_var" {
  sensitive = true
  value     = var.my_sensitive_value
}
```

#### Retrieving Outputs
```bash
# Get output value
terraform output s3_bucket_name

# Get raw value (no quotes)
terraform output -raw s3_bucket_name

# Get all outputs
terraform output
```

### 7. Real-World Application: Multi-Region Deployment

#### Scenario: Mia's Multi-Region Setup
Mia needs to deploy AWS resources across multiple regions using the same Terraform configuration.

#### Step 1: Define Variables
```hcl
variable "aws_region" {
  description = "AWS region for resource deployment"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "bucket_name_prefix" {
  description = "Prefix for S3 bucket name"
  type        = string
}
```

#### Step 2: Use Variables in Resources
```hcl
provider "aws" {
  region = var.aws_region
}

resource "aws_s3_bucket" "app_bucket" {
  bucket = "${var.bucket_name_prefix}-${var.aws_region}"
}

resource "aws_instance" "app_server" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = var.instance_type
  
  tags = {
    Name = "server-${var.aws_region}"
  }
}
```

#### Step 3: Environment-Specific Files
```hcl
# dev.tfvars
aws_region = "us-east-1"
bucket_name_prefix = "myapp-dev"

# prod.tfvars
aws_region = "eu-west-1"
bucket_name_prefix = "myapp-prod"
```

#### Step 4: Deploy per Environment
```bash
# Development
terraform apply -var-file="dev.tfvars"

# Production
terraform apply -var-file="prod.tfvars"
```

### 8. Best Practices

#### Variable Best Practices
- **Descriptions**: Always provide clear descriptions
- **Types**: Use specific types instead of `any`
- **Defaults**: Provide sensible defaults when possible
- **Validation**: Add validation rules for critical variables
- **Sensitivity**: Mark sensitive data appropriately

#### Local Best Practices
- **Organization**: Group related locals together
- **Naming**: Use descriptive names
- **File Structure**: Consider separate `locals.tf` file
- **Complex Logic**: Use locals for complex expressions

#### Output Best Practices
- **Descriptions**: Document output purpose
- **Sensitivity**: Mark sensitive outputs appropriately
- **Selective Exposure**: Only output necessary information
- **Naming**: Use clear, descriptive names

#### Security Best Practices
- **Remote State**: Use encrypted remote backends
- **Secret Management**: Integrate with secret managers
- **CI/CD**: Sanitize logs and use secure pipelines
- **Access Control**: Implement proper IAM policies

### 9. Common Patterns and Anti-Patterns

#### Good Patterns
```hcl
# Centralized configuration
locals {
  common_tags = {
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "Terraform"
  }
}

# Variable validation
variable "environment" {
  type        = string
  description = "Deployment environment"
  
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod"
  }
}

# Sensitive handling
variable "db_password" {
  type      = string
  sensitive = true
}
```

#### Anti-Patterns to Avoid
```hcl
# ❌ Hardcoded values
resource "aws_instance" "web" {
  instance_type = "t2.micro"  # Should be variable
}

# ❌ No validation
variable "instance_type" {
  type = string  # Should validate allowed values
}

# ❌ Sensitive data in plaintext
variable "api_key" {
  type = string  # Should be sensitive = true
}

# ❌ No descriptions
variable "region" {
  type = string  # Should have description
}
```

### 10. Troubleshooting Common Issues

#### Variable Resolution Issues
- **No Default**: Variables without defaults become required
- **Type Mismatch**: Ensure variable types match usage
- **Precedence**: Check variable precedence order
- **File Loading**: Verify `.tfvars` file naming and location

#### Sensitive Value Issues
- **State Exposure**: Sensitive data visible in state file
- **Expression Limitations**: Cannot use in certain contexts
- **Output Masking**: Sensitive outputs masked in logs
- **Retrieval**: Use `terraform output` to get sensitive values

#### Local Issues
- **Scope**: Locals only available within module
- **Dependencies**: Ensure referenced resources exist
- **Complexity**: Avoid overly complex local expressions

## Key Concepts Summary

### Essential Variable Concepts
- **Input Variables**: Customize configurations without code changes
- **Variable Types**: String, number, bool, list, map, object, any
- **Validation**: Enforce constraints and provide error messages
- **Sensitivity**: Protect sensitive data from exposure
- **Precedence**: CLI flags override file-based values

### Local Concepts
- **Computed Values**: Reusable expressions within modules
- **Common Tags**: Centralized tagging strategy
- **Organization**: Separate files for better structure
- **Scope**: Module-level availability

### Output Concepts
- **Information Exposure**: Share resource details
- **Integration**: Connect with other systems
- **Sensitivity**: Control information visibility
- **Retrieval**: Command-line access to values

### Best Practices
- **Documentation**: Clear descriptions and comments
- **Validation**: Enforce business rules
- **Security**: Protect sensitive information
- **Organization**: Logical file structure
- **Testing**: Validate configurations across environments

## Exercise References
- **Exercise 14**: AWS Region Variables - Dynamic region configuration
- **Exercise 15**: EC2 Instance Size and Volume - Variable validation and customization
- **Exercise 16**: Objects for Volume Configuration - Structured variable types
- **Exercise 17**: Working with tfvars - File-based variable management
- **Exercise 18**: Auto tfvars - Automatic file loading
- **Exercise 19**: Working with Locals - Computed values and common tags
- **Exercise 20**: Working with Outputs - Resource information exposure
- **Exercise 21**: Sensitive Values - Security and sensitive data handling

## Key Takeaways
- **Variables**: Enable dynamic, reusable configurations across environments
- **Types**: Use specific types and validation for robust configurations
- **Sensitivity**: Protect sensitive data with appropriate marking
- **Precedence**: Understand variable resolution order for predictable behavior
- **Locals**: Centralize computed values and common configurations
- **Outputs**: Expose necessary information for integration and monitoring
- **Best Practices**: Documentation, validation, security, and organization
- **Real-World**: Apply patterns for multi-environment deployments
