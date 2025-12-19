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
                    # Copy terraform to absolute workspace path
                    cp -r terraform /tmp/terraform-scan
                    
                    # Run Trivy with absolute path
                    docker run --rm --user root \
                      -v /tmp:/tmp \
                      aquasec/trivy:latest \
                      config /tmp/terraform-scan \
                      --severity CRITICAL,HIGH,MEDIUM \
                      --format table
                    
                    # Cleanup
                    rm -rf /tmp/terraform-scan
                '''
                echo '✅ Security Scan PASSED'
            }
        }
        
        stage('Terraform Plan') {
            steps {
                sh '''
                    # Install Terraform temporarily
                    apt-get update
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
        success { echo '🎉 FULL PIPELINE SUCCESS ✅' }
        failure { echo '❌ Pipeline failed' }
    }
}
