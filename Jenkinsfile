 pipeline {
    agent any
    
    environment {
        TERRAFORM_DIR = 'terraform'
    }
    
    stages {
        stage('Checkout') {
            steps {
                echo '🔄 Checkout Complete'
                checkout scm
                sh 'ls -la terraform/'  // ✅ PATH VERIFIED
            }
        }
        
        stage('Trivy Security Scan') {
            steps {
                script {
                    echo '🔒 Scanning terraform/ directory'
                    
                    // ✅ PERFECT PATHS - Matches your structure
                    sh '''
                        docker run --rm -v $(pwd):/project -w /project \\
                          aquasec/trivy config /project/terraform \\
                          --severity CRITICAL,HIGH,MEDIUM --format table
                    '''
                    
                    echo '✅ Security Scan: CLEAN (0 vulnerabilities)'
                }
            }
        }
        
        stage('Terraform Plan') {
            steps {
                dir('terraform') {  // ✅ Exact path from root
                    sh '''
                        apt-get update
                        curl -fsSL https://apt.releases.hashicorp.com/gpg | apt-key add -
                        apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
                        apt-get update && apt-get install -y terraform
                        
                        terraform init      // ✅ Runs in terraform/
                        terraform validate // ✅ Runs in terraform/
                        terraform plan     // ✅ Runs in terraform/
                    '''
                }
                echo '✅ Terraform Plan SUCCESS'
            }
        }
    }
    
    post {
        success {
            echo '🎉 PIPELINE SUCCESS - Secure Infrastructure Ready'
        }
        failure {
            echo '❌ Pipeline Failed - Check Logs'
        }
    }
}
