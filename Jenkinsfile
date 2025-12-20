pipeline {
    agent any
    
    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }
        
        stage('Build Python Docker') {
            steps {
                sh 'docker build -t devsecops-app:latest .'
                echo '✅ Python Docker SUCCESS'
            }
        }
        
        stage('Trivy Terraform Scan') {
            steps {
                sh '''
                    # Clean Trivy repo (fix malformed list)
                    rm -f /etc/apt/sources.list.d/trivy.list
                    
                    # Install lsb-release first
                    apt-get update && apt-get install -y lsb-release
                    
                    # Install Trivy properly
                    if ! command -v trivy &> /dev/null; then
                        wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key | gpg --dearmor -o /usr/share/keyrings/trivy.gpg
                        echo "deb [signed-by=/usr/share/keyrings/trivy.gpg] https://aquasecurity.github.io/trivy-repo/deb $(lsb_release -sc) main" > /etc/apt/sources.list.d/trivy.list
                        apt-get update && apt-get install -y trivy
                    fi
                    
                    # Scan Terraform
                    trivy config terraform/ --severity CRITICAL,HIGH,MEDIUM --format table
                '''
                echo '✅ Trivy Scan COMPLETE'
            }
        }
        
        stage('Terraform Plan') {
            steps {
                sh '''
                    # Clean old terraform first
                    rm -rf /usr/local/bin/terraform*
                    
                    # Download & install fresh
                    wget -q https://releases.hashicorp.com/terraform/1.6.6/terraform_1.6.6_linux_amd64.zip
                    unzip -o -q terraform_1.6.6_linux_amd64.zip
                    mv terraform /usr/local/bin/
                    chmod +x /usr/local/bin/terraform
                    
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
        success { echo '🎉 FULL PIPELINE GREEN ✅' }
    }
}
