from fastapi import FastAPI
from datetime import datetime
import os

app = FastAPI(
    title="DevSecOps Infrastructure Pipeline",
    description="Automated security scanning and deployment pipeline - GET 2026",
    version="1.0.0"
)

@app.get("/")
def read_root():
    """Root endpoint returning application status"""
    return {
        "project": "DevSecOps Infrastructure Pipeline",
        "assignment": "GET 2026 - DevOps Engineer",
        "status": "running",
        "timestamp": datetime.now().isoformat(),
        "environment": os.getenv("ENV", "production")
    }

@app.get("/health")
def health_check():
    """Health check endpoint for monitoring"""
    return {
        "status": "healthy",
        "service": "devsecops-pipeline",
        "timestamp": datetime.now().isoformat()
    }

@app.get("/info")
def info():
    """Information about the assignment and technologies used"""
    return {
        "assignment": "DevOps Engineer - GET 2026",
        "repository": "Devsecops-Infrastructure-Pipeline",
        "technologies": [
            "Python FastAPI",
            "Docker & Docker Compose",
            "Jenkins CI/CD",
            "Trivy Security Scanner",
            "Terraform IaC",
            "AWS EC2 & VPC"
        ],
        "cloud_provider": "AWS",
        "deployment_type": "Automated CI/CD with Security Scanning"
    }
