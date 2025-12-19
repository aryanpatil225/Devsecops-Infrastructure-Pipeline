
terraform {
  required_version = ">= 1.5"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.40"
    }
  }
}

provider "aws" {
  region = var.aws_region
  default_tags {
    tags = {
      Project     = "DevSecOps-Infrastructure-Pipeline"
      Environment = "production"
      Security    = "Hardened-v1.0"
    }
  }
}

resource "aws_cloudwatch_log_group" "vpc_logs" {
  name = "/aws/vpc/flow-logs"
}

resource "aws_flow_log" "vpc" {
  vpc_id          = aws_vpc.main.id
  log_group_name  = aws_cloudwatch_log_group.vpc_logs.name
  traffic_type    = "ACCEPT"
}

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "${var.aws_region}a"
  map_public_ip_on_launch = false  
  tags = { Name = "secure-public-subnet" }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
  tags = { Name = "secure-igw" }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = { Name = "secure-rt" }
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

resource "aws_security_group" "web_sg" {
  name        = "secure-web-sg-v1.0"
  description = "Production secure web SG"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "Admin SSH - IP restricted"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.admin_ssh_cidr]
  }

  ingress {
    description = "HTTP Application"
    from_port   = 8000
    to_port     = 8000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["10.0.0.0/16"] 
    description = "VPC internal traffic"
  }

  tags = {
    Name     = "secure-web-sg"
    Security = "Trivy-Fixed-v1.0"
  }
}

resource "aws_instance" "web" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.web_sg.id]

  root_block_device {
    volume_size           = 10
    volume_type           = "gp3"
    encrypted             = true
    delete_on_termination = true
  }

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  monitoring = true

  user_data = base64encode(<<-EOF
#!/bin/bash
apt-get update -y && apt-get upgrade -y
apt-get install -y docker.io ufw
systemctl start docker && systemctl enable docker
usermod -aG docker ubuntu
ufw --force enable && ufw allow 8000/tcp && ufw reload
echo "Secure setup complete"
EOF
  )

  tags = { Name = "secure-web-server", Security = "Trivy-Fixed" }
}

output "instance_public_ip" { value = aws_instance.web.public_ip }
output "app_url" { value = "http://${aws_instance.web.public_ip}:8000" }

