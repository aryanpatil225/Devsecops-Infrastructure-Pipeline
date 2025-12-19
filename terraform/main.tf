terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# VPC Configuration
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name        = "devsecops-pipeline-vpc"
    Environment = "development"
    Project     = "DevSecOps-Infrastructure-Pipeline"
    Assignment  = "GET-2026"
  }
}

# Public Subnet
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "${var.aws_region}a"
  map_public_ip_on_launch = true

  tags = {
    Name        = "devsecops-pipeline-public-subnet"
    Environment = "development"
    Project     = "DevSecOps-Infrastructure-Pipeline"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name        = "devsecops-pipeline-igw"
    Environment = "development"
    Project     = "DevSecOps-Infrastructure-Pipeline"
  }
}

# Route Table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name        = "devsecops-pipeline-public-rt"
    Environment = "development"
    Project     = "DevSecOps-Infrastructure-Pipeline"
  }
}

# Route Table Association
resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# ================================================
# INTENTIONALLY VULNERABLE SECURITY GROUP
# These vulnerabilities will be detected by Trivy
# ================================================
resource "aws_security_group" "web_sg" {
  name        = "devsecops-pipeline-vulnerable-sg"
  description = "Intentionally vulnerable security group - DO NOT USE IN PRODUCTION"
  vpc_id      = aws_vpc.main.id

  # VULNERABILITY 1: SSH port 22 open to the entire internet
  # Trivy will flag this as CRITICAL
  ingress {
    description = "SSH from anywhere - INTENTIONALLY VULNERABLE"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # ⚠️ CRITICAL VULNERABILITY
  }

  # VULNERABILITY 2: HTTP port open to world
  ingress {
    description = "HTTP from anywhere"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Application port
  ingress {
    description = "Application port"
    from_port   = 8000
    to_port     = 8000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # VULNERABILITY 3: Overly permissive egress rules
  egress {
    description = "All outbound traffic allowed"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "devsecops-pipeline-vulnerable-sg"
    Environment = "development"
    Project     = "DevSecOps-Infrastructure-Pipeline"
    Warning     = "VULNERABLE - For assignment demonstration only"
  }
}

# ================================================
# EC2 INSTANCE WITH INTENTIONAL VULNERABILITIES
# ================================================
resource "aws_instance" "web" {
  ami           = var.ami_id
  instance_type = var.instance_type

  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.web_sg.id]

  # VULNERABILITY 4: Unencrypted EBS volume
  # Trivy will flag this as HIGH severity
  root_block_device {
    volume_size           = 8
    volume_type           = "gp3"
    encrypted             = false # ⚠️ HIGH VULNERABILITY - No encryption at rest
    delete_on_termination = true
  }

  # VULNERABILITY 5: IMDSv2 not enforced
  # Makes instance vulnerable to SSRF attacks
  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "optional" # ⚠️ Should be "required"
    http_put_response_hop_limit = 1
  }

  # VULNERABILITY 6: Monitoring disabled
  monitoring = false

  # User data to setup Docker on the instance
  user_data = base64encode(<<-EOF
              #!/bin/bash
              set -e
              
              # Update system
              apt-get update -y
              apt-get upgrade -y
              
              # Install Docker
              apt-get install -y docker.io curl git
              
              # Start and enable Docker
              systemctl start docker
              systemctl enable docker
              
              # Add ubuntu user to docker group
              usermod -aG docker ubuntu
              
              echo "DevSecOps Pipeline - EC2 setup complete"
              EOF
  )

  tags = {
    Name        = "devsecops-pipeline-web-server"
    Environment = "development"
    Project     = "DevSecOps-Infrastructure-Pipeline"
    Assignment  = "GET-2026"
  }
}

# Outputs
output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

output "instance_id" {
  description = "ID of the EC2 instance"
  value       = aws_instance.web.id
}

output "instance_public_ip" {
  description = "Public IP address of the EC2 instance"
  value       = aws_instance.web.public_ip
}

output "instance_public_dns" {
  description = "Public DNS name of the EC2 instance"
  value       = aws_instance.web.public_dns
}

output "security_group_id" {
  description = "ID of the security group"
  value       = aws_security_group.web_sg.id
}

output "application_url" {
  description = "URL to access the application once deployed"
  value       = "http://${aws_instance.web.public_ip}:8000"
}
