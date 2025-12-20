variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "ap-south-1"
}

variable "ami_id" {
  description = "AMI ID for EC2 instance"
  type        = string
  default     = "ami-0c02fb55956c7d316"  # Ubuntu 22.04 ap-south-1
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t2.micro"
}

variable "admin_ssh_cidr" {
  description = "Admin SSH access CIDR"
  type        = string
  default     = "0.0.0.0/0"  # VULNERABLE for demo
}
