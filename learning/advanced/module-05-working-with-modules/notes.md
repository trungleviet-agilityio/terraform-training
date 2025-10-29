# Advanced Module 05 – Working with Terraform Modules

## Learning Objectives
- Understand what Terraform modules are and why they matter
- Learn the standard module structure and how files interact
- Encapsulate implementation using `variables.tf` and `outputs.tf`
- Organize modules and environments for reuse and isolated state
- Apply code patterns for real usage (public modules, local modules)
- Manage module versions safely with Semantic Versioning
- Adopt best practices and avoid common pitfalls

## Session Notes

### 1. Module Fundamentals
- **Core Concept**: Modules are reusable containers of Terraform configuration (directories of `.tf` files) that define coherent infrastructure components
- **Function Analogy**: Like functions in programming with inputs (variables), logic (resources), and outputs
- **Key Benefits**:
  - Reusability and consistency across environments
  - Abstraction (hide complexity, expose only necessary interfaces)
  - Scalability and maintainability (versionable units)
  - Separation of concerns (teams can own different modules)
  - Multi-environment deployments (same code, different inputs)

### 2. Standard Module Structure
- **Recommended Files**:
  - `main.tf` (or `vpc.tf`, `networking.tf`): Core resources
  - `variables.tf`: Input parameters and validation
  - `outputs.tf`: Exposed values for consumers
  - `versions.tf`: Version constraints for reproducibility
  - `README.md`: Documentation and examples
  - `LICENSE`: Distribution license
- **File Responsibilities**: Each file has a specific purpose in the module interface

### 3. Encapsulation and Reuse
- **Input Encapsulation**: `variables.tf` defines the public interface; keep minimal and meaningful
- **Output Exposure**: `outputs.tf` exposes stable identifiers consumers need (IDs, ARNs, maps)
- **Internal Changes**: Encapsulation allows internal changes without breaking callers when inputs/outputs remain stable
- **Stable Interface**: Consumers depend on outputs, not internal resource names

### 4. Organization for Environments
- **Directory Structure**: Separate `modules/` (shared logic) from `environments/` (configuration)
- **Principle**: Same code (modules), different inputs (tfvars), separate state (backend per env)
- **Flat Composition**: Keep modules flat and composable; avoid deep nesting chains
- **State Isolation**: Each environment uses its own backend for complete isolation

### 5. Module Sources and Referencing
- **Local Modules**: `source = "./modules/networking"`
- **Registry Modules**: `source = "terraform-aws-modules/vpc/aws"` with `version = "x.y.z"`
- **Git Modules**: `source = "git::https://github.com/org/repo.git//path?ref=v2.3.1"`
- **Version Pinning**: Always pin exact versions for reproducibility

### 6. Effective Calling Patterns
- **Multiple Instances**: Use different module blocks or `for_each` over config maps
- **Object Inputs**: Prefer single object inputs per concern for evolvability
- **Root Composition**: Compose modules in root, not deeply nested
- **Data Flow**: Make data flow explicit and dependencies clear

### 7. Conditional and Dynamic Patterns
- **Conditional Resources**: Use `count` or `for_each` with conditional expressions
- **Dynamic Blocks**: Abstract repeated nested blocks without exposing internals
- **Preconditions**: Validate assumptions on resources with lifecycle conditions
- **Flexible Configuration**: Support optional features without complexity

### 8. Publishing and Versioning
- **Semantic Versioning**: Use `MAJOR.MINOR.PATCH` format for module versions
- **Registry Readiness**: Include standard files, documentation, and examples
- **Version Pinning**: Consumers pin module versions; modules pin provider constraints
- **Promotion Flow**: Test in dev → stage → prod environments

### 9. Testing and Documentation
- **Example-Driven**: Provide `examples/` folders showing canonical usage
- **CI Validation**: Use `terraform validate` and `terraform plan` in CI
- **Documentation**: Generate README tables from `variables.tf`/`outputs.tf`
- **User Experience**: Clear examples and comprehensive documentation

### 10. State Management with Modules
- **Root Ownership**: Modules don't own state; root module's backend defines storage
- **Environment Isolation**: Each environment uses separate backend (S3 bucket/key)
- **Refactoring Safety**: Preserve resource addresses when moving to modules
- **State Consistency**: Maintain state integrity across module changes

### 11. Security and Compliance
- **No Secrets**: Never include secrets in module code or outputs
- **Least Privilege**: Attach minimal policies; accept ARNs as inputs when needed
- **Input Validation**: Validate critical inputs (CIDR, AZs, ARNs) with clear error messages
- **Provider Configuration**: Keep provider config light; avoid credential conflicts

### 12. Performance and Troubleshooting
- **Hidden Dependencies**: Avoid heavy data sources in modules; pass inputs explicitly
- **Plan Readability**: Aggregate outputs into maps for fewer plan lines
- **Common Issues**: Module not found, version conflicts, infinite diffs, resource churn
- **Debugging**: Use locals to simplify repeated expressions

### 13. Exercise Cross-Reference (35-43)
- **Public Modules**: VPC and EC2 modules from Terraform Registry
- **Local Module**: Building custom VPC module incrementally
- **Patterns Demonstrated**: Object inputs, AZ validation, conditional resources, structured outputs
- **Consumer Usage**: Testing module outputs with dependent EC2 instances

## Key Module Concepts

### Essential Module Components
- **Module Definition**: Directory containing `.tf` files that define reusable infrastructure
- **Input Interface**: `variables.tf` defines what the module accepts
- **Output Interface**: `outputs.tf` defines what the module exposes
- **Resource Logic**: `main.tf` (or specific files) contains the actual infrastructure code
- **Documentation**: `README.md` explains usage and provides examples

### Module Benefits
- **Reusability**: Same module can be used across multiple environments
- **Consistency**: Standardized infrastructure patterns across projects
- **Abstraction**: Hide complex implementation details from consumers
- **Maintainability**: Centralized updates benefit all consumers
- **Team Collaboration**: Different teams can own different modules

### Module Types
- **Local Modules**: Defined in local directories (`./modules/`)
- **Registry Modules**: Published to Terraform Registry (`terraform-aws-modules/vpc/aws`)
- **Git Modules**: Stored in Git repositories with version tags
- **Root Module**: The main configuration that calls other modules

## Code Patterns and Examples

### Using Public VPC Module
```hcl
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.5.3"

  name            = local.project_name
  cidr            = local.vpc_cidr
  azs             = data.aws_availability_zones.azs.names
  private_subnets = ["10.0.0.0/24"]
  public_subnets  = ["10.0.128.0/24"]
}
```

### Using Public EC2 Module
```hcl
module "ec2" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "5.6.1"

  name          = local.project_name
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3.micro"
  subnet_id     = module.vpc.public_subnets[0]
  tags          = local.common_tags
}
```

### Local Module Structure
```
modules/networking/
├── main.tf
├── variables.tf
├── outputs.tf
├── versions.tf
└── README.md
```

### Environment Organization
```
terraform/
├── modules/
│   ├── vpc/
│   ├── ec2/
│   └── s3/
└── environments/
    ├── production/
    │   ├── main.tf
    │   ├── terraform.tfvars
    │   └── backend.tf
    └── development/
        ├── main.tf
        ├── terraform.tfvars
        └── backend.tf
```

## Best Practices

### Module Design
- **Narrow Scope**: Keep modules focused on specific functionality
- **Stable Interface**: Minimize changes to inputs and outputs
- **Object Inputs**: Group related parameters into object types
- **Comprehensive Outputs**: Expose all identifiers consumers might need
- **Input Validation**: Validate critical inputs with clear error messages

### Security Considerations
- **No Secrets**: Never include sensitive data in module code
- **Least Privilege**: Use minimal required permissions
- **Input Validation**: Validate all external inputs
- **Provider Configuration**: Keep provider config minimal

### Version Management
- **Semantic Versioning**: Use `MAJOR.MINOR.PATCH` format
- **Version Pinning**: Always pin exact versions in production
- **Promotion Flow**: Test in dev → stage → prod
- **Breaking Changes**: Document and communicate breaking changes

## Common Pitfalls

### Design Issues
- **Over-Exposure**: Exposing too many internal configuration options
- **Wide Scope**: Trying to solve too many problems in one module
- **Hidden Dependencies**: Using data sources instead of explicit inputs
- **Missing Validation**: Not validating critical inputs

### Implementation Issues
- **List with for_each**: Causes resource churn on reordering
- **Version Conflicts**: Not pinning versions leads to surprise updates
- **State Issues**: Not preserving resource addresses during refactoring
- **Documentation**: Insufficient examples and usage documentation

## Troubleshooting

### Common Issues
- **Module Not Found**: Verify source URL and path
- **Version Conflicts**: Check version constraints and provider compatibility
- **Infinite Diffs**: Review lifecycle rules and computed attributes
- **Resource Churn**: Use maps/sets instead of lists with for_each
- **AZ/Region Errors**: Ensure provider region matches AZ inputs

### Debugging Steps
1. Verify module source and version
2. Check input validation errors
3. Review resource dependencies
4. Validate provider configuration
5. Check state file for conflicts

## Exercise References
- **35**: Using the AWS VPC Module
- **36**: Using the AWS EC2 Module  
- **37**: Creating Our First VPC Module
- **38**: Extending the VPC Module to Receive Subnet Configuration
- **39**: Receiving Subnet Configuration (iterative)
- **40**: Validating the Availability Zones
- **41**: Public and Private Subnets
- **42**: Defining Outputs
- **43**: Testing the Module with EC2 Instances

## Key Takeaways
- **Modules are Functions**: Inputs, logic, outputs - just like programming functions
- **Encapsulation Matters**: Hide complexity, expose only what's needed
- **Version Everything**: Pin versions for reproducibility and safety
- **Test Thoroughly**: Use examples and CI validation
- **Document Well**: Clear examples and comprehensive documentation
- **Security First**: No secrets, least privilege, input validation
- **State Management**: Root owns state, environments are isolated
- **Best Practices**: Follow established patterns for maintainable modules
