# Module 04 – Terraform's Core Components

## Learning Objectives
- Understand HashiCorp Configuration Language (HCL) and its essential components
- Learn Terraform CLI commands and their practical usage
- Master Terraform state management and its importance
- Configure and work with Terraform backends (local and remote)
- Understand Terraform providers and their configuration

## Session Notes

### 1. Hands-On: Overview of the HashiCorp Configuration Language (HCL)
- Introduction to HCL essential components
- **Core Components**: Provider, Resource, Variables, Outputs, Data Sources, Terraform block
- **Minimum Requirements**: Provider and Resource blocks are absolute bare minimum for deployment
- **Best Practice**: Include Variables and Outputs for flexibility and maintainability

### 2. Understanding HashiCorp Configuration Language (HCL)
- **Provider Block**: Defines cloud/service provider (AWS, GCP, Azure) and enables API interaction
- **Resource Block**: Represents infrastructure component managed by Terraform (EC2, S3, VPC)
- **Variables Block**: Optional but best practice for reusable and flexible configurations
- **Output Block**: Optional - displays useful information post-`terraform apply`
- **Data Source Block**: Optional - reads existing infrastructure information
- **Terraform Block**: Meta-configuration defining required providers and versions for consistency

### 3. Configuring Terraform
- **Terraform Block**: Used for configuring Terraform project
- **Configuration Elements**:
  - Backends for state storage
  - Providers and their versions
  - Required Terraform versions
- **Terraform Block Example**:
  ```hcl
  terraform {
    required_version = ">= 1.7.0"
    backend "s3" {
      bucket = "my-terraform-state"
      key    = "dev/terraform.tfstate"
      region = "us-east-1"
    }
    required_providers {
      aws = {
        source  = "hashicorp/aws"
        version = "~> 5.33.0"
      }
    }
  }
  ```

#### Terraform Block Rules and Constraints
- **Constants Only**: No input variables allowed within terraform block
- **Cloud Block**: Can configure Terraform Cloud (covered later in course)
- **Backend Block**: Configures state backend (S3 is one option, others covered later)
- **Required Version**: Specifies accepted Terraform versions for the project
- **Required Providers**: Specifies required providers and their accepted versions

#### Version Constraints
- **Equal (=)**: Allow only specified version
- **Not Equal (!=)**: Exclude exact version (useful for buggy versions)
- **Greater/Less Than (>=, <=, >, <)**: Traditional comparison operators
- **Pessimistic Constraint (~>)**: Fixes all numbers except rightmost digits
  - `~> 5.33.0` allows 5.33.x but not 5.34.0
  - `~> 5.33` allows 5.x but not 6.x

#### Version Constraint Examples
- `>= 1.7.0`: Greater than or equal to 1.7.0
- `> 1.5.0, < 1.7.0`: Range between 1.5.x and 1.6.x
- `~> 1.5`: Anything 1.x is allowed
- `~> 1.5.0`: Anything 1.5.x is allowed

#### Key Differences
- **Required Version**: Refers to Terraform version itself
- **Required Providers**: Refers to provider versions (AWS, Azure, etc.)
- **Backend Configuration**: Where state is stored (local vs remote)

### 4. Hands-On: Introduction to Our First Terraform Project - Overview
- Overview of creating a simple S3 bucket
- Steps: defining provider, resource, variables, and outputs
- **Project Goal**: Create S3 bucket using HCL configuration
- **Exercise Reference**: `exercises/basics/module-04/05-first-tf-project/README.md`

### 5. Hands-On: Creating Resources in Our First Terraform Project
- Practical example of creating S3 bucket using HCL
- **Complete HCL Configuration**:
  - `terraform` block with `required_providers`
  - `provider` block for AWS
  - `variable` blocks for `aws_region` and `bucket_name`
  - `resource` block for `aws_s3_bucket`
  - `output` block for `s3_bucket_name`
- **Commands**: `terraform init` and `terraform apply -var="bucket_name=sam-demo-bucket"`
- **Exercise Reference**: `exercises/basics/module-04/05-first-tf-project/README.md`

### 6. Hands-On: Overview of the Terraform CLI
- Introduction to core Terraform CLI commands
- **Key Commands**: `init`, `plan`, `apply`
- **Exercise Reference**: `exercises/basics/module-04/06-terraform-cli/README.md`

### 7. Hands-On: Exploring Key Commands in the Terraform CLI
- **`terraform init`**: Initializes working directory, downloads providers, configures backends
- **`terraform plan`**: Creates execution plan showing proposed actions
- **`terraform apply`**: Executes plan to create/update infrastructure
- **`terraform destroy`**: Destroys Terraform-managed infrastructure
- **`terraform refresh`**: Updates state file with real-world infrastructure changes

#### Essential Terraform CLI Commands

##### `terraform init`
- **Purpose**: Sets up providers and backends for the project
- **When to Use**: First time setup or after adding new providers
- **What it Does**: Downloads HashiCorp AWS provider, HashiCorp random provider, etc.
- **Provider Installation**: Required whenever new providers are added

##### `terraform fmt` (Format)
- **Purpose**: Formats Terraform files for better readability
- **What it Does**: Aligns equals signs, formats resource blocks, improves indentation
- **Recursive Option**: `terraform fmt -recursive` formats all files in directory tree
- **Best Practice**: Run before committing code to repository

##### `terraform validate`
- **Purpose**: Validates configuration syntax and basic structure
- **Limitations**: Not thorough - many errors only appear during apply
- **Use Case**: Sanity check to rule out obvious mistakes
- **Note**: Cannot catch all configuration errors (e.g., invalid CIDR blocks)

##### `terraform plan`
- **Purpose**: Shows proposed changes without executing them
- **Output**: Lists resources to be created, modified, or destroyed
- **Plan File**: `terraform plan -out myplan` saves plan to file
- **Plan File Usage**: Can be passed to `terraform apply myplan`

##### `terraform apply`
- **Purpose**: Executes the plan to create/update infrastructure
- **Interactive Mode**: Shows plan and asks for confirmation
- **Plan File Mode**: `terraform apply myplan` skips confirmation
- **Auto-approve**: `terraform apply -auto-approve` skips confirmation
- **Destroy Mode**: `terraform apply -destroy` removes all resources

##### `terraform show`
- **Purpose**: Displays information from state file
- **State Information**: Shows all resources and their current configuration
- **Plan File**: `terraform show myplan` shows human-readable plan
- **Use Case**: Inspect state or plan files for debugging

##### `terraform state list`
- **Purpose**: Lists all resources managed by Terraform
- **Output**: Concise list of resources in state file
- **Advantage**: More readable than `terraform show`
- **Use Case**: Quick overview of managed resources

##### `terraform destroy`
- **Purpose**: Removes all Terraform-managed infrastructure
- **Confirmation**: Asks for confirmation before destroying
- **Auto-approve**: `terraform destroy -auto-approve` skips confirmation
- **Best Practice**: Always destroy resources to avoid unexpected costs

#### CLI Command Best Practices
- **File Organization**: Keep related resources in separate `.tf` files
- **Formatting**: Always run `terraform fmt` before committing
- **Validation**: Use `terraform validate` as sanity check
- **Plan First**: Always run `terraform plan` before apply
- **State Management**: Use `terraform state list` for resource overview
- **Cleanup**: Always destroy resources to avoid costs
- **Help**: Use `terraform help` and `terraform <command> -help` for documentation

#### Command Workflow
1. **Setup**: `terraform init` (first time or after provider changes)
2. **Format**: `terraform fmt` (improve code readability)
3. **Validate**: `terraform validate` (syntax check)
4. **Plan**: `terraform plan` (review changes)
5. **Apply**: `terraform apply` (execute changes)
6. **Verify**: `terraform state list` (check resources)
7. **Cleanup**: `terraform destroy` (remove resources)

### 8. Understanding Terraform State
- **What is State**: Maps resources from configuration files to real-world objects
- **State File**: Contains resource configurations and bindings to real-world infrastructure
- **Primary Goal**: Track resource configurations and their real-world object mappings
- **Additional Contents**:
  - Metadata useful for Terraform operations
  - Backend configuration
  - Outputs generated by Terraform project
  - **Sensitive values** (passwords, keys, tokens)

#### State File Characteristics
- **Always Required**: Terraform cannot work without a state file
- **Security Critical**: Contains extremely sensitive data - must be well protected
- **Access Control**: Should not be accessible to everyone
- **Required Element**: Essential for Terraform functionality

#### State File Contents
- **Resource Dependencies**: Order of resource creation, update, or deletion
- **Operation Sequencing**: Defines parallel vs sequential operations
- **Resource Bindings**: Links configuration to real-world objects
- **Metadata**: Information useful for Terraform operations

#### State Refresh Process
- **How it Works**: Terraform looks at state file → identifies real-world objects → issues API requests via providers
- **Latest Information**: Gets current state from real-world objects
- **Change Detection**: Compares real-world state with configuration
- **Drift Prevention**: Includes changes in plan to match configuration

#### Configuration Drift
- **Definition**: When real-world objects are modified outside of Terraform
- **Terraform Response**: Reverts changes to match configuration files
- **Source of Truth**: Terraform configuration files are always the authority
- **Goal**: Make real-world objects match configuration exactly

#### State Storage Options
- **Local Storage**: Default if no backend configuration provided
- **Remote Backends**: S3, Google Cloud Storage, Terraform Cloud, and others
- **Backend Configuration**: Covered in detail when discussing backends

#### State Locking
- **Purpose**: Prevents concurrent modifications that could lead to state corruption
- **How it Works**: Locks state file during operations
- **Concurrency Control**: Prevents simultaneous writes
- **Example Scenario**: Developer A deploying → Developer B must wait for lock release
- **Protection**: Prevents inconsistent state of real-world objects

#### Key State Management Principles
- **Security First**: State contains sensitive data - protect access
- **Drift Prevention**: State helps avoid configuration drift issues
- **Storage Flexibility**: Local or remote backend options
- **Concurrency Safety**: State locking prevents corruption

### 9. [Demo] Reviewing the State of Our Project
- Demonstration of inspecting `terraform.tfstate` file
- Using `terraform state show` for resource details
- Understanding state file structure and content

### 10. Working with Backends in Terraform
- **What is a Backend**: Defines where Terraform stores its state file
- **State File Importance**: Primary source of truth for Terraform project management
- **Storage Requirements**: Proper access control and guaranteed persistence
- **Backend Purpose**: Secure, controlled storage of critical state information

#### Three Categories of Backends

##### 1. Local Backend
- **Storage**: State file stored on local machine (`terraform.tfstate`)
- **Characteristics**: Default backend, familiar from previous work
- **Use Case**: Individual development and testing
- **Limitations**: No collaboration features, single-user only

##### 2. Terraform Cloud Backend
- **Storage**: State files stored in Terraform Cloud projects and workspaces
- **Special Features**: Additional functionalities beyond basic state storage
- **Advanced Capabilities**: Enhanced project management features
- **Coverage**: Detailed coverage later in course

##### 3. Third-Party Remote Backends
- **Examples**: S3, Google Cloud Storage, Azure Blob Storage
- **Storage**: State files stored in remote cloud storage
- **Flexibility**: Multiple cloud provider options
- **Configuration**: Different arguments required for each backend type

#### Backend Characteristics and Limitations
- **Single Backend**: Only one backend configuration allowed per Terraform project
- **No Merging**: Cannot combine multiple backends or merge state files
- **Migration Utilities**: Terraform provides migration tools (not 100% reliable)
- **Manual Migration**: Sometimes requires manual intervention for complex migrations

#### Backend Configuration Rules
- **No Variables**: Backend blocks cannot use input variables
- **No References**: Cannot reference resources or data sources
- **Constants Only**: Must use hardcoded values in backend configuration
- **Re-initialization**: Must run `terraform init` after backend changes

#### Remote Backend Requirements
- **Authentication**: Requires proper credentials for cloud provider access
- **Permissions**: Needs read and write permissions to state file location
- **S3 Example**: Requires AWS credentials with S3 bucket access
- **Security**: Proper access control for state file protection

#### Backend Migration Process
- **State Migration**: `terraform init -migrate-state` for backend changes
- **Verification**: Always verify migration success
- **Backup**: Consider backing up state before migration
- **Testing**: Test new backend configuration thoroughly

#### Backend Selection Guidelines
- **Local Backend**: Individual development, learning, testing
- **Remote Backends**: Team collaboration, production environments
- **Terraform Cloud**: Advanced features, enterprise requirements
- **Long-term Use**: Set once, use consistently throughout project lifecycle

#### Key Backend Considerations
- **Security**: Protect access to state files containing sensitive data
- **Collaboration**: Remote backends enable team coordination
- **Persistence**: Ensure state files are not lost or corrupted
- **Access Control**: Proper permissions and authentication
- **Migration Planning**: Consider future backend changes carefully

### 11. Hands-On: Setting Up a Remote Backend in S3 - Overview
- Introduction to using S3 bucket for remote state storage
- Benefits of remote backend configuration
- **Exercise Reference**: `exercises/basics/module-04/07-s3-backend/README.md`

### 12. Hands-On: Configuring a Remote S3 Backend
- **S3 Backend Configuration**:
  - `bucket`: Name of S3 bucket (must exist)
  - `key`: Path for state file in bucket
  - `region`: AWS region of S3 bucket
  - `dynamodb_table`: DynamoDB table for state locking
  - `encrypt`: Server-side encryption (AES-256)
- **Why Each Setting Matters**: Prevents duplicates, avoids concurrency conflicts, protects sensitive data

### 13. Hands-On: Partial Backend Setup - Overview
- Initial steps for preparing remote backend infrastructure
- **Critical Point**: S3 bucket and DynamoDB table must exist before `terraform init`
- **Exercise Reference**: `exercises/basics/module-04/08-partial-backend-config/README.md`

### 14. Hands-On: Partial Backend Setup
- One-time manual setup of S3 bucket and DynamoDB table
- **Backend Block Special Rules**: Evaluated before providers/plans, no variables allowed
- **Changing Backend Configuration**: Update `bucket`/`key`, run `terraform init -migrate-state`, verify migration
- **Consequences**: Not migrating state can lead to infrastructure recreation

### 15. Terraform Providers Explained
- **What are Providers**: Plugins that enable Terraform to interact with remote APIs and platforms
- **Core Limitation**: Terraform core cannot create/manage resources without providers
- **Provider Function**: Enable interaction with AWS, Google Cloud, Azure, and other remote APIs
- **Plugin Architecture**: Providers are developed and maintained separately from Terraform

#### Provider Declaration and Configuration
- **Required Providers Block**: Declare providers in `terraform` configuration block
- **Provider Declaration**: Must declare all providers required by the project
- **Resource Dependency**: To use specific resources, include respective provider
- **Root Module**: Provider configuration belongs to root module of Terraform project

#### Provider Development and Maintenance
- **Separate Development**: Providers developed independently from Terraform
- **Plugin Architecture**: Fits into Terraform's plugin system
- **Open Source**: Anyone can write providers for any remote API
- **Resource Management**: Providers enable management of any API-based resources

#### Provider Scope and Modules
- **Root Module**: Provider configuration defined at project root level
- **Child Modules**: Receive provider configuration from parent module
- **Module Dependencies**: Child modules define which providers they need
- **Configuration Inheritance**: Providers passed down from parent to child modules

#### Version Management
- **Version Constraints**: Same version constraint system as Terraform version
- **Dependency Lockfile**: Can create and commit dependency lockfile
- **Repository Commits**: Lockfile should be committed to repository
- **Version Consistency**: Ensures exact provider versions across environments
- **Initialization**: Guarantees consistent provider versions during `terraform init`

#### Provider Architecture Benefits
- **Extensibility**: Easy to add support for new platforms and services
- **Community Development**: Open source provider ecosystem
- **API Coverage**: Support for any platform with remote API
- **Version Control**: Precise version management and consistency
- **Modularity**: Clean separation between Terraform core and provider logic

#### Key Provider Concepts
- **API Interaction**: Providers handle all communication with remote APIs
- **Resource Types**: Each provider adds specific resource types and data sources
- **Configuration**: Provider-specific configuration options
- **Authentication**: Provider handles authentication with remote services
- **State Management**: Providers manage resource state and lifecycle

### 16. Hands-On: Overview of Working with Providers
- How providers are declared in `terraform` block (`required_providers`)
- Provider configuration with `provider "aws" {}`
- **Exercise Reference**: `exercises/basics/module-04/09-providers/README.md`

### 17. Hands-On: Hands-on with Providers
- Practical application of AWS provider to create resources
- **Provider Region Setting**: How provider's region setting influences resource creation
- **S3 Bucket Example**: Demonstrates provider configuration impact on resource creation

## Key HCL Components Summary

### Essential Components (Minimum Required)
- **Provider Block**: Defines which cloud/service provider to use
- **Resource Block**: Defines what infrastructure to create

### Optional but Recommended Components
- **Variables Block**: Makes configurations reusable and flexible
- **Output Block**: Displays useful information after deployment
- **Data Source Block**: References existing infrastructure
- **Terraform Block**: Defines required providers and versions

## Terraform CLI Commands Summary

| Command | Purpose | When to Use |
|---------|---------|-------------|
| `terraform init` | Initialize working directory | First time or after adding providers |
| `terraform plan` | Create execution plan | Before applying changes |
| `terraform apply` | Execute plan | Deploy or update infrastructure |
| `terraform destroy` | Remove infrastructure | Clean up resources |
| `terraform refresh` | Update state file | Sync with real-world changes |

## Backend Configuration

### Local Backend (Default)
- State stored in `terraform.tfstate` on local machine
- Suitable for individual development
- No collaboration features

### Remote Backend (S3 Example)
```hcl
terraform {
  backend "s3" {
    bucket         = "my-terraform-state"
    key            = "dev/app.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-locks"
    encrypt        = true
  }
}
```

### Terraform Cloud Backend
```hcl
terraform {
  cloud {
    organization = "my-org"
    workspaces {
      name = "production"
    }
  }
}
```

## Key Takeaways
- **HCL Essentials**: Provider and Resource blocks are minimum requirements for Terraform
- **State Management**: Critical for tracking infrastructure and enabling change detection
- **Backend Importance**: Remote backends enable collaboration, consistency, and security
- **CLI Workflow**: init → plan → apply → destroy is the standard workflow
- **Provider Configuration**: Determines where and how resources are created
- **Best Practices**: Use variables for flexibility, outputs for information, and remote backends for team collaboration

## Practical Learning Path
1. **Start Simple**: Begin with basic provider and resource blocks
2. **Add Flexibility**: Include variables for reusable configurations
3. **Provide Information**: Use outputs to display important values
4. **Team Collaboration**: Configure remote backends for shared state management
5. **Advanced Features**: Explore data sources and complex provider configurations

## Practical Exercises Summary
- **Exercise 4**: HCL Basics - Understanding HashiCorp Configuration Language syntax
- **Exercise 5**: First Terraform Project - Creating S3 bucket with random ID
- **Exercise 6**: Terraform CLI - Essential commands and workflows
- **Exercise 7**: S3 Backend - Remote state storage configuration
- **Exercise 8**: Partial Backend Config - Environment-specific backend configurations
- **Exercise 9**: Providers - Multi-region provider configuration

## Exercise References
- **Exercise 4**: `exercises/basics/module-04/04-hcl/README.md`
- **Exercise 5**: `exercises/basics/module-04/05-first-tf-project/README.md`
- **Exercise 6**: `exercises/basics/module-04/06-terraform-cli/README.md`
- **Exercise 7**: `exercises/basics/module-04/07-s3-backend/README.md`
- **Exercise 8**: `exercises/basics/module-04/08-partial-backend-config/README.md`
- **Exercise 9**: `exercises/basics/module-04/09-providers/README.md`
