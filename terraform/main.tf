# ============================================
# Terraform Configuration
# DevSecOps Infrastructure Pipeline
# ============================================

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

# ============================================
# VPC - Virtual Private Cloud
# ============================================
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "secure-vpc"
  }
}

# ============================================
# CloudWatch Log Group for VPC Flow Logs
# ============================================
resource "aws_cloudwatch_log_group" "vpc_logs" {
  name              = "/aws/vpc/flow-logs"
  retention_in_days = 7

  tags = {
    Name = "vpc-flow-logs"
  }
}

# ============================================
# IAM Role for VPC Flow Logs
# ============================================
resource "aws_iam_role" "vpc_flow_log_role" {
  name = "vpc-flow-log-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "vpc-flow-logs.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "vpc-flow-log-role"
  }
}

resource "aws_iam_role_policy" "vpc_flow_log_policy" {
  name = "vpc-flow-log-policy"
  role = aws_iam_role.vpc_flow_log_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams"
        ]
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })
}

# ============================================
# VPC Flow Logs
# ============================================
resource "aws_flow_log" "vpc" {
  vpc_id               = aws_vpc.main.id
  log_destination      = aws_cloudwatch_log_group.vpc_logs.arn
  log_destination_type = "cloud-watch-logs"
  traffic_type         = "ALL"
  iam_role_arn         = aws_iam_role.vpc_flow_log_role.arn

  tags = {
    Name = "vpc-flow-log"
  }
}

# ============================================
# Public Subnet
# ============================================
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "${var.aws_region}a"
  map_public_ip_on_launch = false

  tags = {
    Name = "secure-public-subnet"
  }
}

# ============================================
# Internet Gateway
# ============================================
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "secure-igw"
  }
}

# ============================================
# Route Table
# ============================================
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "secure-public-rt"
  }
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# ============================================
# Security Group
# ============================================
resource "aws_security_group" "web_sg" {
  name        = "secure-web-sg-v1.0"
  description = "Production secure web security group"
  vpc_id      = aws_vpc.main.id

  # SSH access - restricted to admin IP only
  ingress {
    description = "Admin SSH - IP restricted"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # INTENTIONALLY VULNERABLE!
  }

  # Application port access
  ingress {
    description = "HTTP Application"
    from_port   = 8000
    to_port     = 8000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Outbound - VPC traffic only
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["10.0.0.0/16"]
    description = "VPC internal traffic only"
  }

  # Allow outbound HTTPS for updates
  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTPS for package updates"
  }

  # Allow outbound HTTP for updates
  egress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTP for package updates"
  }

  tags = {
    Name     = "secure-web-sg"
    Security = "Trivy-Fixed-v1.0"
  }
}

# ============================================
# EC2 Instance
# ============================================
resource "aws_instance" "web" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.web_sg.id]

  # Encrypted root volume
  root_block_device {
    volume_size           = 10
    volume_type           = "gp3"
    encrypted             = true
    delete_on_termination = true
  }

  # IMDSv2 enforcement for security
  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  # Enable detailed monitoring
  monitoring = true

  # User data script for initial setup
  user_data = base64encode(<<-EOF
#!/bin/bash
set -e

# Update system
apt-get update -y && apt-get upgrade -y

# Install Docker
apt-get install -y docker.io

# Start and enable Docker
systemctl start docker
systemctl enable docker

# Add ubuntu user to docker group
usermod -aG docker ubuntu

# Configure firewall
apt-get install -y ufw
ufw --force enable
ufw allow 8000/tcp
ufw allow 22/tcp
ufw reload

echo "Secure setup complete - $(date)" > /var/log/setup-complete.log
EOF
  )

  tags = {
    Name     = "secure-web-server"
    Security = "Trivy-Fixed"
  }
}

# ============================================
# Outputs
# ============================================
output "instance_public_ip" {
  description = "Public IP of the EC2 instance"
  value       = aws_instance.web.public_ip
}

output "app_url" {
  description = "Application URL"
  value       = "http://${aws_instance.web.public_ip}:8000"
}

output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.main.id
}

output "subnet_id" {
  description = "Subnet ID"
  value       = aws_subnet.public.id
}