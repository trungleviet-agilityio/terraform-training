# Module 03 – Understanding Infrastructure as Code (IaC) and Terraform

## Learning Objectives
- Understand the principles of Infrastructure as Code (IaC)
- Learn the advantages of using Infrastructure as Code
- Compare manual infrastructure setup vs. automated setup with Terraform
- Understand why Terraform is a preferred choice for IaC
- Learn the structure and phases of Terraform

### 1. Defining Infrastructure as Code (IaC)
- Infrastructure as Code is the practice of managing and provisioning computing infrastructure through machine-readable definition files
- Treats infrastructure as software, enabling version control, testing, and automation
- Key principle: infrastructure should be defined declaratively rather than imperatively

### 2. Advantages of Using Infrastructure as Code
#### Better Cost Management
- **Easy Creation and Destruction**: Resources, environments, and complex infrastructures can be easily created and destroyed with single commands
- **Development Environment Automation**: Spin up dev environments when developers start working and destroy them at end of day to prevent additional costs
- **Time Savings**: Automation frees up time for developers and infrastructure maintainers to work on higher value tasks
- **Consistent Tagging**: Easily implement tagging strategies across entire infrastructure for better resource tracking
- **Resource Overview**: Obtain comprehensive overview of all resources created and managed by specific IaC projects

#### Improved Reliability
- **Consistent Behavior**: Well-developed IaC tools guarantee consistent behavior when interacting with remote APIs
- **Multiple Deployment Methods**: Support for local deployment, CI/CD pipeline integration, and API-triggered deployments
- **Configuration Validation**: Tools validate infrastructure configuration during deployment process, warning about invalid values before proceeding

#### Improved Consistency and Scalability
- **Easy Replication**: Infrastructure can be easily copied and deployed multiple times with the same structure
- **Modularization**: Create reusable modules that can be made publicly or privately available
- **Environment Creation**: Leverage reusable code to create different environments based on similar configuration files
- **Dynamic Scaling**: Resource counts can be easily increased or decreased whenever needed

#### Improved Deployment Processes
- **Time and Effort Savings**: Automation significantly reduces time and effort in infrastructure deployment
- **Configuration Drift Prevention**: IaC tools identify and revert unexpected changes to maintain intended configuration
- **CI/CD Integration**: Creating, updating, and destroying resources becomes fully integrated with other CI/CD tasks
- **Version Control**: Infrastructure changes are version controlled, making it easier to revert in case of incompatibility or errors

#### Fewer Human Errors
- **Planning Stage**: Tools show all expected changes before execution, allowing inspection and validation
- **Code-based Configuration**: Use variables and resource references instead of hard-coded values
- **Validation and Integrity Checks**: Support for custom conditions to ensure valid values
- **Protection Rules**: Safeguards against unintended deletion of critical resources

#### Improved Security Strategies
- **Compliance Validation**: Use validation and integrity checks to ensure infrastructure complies with security requirements
- **Storage Security**: Ensure deployed storage is encrypted (e.g., EBS encryption in AWS)
- **AMI Approval**: Validate that EC2 instances use only pre-approved AMIs
- **Secure Modules**: Shared infrastructure modules maintained by security-focused teams
- **IAM Configuration**: Configure IAM users, roles, and policies via IaC tools
- **Code Inspection**: Infrastructure code can be inspected by security software for vulnerabilities

#### Self-Documenting Infrastructure
- **Code as Documentation**: The infrastructure code itself documents what is being deployed and how resources are connected
- **Resource Inspection**: Use IaC tools to inspect created resources and see detailed information
- **Audit Logs**: Run logs are stored for inspection in case of errors or unwanted changes
- **Automated Documentation**: Since everything is automated, the process itself becomes documented

### 3. Hands-On: Setting Up Infrastructure Manually in AWS - Overview
- Demonstration of manual infrastructure setup process
- Shows the complexity and time-consuming nature of manual setup
- **Exercise Reference**: `exercises/basics/module-03/01-manual-vpc/README.md`

### 4. Hands-On: Setting Up Infrastructure Manually in AWS
- Step-by-step manual creation of AWS resources
- Highlights challenges: time-consuming, error-prone, difficult to reproduce
- Shows the need for automation
- **Exercise Details**: Create VPC with CIDR `10.0.0.0/16`, public subnet `10.0.0.0/24`, private subnet `10.0.1.0/24`, Internet Gateway, and route table
- **Exercise Reference**: `exercises/basics/module-03/01-manual-vpc/README.md`

### 5. Hands-On: Setting Up Infrastructure with Terraform - Overview
- Introduction to automated infrastructure setup with Terraform
- Preview of how Terraform simplifies the process
- **Exercise Reference**: `exercises/basics/module-03/02-terraform-vpc/README.md`

### 6. Hands-On: Setting Up Infrastructure with Terraform (8 min)
- Practical demonstration of Terraform in action
- Shows how the same infrastructure can be created with code
- Demonstrates the efficiency and consistency of IaC approach
- **Exercise Details**: Same infrastructure as manual setup but using Terraform configuration
- **Solution Reference**: `exercises/basics/module-03/02-terraform-vpc/solution/main.tf`
- **Exercise Reference**: `exercises/basics/module-03/02-terraform-vpc/README.md`

### 7. Why Choose Terraform?
- **Multi-cloud support**: Works with AWS, Azure, GCP, and many other providers
- **State management**: Tracks current state of infrastructure
- **Plan and apply workflow**: Preview changes before applying
- **Large ecosystem**: Extensive provider support
- **Declarative syntax**: Describe desired state, not steps to get there

### 8. The Structure of Terraform
- **Configuration files**: `.tf` files containing resource definitions
- **Providers**: Plugins that interact with cloud APIs
- **Resources**: Infrastructure components (VMs, networks, databases)
- **Variables**: Parameters for customization
- **Outputs**: Values to expose after deployment
- **State file**: Tracks current infrastructure state

### 9. Phases of Infrastructure Provisioning
- **Init**: Download providers and modules
- **Plan**: Create execution plan showing what will be created/modified/destroyed
- **Apply**: Execute the plan to create/modify infrastructure
- **Destroy**: Remove infrastructure when no longer needed

### 10. Hands-On: Understanding Terraform's Phases - Overview
- Introduction to practical demonstration of Terraform phases
- **Exercise Reference**: `exercises/basics/module-03/03-terraform-stages/README.md`

### 11. Hands-On: Understanding Terraform's Phases
- Practical walkthrough of `terraform init`, `terraform plan`, `terraform apply`
- Shows how each phase works in practice
- Demonstrates the safety of the plan phase
- **Exercise Details**: Initialize, plan, apply, and destroy infrastructure
- **Exercise Reference**: `exercises/basics/module-03/03-terraform-stages/README.md`

## Key Takeaways
- Infrastructure as Code transforms infrastructure management from manual to automated
- Terraform provides a powerful, multi-cloud solution for IaC
- The plan-apply workflow ensures safe infrastructure changes
- IaC enables better collaboration, version control, and consistency
- Manual infrastructure setup is error-prone and time-consuming compared to IaC
- **Practical Learning**: Complete the exercises to reinforce theoretical knowledge
