output "ssh_command" {
  description = "SSH command to connect to instance (WARNING: Vulnerable configuration)"
  value       = "ssh -i your-key.pem ubuntu@${aws_instance.web.public_ip}"
}

output "deployment_info" {
  description = "Deployment information"
  value = {
    project     = "DevSecOps-Infrastructure-Pipeline"
    assignment  = "GET-2026"
    instance_ip = aws_instance.web.public_ip
    app_url     = "http://${aws_instance.web.public_ip}:8000"
  }
}
