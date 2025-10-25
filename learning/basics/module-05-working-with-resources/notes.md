# Module 05 – Working with Resources

## Learning Objectives
- Understand how to define and manage resources in Terraform
- Learn about essential resource arguments for AWS EC2 instances
- Grasp the importance of unique resource names in Terraform
- Explore Terraform validation processes and their benefits
- Understand resource dependencies and meta-arguments
- Learn to set up and manage VPC, EC2 instances, and security groups
- Practice deploying applications like NGINX on EC2
- Understand how to clean up resources effectively

## Session Notes

### 1. Understanding Resources
- **Core Concept**: Resources are the main building blocks of Terraform used to configure real-world infrastructure objects
- **Key Components**:
  - Provider block: Specifies the cloud/service provider (e.g., AWS)
  - Resource block: Defines the infrastructure component (e.g., EC2 instance, S3 bucket)
- **Deployment Steps**: `terraform init` → `terraform plan` → `terraform apply`

#### What are Resources?
- **Main Building Blocks**: Resources are the most important blocks within Terraform
- **Infrastructure Management**: Used to manage any infrastructure with Terraform
- **Configuration Bulk**: The bulk of a Terraform configuration is made up of resources
- **Real-world Objects**: Represent things like virtual networks, compute instances, DNS records, storage disks

#### Resource Examples
- **AWS EC2 Instance**: `aws_instance` - Virtual compute instances
- **AWS S3 Bucket**: `aws_s3_bucket` - Object storage buckets
- **Random ID**: `random_id` - Local-only resource for generating unique identifiers
- **Hundreds of Resources**: Thousands of resources available across different providers

#### Resource Arguments
- **Resource-Specific**: Arguments depend on and vary based on resource type
- **Validation**: Terraform validates argument compatibility with resource type
- **Examples**:
  - `ami` argument: Valid for AWS instance, not valid for S3 bucket
  - `bucket` argument: Valid for S3 bucket, not valid for AWS instance
- **IDE Integration**: IDEs can catch invalid arguments before deployment

#### Common Resource Blocks
- **Provider-Specific**: Common blocks vary between providers
- **AWS Tags**: `tags` block common to most AWS resources
- **Provider Variations**: Different providers may use different naming (e.g., `labels` in GCP)
- **Resource Support**: Not all resources support all common blocks

#### Resource Naming Rules
- **Unique Combination**: Resource type + resource name must be unique within a module
- **Terraform Binding**: This combination is how Terraform binds resource blocks to real-world objects
- **No Duplicates**: Cannot have two resource blocks with identical type and name
- **Module Scope**: Uniqueness required within the same module

#### Provider Usage
- **Default Provider**: Terraform uses default provider if none specified
- **Provider Meta-Argument**: Use `provider` meta-argument to specify different provider
- **Explicit Provider**: Can pass different provider instance for specific resources
- **Provider Flexibility**: Allows using multiple provider instances

#### Local-Only Resources
- **No Cloud Resources**: Resources that don't create anything in the cloud
- **Information Generation**: Provide information that can be used in other resources
- **Examples**:
  - `random_id`: Generates random identifiers
  - `tls_private_key`: Creates private keys
  - `tls_self_signed_cert`: Creates self-issued TLS certificates
- **Use Cases**: Generate unique names, create cryptographic materials

#### Multiple Resource Instances
- **Terraform Loops**: Create multiple instances of resources using loops
- **Count Meta-Argument**: Create multiple instances with `count`
- **For Each Meta-Argument**: Create instances from maps or sets with `for_each`
- **Dedicated Section**: Loops covered in detail in dedicated section

### 2. Exploring Resource Dependencies
- **Resource Dependencies**: How Terraform determines the order of resource creation
- **Implicit Dependencies**: Terraform automatically detects dependencies through resource references
- **Explicit Dependencies**: Using `depends_on` meta-argument for explicit dependency management
- **Dependency Graph**: Understanding how Terraform builds and executes the dependency graph

#### Terraform Dependency Management
- **Automatic Detection**: Terraform is very good at identifying dependencies between resources
- **Parallel and Sequential**: Supports both parallel and sequential resource creation
- **Not Perfect**: Terraform is not perfect and sometimes requires explicit management
- **Dependency Resolution**: Automatically determines which resources can be created in parallel

#### Parallel vs Sequential Creation
- **Unrelated Resources**: Resources that don't depend on each other can be created in parallel
- **Examples**:
  - VPC and S3 bucket (unrelated) → Created in parallel
  - IAM role and VPC (unrelated) → Created in parallel
- **Dependent Resources**: Resources with dependencies must be created sequentially
- **VPC Dependencies**: RDS and EC2 instance both depend on VPC → Created after VPC

#### Implicit Dependencies
- **Automatic Detection**: Terraform inspects expressions in configuration files
- **Resource References**: Dependencies identified through resource references
- **Examples**:
  - EC2 instance references VPC ID → VPC must be created first
  - RDS instance references subnet ID → Subnet must be created first
- **Expression Analysis**: Terraform analyzes resource references to build dependency graph

#### Explicit Dependencies
- **`depends_on` Meta-Argument**: Define explicit dependencies when implicit detection fails
- **Use Cases**: When resources depend on each other but Terraform cannot identify implicit dependencies
- **No Expression References**: When resources don't have expressions that reference each other
- **Manual Management**: Explicitly specify dependency relationships

#### Dependency Execution Flow
- **Upstream Resources**: Resources that other resources depend on (e.g., VPC)
- **Downstream Resources**: Resources that depend on upstream resources (e.g., EC2, RDS)
- **Failure Handling**: If upstream resource fails, downstream operations are not processed
- **Logical Order**: Makes sense because dependent resources cannot be created without their dependencies

#### Advanced Dependency Features
- **Replace Triggered By**: Force Terraform to replace parent resource when child resource is modified
- **Use Case**: Create new role whenever EC2 instance is modified
- **Meta-Argument**: `replace_triggered_by` can reference other resources
- **Practical Application**: Less common in practice but useful for specific scenarios

#### Dependency Best Practices
- **Let Terraform Decide**: Allow implicit dependency detection when possible
- **Explicit When Needed**: Use `depends_on` only when necessary
- **Clear Relationships**: Ensure resource relationships are logical and necessary
- **Testing**: Verify dependency behavior through `terraform plan`

### 3. Using Meta-Arguments
- **Meta-Arguments**: Special arguments that can be used with any resource type
- **Key Meta-Arguments**:
  - `depends_on`: Explicit dependency management
  - `count`: Create multiple instances of a resource
  - `for_each`: Create multiple instances based on a map or set
  - `lifecycle`: Control resource lifecycle behavior
  - `provider`: Specify which provider instance to use

#### What are Meta-Arguments?
- **Configuration Control**: Allow us to configure Terraform's behavior in many ways
- **Resource and Data Sources**: Can be used with both resources and data sources
- **Special Functionality**: Offer interesting functionality for infrastructure management
- **Universal Application**: Can be used with any resource type

#### Dependency Management Meta-Arguments

##### `depends_on`
- **Purpose**: Explicitly define dependencies between resources
- **Use Case**: Inform Terraform to process resources sequentially rather than in parallel
- **Sequential Processing**: Forces resources to be created in a specific order
- **Explicit Control**: Override Terraform's automatic dependency detection

#### Resource Creation Meta-Arguments

##### `count` and `for_each`
- **Multiple Resources**: Create multiple resources of the same type without separate resource blocks
- **Non-Identical Resources**: Resources don't need to be identical
- **Map Configuration**: Use maps with `for_each` to configure different resource attributes
- **Efficiency**: Avoid duplicating resource blocks for similar resources

##### `provider`
- **Provider Selection**: Define explicitly which provider to use for a specific resource
- **Multiple Providers**: Use different provider instances for different resources
- **Provider Override**: Override default provider configuration
- **Multi-Cloud**: Enable resources across different cloud providers

#### Lifecycle Meta-Arguments

##### `create_before_destroy`
- **Default Behavior**: Terraform first destroys, then creates new resource
- **In-Place Updates**: Some updates can happen in place (e.g., changing tags)
- **Non-In-Place Updates**: Some updates require destroy and recreate (e.g., changing AMI)
- **Override Behavior**: Create new resource first, then destroy old one
- **Use Case**: Prevent downtime during resource replacement

##### `prevent_destroy`
- **Business Critical**: Protect business-critical resources from destruction
- **Error Prevention**: Terraform exits with error if planned changes would destroy resource
- **Configuration Dependent**: Only active when present in configuration
- **No Memory**: Terraform doesn't remember previous prevent_destroy settings
- **Example**: Protect S3 bucket from accidental destruction

##### `replace_triggered_by`
- **Resource Replacement**: Replace resource when referenced items change
- **Dependent Items**: Use dependent items to signal resource recreation
- **Upstream Resources**: Recreate upstream resource based on downstream changes
- **Use Case**: Create new role whenever EC2 instance is modified

##### `ignore_changes`
- **External Changes**: Prevent updates when attributes are modified outside Terraform
- **Attribute List**: Provide list of attributes that should not trigger updates
- **Tag Management**: Ignore tags added by other processes
- **Configuration Drift**: Prevent Terraform from reverting external changes
- **Best Practice**: Configuration should contain all necessary information

#### Advanced Lifecycle Features
- **Pre and Post Conditions**: Used for object validation
- **Validation**: Ensure resources meet specific criteria
- **Error Prevention**: Catch configuration issues before deployment
- **Dedicated Coverage**: Detailed coverage in dedicated section

#### Meta-Argument Best Practices
- **Use When Needed**: Apply meta-arguments only when necessary
- **Clear Purpose**: Understand the specific behavior each meta-argument provides
- **Testing**: Verify meta-argument behavior through `terraform plan`
- **Documentation**: Document why specific meta-arguments are used
- **Lifecycle Management**: Use lifecycle meta-arguments for resource protection and behavior control

### 4. VPC and EC2 Project - Complete Infrastructure Exercise
- **Project Goal**: Deploy NGINX server in AWS with complete VPC infrastructure
- **Learning Focus**: Real-world infrastructure setup and resource management
- **Components**: VPC, public/private subnets, internet gateway, security groups, EC2 instance
- **Application**: Deploy NGINX Bitnami AMI on EC2 with public access
- **Exercise Reference**: `exercises/basics/module-05/project-00-vpc-ec2/README.md`

#### Project Overview
- **Complete Infrastructure**: Build a full AWS infrastructure from scratch
- **Real-world Scenario**: Practical application of Terraform resource management
- **Resource Dependencies**: Understand how resources depend on each other
- **Best Practices**: Implement proper naming, tagging, and security

#### Step 1: Setting Up the VPC and Subnet
- **VPC Creation**: Define virtual private cloud with CIDR block 10.0.0.0/16
- **Public Subnet**: Create public subnet 10.0.0.0/24 within VPC
- **Private Subnet**: Create private subnet for additional security
- **CIDR Planning**: Proper IP address range allocation
- **Resource Naming**: Consistent naming conventions for infrastructure

#### Step 2: Setting Up the Internet Gateway
- **Internet Gateway**: Enable internet access for VPC
- **Route Table**: Configure routing to internet gateway (0.0.0.0/0)
- **Route Table Association**: Associate public subnet with route table
- **Public Access**: Ensure resources can reach the internet

#### Step 3: Managing Common Tags
- **Tagging Strategy**: Consistent tagging across all resources using locals
- **Common Tags**: ManagedBy, Project, CostCenter applied to all resources
- **Resource-Specific Tags**: Name tags for individual resource identification
- **Best Practices**: Tagging for cost management and resource organization

#### Step 4: Setting Up the EC2 Instance
- **Defining an AWS EC2 Instance**:
  ```hcl
  resource "aws_instance" "web" {
    ami                         = "ami-0dfee6e7eb44d480b"  # NGINX Bitnami AMI
    associate_public_ip_address = true
    instance_type               = "t2.micro"
    subnet_id                   = aws_subnet.public.id
    vpc_security_group_ids      = [aws_security_group.public_http_traffic.id]
    
    root_block_device {
      delete_on_termination = true
      volume_size           = 10
      volume_type           = "gp3"
    }
    
    lifecycle {
      create_before_destroy = true
    }
  }
  ```
- **Essential Arguments**:
  - `ami`: NGINX Bitnami AMI for web server
  - `instance_type`: t2.micro (free tier eligible)
  - `associate_public_ip_address`: Enable public IP assignment
  - `subnet_id`: Public subnet for internet access
  - `vpc_security_group_ids`: Security groups to associate
  - `root_block_device`: Storage configuration with lifecycle management

#### Step 5: Understanding and Using Security Groups
- **Security Groups**: Virtual firewall controlling inbound and outbound traffic
- **Custom Security Group**: Create specific security group for web server
- **Security Group Rules**: Define allowed traffic patterns
- **Best Practices**: Principle of least privilege for security rules

#### Step 6: Creating a Custom Security Group
- **Security Group Definition**: Allow traffic only on ports 80 (HTTP) and 443 (HTTPS)
- **Inbound Rules**: Allow HTTP and HTTPS traffic from anywhere (0.0.0.0/0)
- **Outbound Rules**: Allow all outbound traffic by default
- **Resource Dependencies**: EC2 instance depends on security group

#### Step 7: Deploying an EC2 Instance with NGINX
- **NGINX Bitnami AMI**: Pre-configured NGINX server (ami-0dfee6e7eb44d480b)
- **Public Access**: Instance accessible via public IP
- **Testing**: Verify NGINX is running and accessible
- **Certificate Warnings**: Normal for self-signed certificates (safe to ignore)

#### Step 8: Wrapping Up and Cleaning Up Resources
- **Resource Verification**: Confirm all resources are created successfully
- **Testing**: Verify web server is accessible via public IP
- **Cleanup**: Use `terraform destroy` to remove all resources
- **Cost Management**: Always clean up to avoid unexpected charges

#### Project Learning Outcomes
- **Resource Management**: Complete understanding of Terraform resource definition
- **Infrastructure Design**: Proper VPC and subnet configuration
- **Security Implementation**: Security group configuration and best practices
- **Application Deployment**: Pre-configured AMI deployment
- **Resource Cleanup**: Proper resource management and cost control
- **Solution Reference**: `exercises/basics/module-05/project-00-vpc-ec2/solution/README.md`

### 5. Working with Terraform Resources
- **Resource Definition**: Best practices for defining resources
- **Resource Arguments**: Understanding essential arguments for different resource types
- **Resource Dependencies**: Managing implicit and explicit dependencies
- **Resource Lifecycle**: Understanding resource creation, updates, and destruction

#### Terraform Validation
- **Crucial Step**: Always run `terraform validate` after writing configuration
- **Purpose**: Catches syntax and reference errors early
- **Benefits**: Ensures configuration is syntactically correct, structurally valid, and ready to plan safely
- **Error Example**: For `instance_type = "t2.micr0"`, Terraform provides feedback like: `The instance type "t2.micr0" is not valid. Did you mean "t2.micro"?`
- **Protection**: Prevents deploying invalid infrastructure

## Key Resource Concepts

### Essential Resource Arguments
- **AMI (Amazon Machine Image)**: Blueprint for virtual machine
  - Defines operating system, pre-installed software, root volume snapshot
  - Critical for determining what runs on the instance
- **Instance Type**: Determines compute capacity (CPU, memory, storage)
- **Key Name**: SSH key pair for secure access
- **Subnet ID**: Network location for the instance
- **Security Groups**: Virtual firewall rules
- **Tags**: Metadata for resource identification and management

### Resource Naming
- **Unique Names**: Resource names must be unique within a module
- **Logical Handles**: Names are logical identifiers for Terraform
- **Tracking**: Enables precise resource management and updates
- **Prevention**: Avoids confusion and conflicts during infrastructure management

### Resource Dependencies
- **Implicit Dependencies**: Automatically detected through resource references
- **Explicit Dependencies**: Use `depends_on` meta-argument
- **Dependency Graph**: Terraform builds execution order based on dependencies
- **Parallel Execution**: Resources without dependencies can be created in parallel

### Meta-Arguments
- **`depends_on`**: Explicit dependency management
- **`count`**: Create multiple instances
- **`for_each`**: Create instances from map or set
- **`lifecycle`**: Control resource lifecycle
- **`provider`**: Specify provider instance

## Terraform Validation Process

### Validation Benefits
- **Syntax Checking**: Ensures proper HCL syntax
- **Reference Validation**: Verifies resource references are correct
- **Type Checking**: Validates argument types and values
- **Early Detection**: Catches errors before deployment
- **Cost Protection**: Prevents invalid resource creation

### Common Validation Errors
- **Invalid Instance Types**: Typos in instance type names
- **Invalid AMI IDs**: Non-existent or inaccessible AMI IDs
- **Invalid Subnet IDs**: References to non-existent subnets
- **Invalid Security Groups**: References to non-existent security groups
- **Syntax Errors**: Missing brackets, quotes, or semicolons

## Best Practices

### Resource Definition
- **Clear Naming**: Use descriptive, consistent resource names
- **Proper Tagging**: Implement consistent tagging strategy
- **Documentation**: Comment complex configurations
- **Validation**: Always run `terraform validate` before applying

### Security Considerations
- **Security Groups**: Follow principle of least privilege
- **Key Management**: Use proper SSH key management
- **Network Security**: Implement proper VPC and subnet design
- **Access Control**: Limit access to necessary resources only

### Cost Management
- **Resource Cleanup**: Always destroy resources after testing
- **Instance Types**: Use appropriate instance types for workload
- **Tagging**: Implement cost allocation tags
- **Monitoring**: Monitor resource usage and costs

## Key Takeaways
- **Resource Definition**: Proper resource definition is fundamental to Terraform
- **Validation**: Always validate configurations before applying
- **Dependencies**: Understand and manage resource dependencies
- **Security**: Implement proper security practices
- **Cost Management**: Always clean up resources to avoid unexpected charges
- **Best Practices**: Follow consistent naming, tagging, and documentation practices
