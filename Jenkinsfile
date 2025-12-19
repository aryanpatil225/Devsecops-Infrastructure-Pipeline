pipeline {
    agent any
    
    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }
        
        stage('Security Scan') {
            steps {
                sh '''
                    apt-get update
                    curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sh -s -- -b /usr/local/bin
                    trivy config terraform/ --severity CRITICAL,HIGH,MEDIUM --format table
                '''
            }
        }
        
        stage('Terraform Plan') {
            steps {
                sh '''
                    # CLEAN OLD BROKEN FILES FIRST
                    rm -f /etc/apt/sources.list.d/hashicorp.list
                    apt-get update
                    
                    # INSTALL DEPENDENCIES
                    apt-get install -y gnupg lsb-release
                    
                    # ADD HASHICORP PROPERLY
                    curl -fsSL https://apt.releases.hashicorp.com/gpg | gpg --dearmor -o /usr/share/keyrings/hashicorp.gpg
                    echo "deb [signed-by=/usr/share/keyrings/hashicorp.gpg] https://apt.releases.hashicorp.com \$(lsb_release -cs) main" | tee /etc/apt/sources.list.d/hashicorp.list
                    
                    apt-get update
                    apt-get install -y terraform
                    
                    cd terraform
                    terraform init
                    terraform validate
                    terraform plan
                '''
            }
        }
    }
}
