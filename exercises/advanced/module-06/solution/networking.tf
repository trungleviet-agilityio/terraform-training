data "aws_vpc" "default" {
  default = true
}

data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_subnet" "this" {
  count      = 4
  vpc_id     = data.aws_vpc.default.id
  cidr_block = "172.31.${128 + count.index}.0/24"  # This is a valid CIDR block - it's a subnet in the VPC
  availability_zone = data.aws_availability_zones.available.names[
    count.index % length(data.aws_availability_zones.available.names)
  ]

  lifecycle {

    # The postcondition is used to check if the availability zone is valid
    # after the resource is created
    # If the availability zone is not valid, Terraform will return an error
    # and the resource will not be created
    postcondition {
      condition     = contains(data.aws_availability_zones.available.names, self.availability_zone)
      error_message = "Invalid AZ"
    }
  }
}

# This will not stop the resource from being created, but it will generate a warning
# if the resource does not have a high availability
check "high_availability_check" {
  assert {
    condition     = length(toset([for subnet in aws_subnet.this : subnet.availability_zone])) > 1
    error_message = <<-EOT
      You are deploying all subnets within the same AZ.
      Please consider distributing them across AZs for higher availability.
      EOT
  }
}
