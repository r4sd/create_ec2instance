provider "aws" {
  region = "ap-northeast-1"
}

locals {
  common_tags = {
    Terraform = "automation"
  }
}

resource "aws_vpc" "this" {
  cidr_block = "10.0.0.0/16"

  tags = merge(local.common_tags, {
    Name = "example-vpc"
  })
}

resource "aws_subnet" "this" {
  cidr_block = "10.0.1.0/24"
  vpc_id     = aws_vpc.this.id

  tags = merge(local.common_tags, {
    Name = "example-subnet"
  })
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.this.id

  tags = {
    Name = "example-igw"
  }
}

resource "aws_eip" "nat_1d" {
  vpc = true

  tags = {
    Name = "example-nat_1d"
  }
}

resource "aws_nat_gateway" "nat_1d" {
  subnet_id     = aws_subnet.this.id
  allocation_id = aws_eip.nat_1d.id

  tags = {
    Name = "example-1d"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  tags = {
    Name = "example-public"
  }
}

resource "aws_route" "public" {
  destination_cidr_block = "0.0.0.0/0"
  route_table_id         = aws_route_table.public.id
  gateway_id             = aws_internet_gateway.main.id
}

resource "aws_route_table_association" "public_1d" {
  subnet_id      = aws_subnet.this.id
  route_table_id = aws_route_table.public.id
}

resource "aws_security_group" "this" {
  name        = "example-security-group"
  description = "Example security group"
  vpc_id      = aws_vpc.this.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, {
    Name = "example-security-group"
  })
}

resource "aws_instance" "this" {
  ami           = "ami-0df2ca8a354185e1e"
  instance_type = "t3.medium"
  subnet_id     = aws_subnet.this.id
  //user_data     = file("${path.module}/setup.sh")


  vpc_security_group_ids = [
    aws_security_group.this.id
  ]

  root_block_device {
    volume_size = 30
    volume_type = "gp3"
  }

  key_name                    = "test-key"
  associate_public_ip_address = true

  iam_instance_profile = "AmazonSSMRoleForInstancesQuickSetup"

  tags = merge(local.common_tags, {
    Name = "example-instance"
  })
}
