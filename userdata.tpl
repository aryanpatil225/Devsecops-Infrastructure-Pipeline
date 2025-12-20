#!/bin/bash
set -euo pipefail

# Update system
apt-get update -y
apt-get upgrade -y

# Install security & monitoring tools
apt-get install -y docker.io ufw fail2ban awscli cloud-init jq curl

# Secure Docker daemon
systemctl start docker
systemctl enable docker
usermod -aG docker ubuntu

# UFW Firewall (defense in depth)
ufw --force enable
ufw allow ${app_port}/tcp comment "Web Application"
ufw allow 22/tcp comment "Admin SSH"
ufw --force reload

# Fail2Ban intrusion prevention
systemctl enable fail2ban
systemctl start fail2ban

# CloudWatch Agent (optional monitoring)
curl -O https://s3.amazonaws.com/amazoncloudwatch-agent/ubuntu/amd64/latest/amazon-cloudwatch-agent.deb
dpkg -i -E amazon-cloudwatch-agent.deb

echo "✅ Secure server initialization complete"
echo "Application port: ${app_port}"
