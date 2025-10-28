locals {
  ami_ids = {
    ubuntu = data.aws_ami.ubuntu.id
    nginx  = data.aws_ami.nginx.id
  }
}

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Owner is Canonical

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
    # values = ["bitnami-nginx-1.25.4-*-linux-debian-12-x86_64-hvm-ebs-*"]
    values = ["bitnami-nginx-1.28.0-*-debian-12-amd64-*"]
    # bitnami-nginx-1.28.0-r11-debian-12-amd64-f5774628-e459-457a-b058-3b513caefdee
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_instance" "from_list" {
  count         = length(var.ec2_instance_config_list)
  ami           = local.ami_ids[var.ec2_instance_config_list[count.index].ami]
  instance_type = var.ec2_instance_config_list[count.index].instance_type
  subnet_id = aws_subnet.main[
    count.index % length(aws_subnet.main)
  ].id

  # 0 % 2 = 0
  # 1 % 2 = 1
  # 2 % 2 = 0
  # 3 % 2 = 1

  tags = {
    Name    = "${local.project}-${count.index}"
    Project = local.project
  }
}
