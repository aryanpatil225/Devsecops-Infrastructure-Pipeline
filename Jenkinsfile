pipeline {
    agent any
    
    environment {
        PROJECT_NAME = 'DevSecOps-Infrastructure-Pipeline'
        TERRAFORM_DIR = 'terraform'
        SCAN_SEVERITY = 'CRITICAL,HIGH,MEDIUM'
    }
    
    stages {
        stage('Checkout') {
            steps {
                echo '🔄 Stage 1: Checkout'
                checkout scm
                sh 'ls -la'
                sh 'ls -la ${TERRAFORM_DIR}/ || echo "Terraform dir missing"'
                echo '✅ Checkout complete'
            }
        }
        
        stage('Security Scan') {
            steps {
                echo '🔒 Stage 2: Trivy Security Scan'
                dir("${TERRAFORM_DIR}") {
                    sh '''
                        docker run --rm \\
                          -v $(pwd):/tf \\
                          aquasec/trivy:latest \\
                          config /tf \\
                          --severity ${SCAN_SEVERITY} \\
                          --format table
                    '''
                }
                echo '✅ Security scan complete'
            }
        }
        
        stage('Terraform Plan') {
            steps {
                echo '📝 Stage 3: Terraform Plan'
                dir("${TERRAFORM_DIR}") {
                    sh '''
                        apt-get update -y
                        curl -fsSL https://apt.releases.hashicorp.com/gpg | gpg --dearmor -o /tmp/hashicorp.gpg
                        echo "deb [signed-by=/tmp/hashicorp.gpg] https://apt.releases.hashicorp.com $(. /etc/os-release && echo "$VERSION_ID") main" > /tmp/hashicorp.list
                        apt-get update -y
                        apt-get install -y terraform
                        terraform init
                        terraform validate
                        terraform plan
                    '''
                }
                echo '✅ Terraform plan complete'
            }
        }
    }
    
    post {
        success {
            echo '🎉 PIPELINE SUCCESS ✅'
        }
        failure {
            echo '❌ PIPELINE FAILED - Check logs'
        }
    }
}

