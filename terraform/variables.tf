variable "aws_region" {
  description = "AWS Region"
  type        = string
  default     = "ap-south-1"
}

variable "ami_id" {
  description = "Ubuntu Server 22.04 LTS AMI"
  type        = string
  default     = "ami-0e670eb768a5fc3d4"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t2.micro"
}

variable "admin_ssh_cidr" {
  description = "Admin SSH access - YOUR_PUBLIC_IP/32"
  type        = string
}

variable "app_port" {
  description = "Application port"
  type        = number
  default     = 8000
}
