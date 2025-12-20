pipeline {
    agent any
    
    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }
        
        stage('Trivy Security Scan') {
            steps {
                sh '''
                    # Install Trivy
                    wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key | apt-key add -
                    echo "deb https://aquasecurity.github.io/trivy-repo/deb $(lsb_release -sc) main" | tee -a /etc/apt/sources.list.d/trivy.list
                    apt-get update
                    apt-get install -y trivy
                    
                    # Scan Terraform files
                    trivy config terraform/ --format template --template "@contrib/html.tpl" --output report.html || true
                '''
                
                publishHTML(target: [
                    allowMissing: true,
                    alwaysLinkToLastBuild: false,
                    keepAll: true,
                    reportDir: ".",
                    reportFiles: "report.html",
                    reportName: "Trivy Report"
                ])
            }
        }
        
        stage('Terraform Plan') {
            steps {
                sh '''
                    cd terraform
                    terraform init
                    terraform validate
                    terraform plan
                '''
            }
        }
    }
}
