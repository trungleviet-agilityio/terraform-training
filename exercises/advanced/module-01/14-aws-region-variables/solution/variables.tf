variable "ec2_instance_type" {
  type        = string
  default     = "t2.micro"
  description = "The type of the managed EC2 instances."

  validation {
    condition     = contains(["t2.micro", "t3.micro", "t3.large"], var.ec2_instance_type)
    error_message = "Only t2.micro, t3.micro, and t3.large instances are supported"
  }
}

variable "ec2_volume_config" {
  type = object({
    size = number
    type = string
  })
  description = "The size and type of the root block volume for EC2 instances."

  default = {
    size = 10
    type = "gp3"
  }
}

variable "additional_tags" {
  type    = map(string)
  default = {}
}

variable "my_sensitive_value" {
  type      = string
  sensitive = true
}
