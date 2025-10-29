locals {
  name = "Trung Le"
  age  = 25
  my_object = {
    key1 = 10
    key2 = "my_value"
  }
}

output "example1" {
  value = startswith(lower(local.name), "Viet")
}

output "example2" {
  value = pow(local.age, 2)
}

output "example3" {
  value = yamldecode(file("${path.module}/users.yaml")).users[*].name
}

output "example4" {
  value = jsonencode(local.my_object)
}
