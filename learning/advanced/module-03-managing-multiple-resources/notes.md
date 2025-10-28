# Advanced Module 03 – Managing Multiple Resources with count and for_each

## Learning Objectives
- Understand Terraform meta-arguments: `count`, `for_each`, `depends_on`, and `lifecycle`
- Choose between `count` and `for_each` for scalable resource patterns
- Create multiple resources from lists, sets, and maps
- Add robust input validations for safe, deterministic deployments
- Distribute resources across subnets and pass subnet info via variables
- Extend images (AMIs) and constrain allowed values

## Key Concepts

### Meta-Arguments Overview
- **count**: Replicates a resource N times; best for identical resources differing only by index.
- **for_each**: Creates resources from a map or set; best when instances are unique or need stable keys.
- **depends_on**: Force explicit dependency when implicit references aren’t present.
- **lifecycle**: Control behaviors such as `create_before_destroy`, `prevent_destroy`.

### When to Use count
- Resources are identical (same AMI, instance type, SGs).
- Only the index differs (naming, CIDR offset, round-robin distribution).
- Simple scale up/down by changing a single number.

Example (two subnets with unique CIDRs and names):
```hcl
resource "aws_subnet" "main" {
  count      = var.subnet_count
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.${count.index}.0/24"

  tags = {
    Project = local.project
    Name    = "${local.project}-${count.index}"
  }
}
```

### When to Use for_each
- Each resource needs unique attributes (e.g., instance type, subnet, name).
- Stable keys are required to avoid re-index churn on insert/remove.
- Managing maps or sets of data with incremental changes.

Example (map-driven EC2 instances):
```hcl
resource "aws_instance" "from_map" {
  for_each      = var.ec2_instance_config_map
  ami           = local.ami_ids[each.value.ami]
  instance_type = each.value.instance_type
  subnet_id     = aws_subnet.main[each.value.subnet_name].id

  tags = {
    Name    = "${local.project}-${each.key}"
    Project = local.project
  }
}
```

### Collections with for_each
- **map(string|object)**: Preferred for stable, meaningful keys (e.g., names, subnets, roles).
- **set(string)**: Good when only uniqueness matters (e.g., a set of AMI IDs). Avoid lists to prevent churn on reordering.

## Practical Patterns Covered (Aligned with Exercises 27–34)

### 27. Creating Multiple Subnets with count
- Define `local.project` and a VPC.
- Use `count` to create N subnets with unique CIDRs and names using `count.index`.
- Make subnet count configurable with `variable "subnet_count"`.

### 28. Referencing Resources Created with count
- Create EC2 instances with a configurable `ec2_instance_count` (default 1).
- Read Ubuntu AMI via data source.
- Distribute instances across subnets: `subnet_id = aws_subnet.main[count.index % length(aws_subnet.main)].id`.
- Use `t3.micro` instance type.

### 29. Multiple EC2 from List Input
- Variable `ec2_instance_config_list` (list of objects: `instance_type`, `ami`, optional `subnet_name`).
- Local `ami_ids` map: friendly keys (`ubuntu`, `nginx`) to AMI IDs via data sources.
- Create instances with `count = length(var.ec2_instance_config_list)` and index into the list.
- Distribute or target subnets as needed.

### 30. Extend AMIs to Allow NGINX
- Add `data "aws_ami" "nginx"` with a precise name filter (e.g., Bitnami NGINX 1.28.0 x86_64 HVM EBS).
- Extend `local.ami_ids` to include `nginx`.
- Add an NGINX entry in list/map configs.

### 31. Validation for List Input
- Add validation to enforce `instance_type` is `t3.micro` only.
- Add validation to enforce `ami` in [`ubuntu`, `nginx`].
- Surface clear error messages.

### 32. Multiple EC2 from Map Input with for_each
- Variable `ec2_instance_config_map` (map of objects: `instance_type`, `ami`, optional `subnet_name`).
- Use `for_each` to create named instances with stable keys.
- Prefer `t3.micro` per validations and solution.

### 33. Validation for Map Input
- Mirror list validations for map values.
- Enforce `t3.micro` and limited AMI keys (`ubuntu`, `nginx`).

### 34. Provide Subnet Information
- Variable `subnet_config` (map of objects with `cidr_block`).
- Validation ensuring valid CIDRs via `can(cidrnetmask(...))`.
- Create subnets with `for_each` keyed by subnet name.
- Extend list/map instance configs with optional `subnet_name` (default `"default"`).
- Use `aws_subnet.main[<subnet_name>].id` when setting `subnet_id`.

## AMI Data Sources (Solution Alignment)

```hcl
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-*-22.04-amd64-server-*"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

data "aws_ami" "nginx" {
  most_recent = true
  filter {
    name   = "name"
    values = ["bitnami-nginx-1.28.0-*-linux-debian-12-x86_64-hvm-ebs-*"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

locals {
  ami_ids = {
    ubuntu = data.aws_ami.ubuntu.id
    nginx  = data.aws_ami.nginx.id
  }
}
```

## Input Validations (Examples)

List:
```hcl
variable "ec2_instance_config_list" {
  type = list(object({
    instance_type = string
    ami           = string
    subnet_name   = optional(string, "default")
  }))
  default = []

  validation {
    condition = alltrue([
      for config in var.ec2_instance_config_list : contains(["t3.micro"], config.instance_type)
    ])
    error_message = "Only t3.micro instances are allowed."
  }

  validation {
    condition = alltrue([
      for config in var.ec2_instance_config_list : contains(["nginx", "ubuntu"], config.ami)
    ])
    error_message = "At least one of the provided \"ami\" values is not supported.\nSupported \"ami\" values: \"ubuntu\", \"nginx\"."
  }
}
```

Map:
```hcl
variable "ec2_instance_config_map" {
  type = map(object({
    instance_type = string
    ami           = string
    subnet_name   = optional(string, "default")
  }))

  validation {
    condition = alltrue([
      for config in values(var.ec2_instance_config_map) : contains(["t3.micro"], config.instance_type)
    ])
    error_message = "Only t3.micro instances are allowed."
  }

  validation {
    condition = alltrue([
      for config in values(var.ec2_instance_config_map) : contains(["nginx", "ubuntu"], config.ami)
    ])
    error_message = "At least one of the provided \"ami\" values is not supported.\nSupported \"ami\" values: \"ubuntu\", \"nginx\"."
  }
}
```

## Choosing Between count and for_each
- **Use count** when resources are uniform and index-based differentiation is sufficient.
- **Use for_each** when resources differ, require stable keys, or map naturally to named items.
- Avoid `for_each` over lists; prefer `set(string)` or `map(...)` to prevent churn from reordering.

## Real-World Scenarios
- Scale identical web servers: `count` with a single resource block.
- Distinct instances per subnet/name: `for_each` with a map keyed by subnet/name.
- One instance per unique AMI: `for_each` over `set(string)` of AMI IDs.

## Exercise References
- `exercises/advanced/module-03/27-creating-count/README.md`
- `exercises/advanced/module-03/28-referencing-count/README.md`
- `exercises/advanced/module-03/29-multiple-ec2-list-input/README.md`
- `exercises/advanced/module-03/30-allow-nginx-image/README.md`
- `exercises/advanced/module-03/31-validation-list-input/README.md`
- `exercises/advanced/module-03/32-multiple-ec2-map-input/README.md`
- `exercises/advanced/module-03/33-validation-map-input/README.md`
- `exercises/advanced/module-03/34-provide-subnet-information/README.md`

## Key Takeaways
- `count` and `for_each` are core to scaling resources safely and predictably.
- Prefer stable keys and maps for production-grade changes without churn.
- Validate inputs to protect cost, security, and correctness.
- Keep AMI patterns precise and align architectures with instance types.
