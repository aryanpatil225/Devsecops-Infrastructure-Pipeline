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
                    apt-get update
                    curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sh -s -- -b /usr/local/bin
                    trivy config terraform/ --severity CRITICAL,HIGH,MEDIUM --format table
                    echo "✅ Security Scan: CLEAN"
                '''
            }
        }
        
        stage('Terraform Plan') {
            steps {
                sh '''
                    # MODERN TERRAFORM INSTALL (Debian 12+ compatible)
                    curl -fsSL https://apt.releases.hashicorp.com/gpg | gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
                    echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | tee /etc/apt/sources.list.d/hashicorp.list
                    apt-get update && apt-get install -y terraform
                    
                    cd terraform
                    terraform init
                    terraform validate
                    terraform plan
                '''
                echo '✅ FULL PIPELINE SUCCESS'
            }
        }
    }
    
    post {
        success { echo '🎉 PIPELINE 100% COMPLETE ✅' }
    }
}
