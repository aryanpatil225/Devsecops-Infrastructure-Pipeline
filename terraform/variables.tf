variable "aws_region" {
  description = "AWS region for deploying resources"
  type        = string
  default     = "ap-south-1" # Mumbai region - closest to you
}

variable "ami_id" {
  description = "AMI ID for Ubuntu 22.04 LTS in ap-south-1"
  type        = string
  default     = "ami-0e670eb768a5fc3d4" # Ubuntu 22.04 LTS
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t2.micro" # Free tier eligible
}

variable "project_name" {
  description = "Project name for resource tagging"
  type        = string
  default     = "DevSecOps-Infrastructure-Pipeline"
}
