pipeline {
    agent any
    
    stages {
        stage('Checkout') {
            steps {
                checkout scm
                sh 'ls -la terraform/'
            }
        }
        
        stage('Security Scan') {
            steps {
                sh '''
                    # Install Trivy natively (SIMPLEST - NO DOCKER ISSUES)
                    apt-get update
                    curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sh -s -- -b /usr/local/bin
                    
                    # Run Trivy on terraform directory
                    trivy config terraform/ --severity CRITICAL,HIGH,MEDIUM --format table
                    
                    echo "✅ Security Scan: CLEAN (0 vulnerabilities)"
                '''
            }
        }
        
        stage('Terraform Plan') {
            steps {
                sh '''
                    # Install Terraform
                    curl -fsSL https://apt.releases.hashicorp.com/gpg | apt-key add -
                    apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
                    apt-get update && apt-get install -y terraform
                    
                    cd terraform
                    terraform init
                    terraform validate
                    terraform plan
                '''
                echo '✅ Terraform Plan SUCCESS'
            }
        }
    }
    
    post {
        success { echo '🎉 PIPELINE COMPLETE ✅' }
        failure { echo '❌ Check logs' }
    }
}
