pipeline {
    agent any
    
    environment {
        TERRAFORM_DIR = "terraform"
    }
    
    stages {
        stage('Checkout') {
            steps {
                checkout scm
                echo "✅ Source code pulled"
            }
        }
        
        stage('Terraform Format & Validate') {
            steps {
                dir(TERRAFORM_DIR) {
                    sh 'terraform init'
                    sh 'terraform fmt -check || terraform fmt'
                    sh 'terraform validate'
                    echo "✅ Terraform configuration valid"
                }
            }
        }
        
        stage('Security Scan - Trivy') {
            steps {
                dir(TERRAFORM_DIR) {
                    sh '''
                        echo "🔍 Scanning for vulnerabilities..."
                        docker run --rm -v $(pwd):/scan aquasec/trivy:latest \
                            config /scan --severity CRITICAL,HIGH --format table
                    '''
                }
            }
        }
        
        stage('Terraform Plan') {
            steps {
                dir(TERRAFORM_DIR) {
                    sh '''
                        echo "📋 Generating terraform plan..."
                        terraform plan -out=tfplan
                        terraform show -no-color tfplan > tfplan.txt
                        echo "✅ Plan ready"
                    '''
                }
            }
        }
        
        stage('Docker Build & Scan') {
            steps {
                sh '''
                    echo "🐳 Building Docker image..."
                    docker build -t app:latest .
                    
                    echo "🔍 Scanning Docker image for CVEs..."
                    docker run --rm -v /var/run/docker.sock:/var/run/docker.sock \
                        aquasec/trivy:latest image --severity CRITICAL,HIGH app:latest
                    
                    echo "✅ Docker image scanned"
                '''
            }
        }
    }
    
    post {
        success {
            echo """
            ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
            ✅ PIPELINE PASSED
            ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
            
            ✓ Source code valid
            ✓ Terraform validated
            ✓ Security scan passed
            ✓ Docker image scanned
            ✓ Plan generated
            
            Next: terraform apply tfplan
            ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
            """
        }
        
        failure {
            echo """
            ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
            ❌ PIPELINE FAILED
            ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
            
            Review errors above:
            • Terraform validation error?
            • Security vulnerabilities found?
            • Docker CVEs detected?
            
            Fix and push again
            ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
            """
        }
        
        always {
            archiveArtifacts artifacts: 'terraform/tfplan.txt', allowEmptyArchive: true
            cleanWs()
        }
    }
}
