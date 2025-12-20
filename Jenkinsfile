pipeline {
    agent any
    
    stages {
        stage('Checkout') {
            steps {
                git branch: 'main', url: 'https://github.com/aryanpatil225/Devsecops-Infrastructure-Pipeline.git'
            }
        }
        
        stage('Build Python Docker Image') {
            steps {
                sh '''
                    docker build -t devsecops-app:latest .
                    echo "✅ Python app containerized"
                '''
            }
        }
        
        stage('Trivy Terraform Scan') {
            steps {
                sh '''
                    # Install Trivy
                    if ! command -v trivy &> /dev/null; then
                        wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key | gpg --dearmor > /usr/share/keyrings/trivy.gpg
                        echo "deb [signed-by=/usr/share/keyrings/trivy.gpg] https://aquasecurity.github.io/trivy-repo/deb $(lsb_release -sc) main" > /etc/apt/sources.list.d/trivy.list
                        apt-get update && apt-get install -y trivy
                    fi
                    
                    # Scan Terraform infrastructure
                    trivy config terraform/ --severity CRITICAL,HIGH,MEDIUM --format table
                '''
            }
        }
        
        stage('Terraform Plan') {
    steps {
        sh '''
            # Skip if terraform exists
            if ! command -v terraform &> /dev/null; then
                wget -q https://releases.hashicorp.com/terraform/1.6.6/terraform_1.6.6_linux_amd64.zip
                unzip -o terraform_1.6.6_linux_amd64.zip
                mv terraform /usr/local/bin/
            fi
            
            cd terraform
            terraform init
            terraform validate
            terraform plan
        '''
    }
}
    }
    
    post {
        success {
            echo '✅ Python app built'
            echo '✅ Terraform infrastructure scanned'
            echo '✅ Ready for AWS deployment'
        }
    }
}
