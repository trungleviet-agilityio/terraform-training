# Module 02 – Using Expressions and Functions

## Learning Objectives
- Understand Terraform operators: mathematical, equality, comparison, logical
- Apply conditionals and type-safe expressions in resources
- Use for-expressions to transform/filter lists and maps
- Use splat expressions to project attributes across collections
- Leverage core functions (string, numeric, collection, encoding, file, type conversion)
- Distinguish boolean vs number outputs and avoid type errors

## Expressions Overview

### Mathematical Operators (return numbers)
```hcl
locals {
  math_product      = 2 * 2   # 4
  math_division     = 10 / 2  # 5
  math_sum          = 1 + 3   # 4
  math_subtraction  = 5 - 1   # 4
  math_modulus      = 7 % 3   # 1
  negate_number     = -5      # -5
}
```

### Equality and Comparison Operators (return booleans)
```hcl
locals {
  eq_true             = 2 == 2        # true
  ne_false            = 2 != 2        # false
  greater_true        = 2 > 1         # true
  greater_or_equal    = 2 >= 1        # true
  less_false          = 2 < 1         # false
  less_or_equal_false = 2 <= 1        # false
}
```

### Logical Operators (return booleans)
```hcl
locals {
  not_example  = !true                  # false
  or_example   = true || false          # true
  and_example  = true && false          # false
}
```

### Conditionals and Type-Safety
- Outputs of comparisons are booleans; do not use booleans where numbers are required.
- For `count`, convert booleans via conditional:
```hcl
resource "example" "maybe" {
  count = (length(var.items) > 0 ? 1 : 0)
}
```
- Terraform does not implicitly convert between strings and numbers. Use explicit conversion:
```hcl
local.string_plus_num_ok = "web-" + tostring(2)  # "web-2"
```

## For-Expressions and Comprehensions

### Lists (transform and filter)
```hcl
locals {
  double_numbers = [for num in var.numbers_list : num * 2]
  even_numbers   = [for num in var.numbers_list : num if num % 2 == 0]
  firstnames     = [for person in var.objects_list : person.firstname]
  fullnames      = [for person in var.objects_list : "${person.firstname} ${person.lastname}"]
}
```

### Maps (transform and filter)
```hcl
locals {
  doubles_map = { for key, value in var.numbers_map : key => value * 2 }
  even_map    = { for key, value in var.numbers_map : key => value * 2 if value % 2 == 0 }
}
```

### Filtering with string predicates
```hcl
variable "servers" {
  type    = list(string)
  default = ["web-1", "test-db", "app-2", "test-cache"]
}

locals {
  non_test_servers = [for s in var.servers : s if !startswith(s, "test-")]
}
```

## Splat Expressions and Projections
- Full splat for lists: `list[*].attr`
- For maps, combine with `values(...)` or a `for` projection.
```hcl
locals {
  firstnames_from_splat        = var.objects_list[*].firstname
  roles_from_for_projection    = [for username, user in local.users_map : user.roles]
  roles_from_values_projection = values(local.users_map)[*].roles
}
```

## Core Functions Used in This Module

### String Functions
```hcl
startswith("prod-app", "prod")  # true
lower("Trung Le")                # "trung le"
```

### Numeric Functions
```hcl
pow(5, 2)  # 25
```

### Collection Helpers
```hcl
length(var.objects_list)
values(local.users_map)
keys(local.users_map)
merge({a = 1}, {a = 2, b = 3})  # { a = 2, b = 3 }
```

### Encoding and Decoding
```hcl
# Read YAML users and project their names
output "users_from_yaml" {
  value = yamldecode(file("${path.module}/users.yaml")).users[*].name
}

# Convert object to JSON string
output "json_payload" {
  value = jsonencode({ key1 = 10, key2 = "my_value" })
}
```

### Filesystem and Path
```hcl
file("${path.module}/users.yaml")
```

### Type Conversion and Validation
```hcl
tostring(2)   # "2"
tonumber("2") # 2
can(tonumber("not-a-number"))  # false
```

## Practical Patterns

### Naming sequential resources (math + interpolation)
```hcl
resource "aws_instance" "app" {
  count         = 3
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3.micro"
  tags = {
    Name = "app-server-${count.index + 1}"
  }
}
```

### Conditional creation and filtering
```hcl
resource "aws_instance" "example" {
  for_each = { for s in var.servers : s => s if !startswith(s, "test-") }
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3.micro"
  tags = { Name = each.key }
}
``;

## Variable Definitions (align with exercises)
```hcl
variable "numbers_list" {
  type = list(number)
}

variable "numbers_map" {
  type = map(number)
}

variable "objects_list" {
  type = list(object({
    firstname = string
    lastname  = string
  }))
}
```

## Distinguishing Boolean vs Number Outputs
- Comparisons (e.g., `length(var.items) > 0`) yield booleans.
- Use conditionals to convert booleans to numbers when required (e.g., `count`).
- Keep types consistent; Terraform won’t add strings to numbers without explicit conversion.

## Best Practices
- Prefer `for_each` with maps for stable addressing; use keys for names.
- Keep expressions readable; extract complex logic into `locals`.
- Use validation and explicit conversions (`tostring`, `tonumber`).
- Validate filters with functions like `startswith`, and use comprehension `if` clauses instead of ad-hoc filtering.
- For projections, prefer splat (`[*]`) on homogeneous collections.

## Troubleshooting
- Invalid operation: mixing `string` and `number` without conversion.
- Unknown values: some expressions evaluate only at apply time; rely on `terraform console` to test.
- Type mismatch in `count`/`for_each`: ensure numbers for `count` and maps/sets for `for_each`.

## Exercise References
- `22-operators`: Operators, for-expressions, projections, and variable typing
- `23-for-lists`: List comprehensions (transform and filter)
- `24-for-maps`: Map comprehensions (transform and filter)
- `25-lists-maps`: Combining list/map transformations and projections
- `26-functions`: String, numeric, encoding, filesystem functions; YAML/JSON interop

## Key Takeaways
- Operators drive numeric or boolean results; use them type-safely.
- For-expressions are the idiomatic way to transform and filter data.
- Splat/project to extract attributes from collections.
- Functions unlock powerful transformations (string, numeric, collections, encoding).
- Always be explicit about types and conversions to avoid plan/apply errors.
