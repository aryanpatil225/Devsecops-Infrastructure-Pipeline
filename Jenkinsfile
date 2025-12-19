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
                        docker run --rm \\
                          -v $(pwd):/tf -w /tf \\
                          hashicorp/terraform:latest \\
                          init
                        docker run --rm \\
                          -v $(pwd):/tf -w /tf \\
                          hashicorp/terraform:latest \\
                          validate
                        docker run --rm \\
                          -v $(pwd):/tf -w /tf \\
                          hashicorp/terraform:latest \\
                          plan
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