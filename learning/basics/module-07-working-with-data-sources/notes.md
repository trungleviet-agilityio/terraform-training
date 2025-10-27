# Module 07 – Working with Data Sources

## Learning Objectives
- Understand what Terraform data sources are and their primary purpose
- Learn how to use data sources to retrieve existing infrastructure information
- Master filtering techniques for precise resource identification
- Understand the difference between data sources and resources
- Learn common AWS data sources and their use cases
- Practice chaining data sources for complex infrastructure queries
- Handle architecture compatibility issues (x86_64 vs ARM64)

## Session Notes

### 1. Understanding Terraform Data Sources
- **Definition**: Data sources allow Terraform to query or retrieve data from remote APIs or other Terraform projects
- **Primary Purpose**: Make Terraform configurations dynamic and reusable by referencing existing infrastructure
- **Key Characteristics**:
  - Read-only access to existing resources
  - No modification of the original resources
  - API calls during the plan phase
  - Results cached in Terraform state
  - Enable referencing infrastructure managed by other teams/projects

#### What are Data Sources?
- **Dynamic Lookups**: Allow Terraform to fetch up-to-date information from cloud providers
- **External Integration**: Reference infrastructure not managed by current Terraform project
- **API Interaction**: Terraform reaches out to provider APIs to find existing resources
- **No Management**: Data sources don't manage or modify the referenced resources
- **State Caching**: Retrieved information is cached in Terraform state for consistency

#### Common Use Cases
- **Existing Infrastructure**: Reference VPCs, subnets, or roles managed by other teams
- **Dynamic AMI Selection**: Always use the latest AMI without hardcoding IDs
- **Account Information**: Get current AWS account ID, region, or caller identity
- **Policy Documents**: Generate IAM policies dynamically
- **Resource Discovery**: Find existing resources based on tags or other criteria

### 2. Data Source vs Resource Blocks
- **Resource Blocks**: Create, modify, and manage infrastructure resources
- **Data Source Blocks**: Read-only access to existing infrastructure information
- **Key Differences**:
  - Resources: `resource "aws_instance" "web" {}`
  - Data Sources: `data "aws_vpc" "existing" {}`
  - Resources manage lifecycle (create, update, destroy)
  - Data sources only read information

#### Data Source Syntax
```hcl
data "provider_type" "local_name" {
  # Configuration arguments
  filter {
    name   = "filter_name"
    values = ["filter_value"]
  }
}
```

### 3. AWS AMI Data Source
- **Purpose**: Retrieve Amazon Machine Image information dynamically
- **Benefits**: Always use latest AMI without hardcoding IDs
- **Common Use Cases**: EC2 instance deployment, auto-scaling groups

#### AMI Data Source Configuration
```hcl
data "aws_ami" "ubuntu" {
  executable_users = ["self"]
  most_recent      = true
  owners           = ["099720109477"]  # Canonical (Ubuntu)

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]  # or ["arm64"] for ARM instances
  }
}
```

#### Key AMI Data Source Arguments
- **`most_recent`**: Get the latest AMI matching criteria
- **`owners`**: AMI owner IDs (e.g., Canonical: "099720109477", Amazon: "amazon")
- **`executable_users`**: Users who can use the AMI
- **`filter`**: Criteria for AMI selection

#### Common AMI Owners
- **Canonical (Ubuntu)**: `"099720109477"`
- **Amazon**: `"amazon"`
- **Microsoft**: `"801119661308"`
- **Red Hat**: `"309956199498"`

#### Architecture Compatibility
- **x86_64 Architecture**: Use `t3.micro`, `t2.micro` instance types
- **ARM64 Architecture**: Use `t4g.micro`, `t4g.small` instance types
- **Architecture Filter**: Always specify architecture to avoid mismatches
- **Error Prevention**: Match AMI architecture with instance type architecture

### 4. AWS VPC Data Source
- **Purpose**: Retrieve information about existing VPCs
- **Use Cases**: Reference VPCs managed by other teams or projects
- **Filtering Options**: Tags, VPC ID, CIDR blocks

#### VPC Data Source Configuration
```hcl
data "aws_vpc" "production" {
  filter {
    name   = "tag:Name"
    values = ["production-vpc"]
  }
}

# Alternative: Filter by VPC ID
data "aws_vpc" "existing" {
  id = "vpc-12345678"
}

# Alternative: Filter by tags
data "aws_vpc" "prod_vpc" {
  tags = {
    Environment = "Production"
    Owner       = "DevOps"
  }
}
```

#### VPC Data Source Attributes
- **`id`**: VPC ID
- **`cidr_block`**: VPC CIDR block
- **`state`**: VPC state (available, pending, etc.)
- **`tags`**: VPC tags
- **`arn`**: VPC ARN

### 5. AWS Subnets Data Source
- **Purpose**: Retrieve information about subnets within a VPC
- **Use Cases**: Find available subnets for EC2 instances, RDS, etc.
- **Chaining**: Often used with VPC data source

#### Subnets Data Source Configuration
```hcl
data "aws_subnets" "production_subnets" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.production.id]
  }
}

# Filter by availability zone
data "aws_subnets" "public_subnets" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.production.id]
  }
  
  filter {
    name   = "tag:Type"
    values = ["public"]
  }
}
```

#### Subnets Data Source Attributes
- **`ids`**: List of subnet IDs
- **`arns`**: List of subnet ARNs
- **`tags`**: Subnet tags

### 6. AWS Caller Identity Data Source
- **Purpose**: Get information about the current AWS caller
- **Use Cases**: Account ID, user ARN, role ARN for policies and resource naming
- **No Configuration**: Simple data source with no arguments

#### Caller Identity Data Source
```hcl
data "aws_caller_identity" "current" {}

output "account_id" {
  value = data.aws_caller_identity.current.account_id
}

output "user_id" {
  value = data.aws_caller_identity.current.user_id
}

output "arn" {
  value = data.aws_caller_identity.current.arn
}
```

#### Caller Identity Attributes
- **`account_id`**: AWS account ID
- **`user_id`**: User ID
- **`arn`**: ARN of the caller (user or role)

### 7. AWS Region Data Source
- **Purpose**: Get current AWS region information
- **Use Cases**: Dynamic region references, multi-region configurations
- **No Configuration**: Simple data source with no arguments

#### Region Data Source
```hcl
data "aws_region" "current" {}

output "region_name" {
  value = data.aws_region.current.name
}

output "region_description" {
  value = data.aws_region.current.description
}
```

#### Region Data Source Attributes
- **`name`**: Region name (e.g., "us-east-1")
- **`description`**: Region description (e.g., "US East (N. Virginia)")
- **`endpoint`**: Regional endpoint

### 8. IAM Policy Document Data Source
- **Purpose**: Generate IAM policy documents dynamically
- **Use Cases**: S3 bucket policies, IAM role policies, resource-based policies
- **Benefits**: Avoid hardcoding JSON policies

#### IAM Policy Document Configuration
```hcl
data "aws_iam_policy_document" "static_website" {
  statement {
    sid = "PublicReadGetObject"

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    actions = ["s3:GetObject"]

    resources = ["arn:aws:s3:::*/*"]
  }
}

output "policy_json" {
  value = data.aws_iam_policy_document.static_website.json
}
```

#### Policy Document Components
- **`statement`**: Policy statements
- **`principals`**: Who the policy applies to
- **`actions`**: What actions are allowed/denied
- **`resources`**: Which resources the policy applies to
- **`effect`**: Allow or Deny (default: Allow)
- **`sid`**: Statement ID for identification

### 9. Chaining Data Sources
- **Concept**: Use output from one data source as input to another
- **Benefits**: Dynamic resource discovery and configuration
- **Example**: VPC → Subnets → Security Groups

#### Chaining Example
```hcl
# Step 1: Get VPC
data "aws_vpc" "production" {
  filter {
    name   = "tag:Name"
    values = ["production-vpc"]
  }
}

# Step 2: Get subnets in that VPC
data "aws_subnets" "production_subnets" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.production.id]
  }
}

# Step 3: Get AMI
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]
  
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-22.04-amd64-server-*"]
  }
}

# Step 4: Use all data sources in EC2 instance
resource "aws_instance" "web" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3.micro"
  subnet_id     = data.aws_subnets.production_subnets.ids[0]
  
  tags = {
    Name = "web-server"
    VPC  = data.aws_vpc.production.id
  }
}
```

### 10. Filtering Best Practices
- **Specific Filters**: Use precise filter criteria to avoid ambiguity
- **Multiple Filters**: Combine filters for more specific results
- **Tag-based Filtering**: Use consistent tagging strategies
- **ID-based Filtering**: Use resource IDs when available for deterministic results

#### Filter Types
- **Tag Filters**: `tag:Name`, `tag:Environment`
- **Resource Filters**: `vpc-id`, `subnet-id`, `security-group-id`
- **Attribute Filters**: `state`, `availability-zone`, `architecture`
- **Name Filters**: `name` for resource names

#### Filter Examples
```hcl
# Filter by tag
filter {
  name   = "tag:Environment"
  values = ["Production"]
}

# Filter by resource ID
filter {
  name   = "vpc-id"
  values = ["vpc-12345678"]
}

# Filter by name pattern
filter {
  name   = "name"
  values = ["ubuntu/images/hvm-ssd/ubuntu-22.04-*"]
}

# Multiple filters
filter {
  name   = "tag:Type"
  values = ["public"]
}

filter {
  name   = "state"
  values = ["available"]
}
```

### 11. Troubleshooting Data Sources
- **No Results**: Check filter criteria and resource existence
- **Multiple Results**: Use more specific filters or `most_recent`
- **Architecture Mismatch**: Ensure AMI and instance type architectures match
- **Permission Issues**: Verify AWS credentials and permissions

#### Common Issues and Solutions
1. **"Your query returned no results"**:
   - Verify filter criteria
   - Check if resources exist in the region
   - Use broader filter patterns

2. **Architecture Mismatch**:
   - Add architecture filter to AMI data source
   - Use compatible instance types (t3.micro for x86_64, t4g.micro for ARM64)

3. **Multiple Resources Found**:
   - Use `most_recent = true` for AMI data sources
   - Add more specific filters
   - Use resource IDs when available

### 12. Real-World Scenarios
- **Multi-team Environment**: Reference infrastructure managed by other teams
- **Dynamic AMI Selection**: Always use latest AMI without manual updates
- **Account Information**: Get account ID for resource naming and policies
- **Policy Generation**: Create IAM policies dynamically
- **Resource Discovery**: Find existing resources for integration

## Key Data Source Concepts

### Essential Data Sources
- **`aws_ami`**: Amazon Machine Images
- **`aws_vpc`**: Virtual Private Clouds
- **`aws_subnets`**: Subnets within VPCs
- **`aws_caller_identity`**: Current AWS caller information
- **`aws_region`**: Current AWS region
- **`aws_iam_policy_document`**: IAM policy documents

### Data Source Benefits
- **Dynamic Configuration**: Always use current resource information
- **No Hardcoding**: Avoid hardcoded resource IDs
- **Team Collaboration**: Reference infrastructure managed by others
- **Automation**: Enable fully automated deployments
- **Consistency**: Ensure consistent resource references

### Best Practices
- **Specific Filtering**: Use precise filter criteria
- **Architecture Matching**: Ensure AMI and instance type compatibility
- **Error Handling**: Handle cases where no resources are found
- **Documentation**: Document data source purposes and dependencies
- **Testing**: Test data sources in different environments

## Practical Exercises Summary
- **Exercise 10**: AMI Information - Dynamic AMI selection with architecture compatibility
- **Exercise 11**: AWS Caller Identity and Region - Account and region information
- **Exercise 12**: VPC Information - Existing VPC discovery and filtering
- **Exercise 13**: IAM Policy Document - Dynamic policy generation

## Exercise References
- **Exercise 10**: `exercises/basics/module-07/10-data-source-ami-information/README.md`
- **Exercise 11**: `exercises/basics/module-07/11-data-source-aws-caller-identity-region/README.md`
- **Exercise 12**: `exercises/basics/module-07/12-data-source-vpc-information/README.md`
- **Exercise 13**: `exercises/basics/module-07/13-data-source-iam-policy/README.md`

## Key Takeaways
- **Data Sources**: Enable dynamic, reusable Terraform configurations
- **External Integration**: Reference infrastructure managed by other teams
- **API Interaction**: Terraform queries provider APIs during plan phase
- **State Caching**: Results cached for consistency across operations
- **Architecture Compatibility**: Match AMI and instance type architectures
- **Filtering**: Use precise criteria for deterministic results
- **Chaining**: Combine data sources for complex resource discovery
- **Best Practices**: Specific filtering, error handling, and documentation
