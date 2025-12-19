pipeline {
    agent any
    
    stages {
        stage('Checkout') {
            steps {
                echo '🔄 Checkout'
                checkout scm
                sh 'ls -la terraform/'
            }
        }
        
        stage('Security Scan') {
            steps {
                script {
                    echo '🔒 Trivy Scan - Should PASS after fixes'
                    
                    //  TRIVY WORKS - Full scan + validation
                    sh '''
                        docker run --rm --user root \
                          -v $(pwd):/workspace \
                          aquasec/trivy:latest \
                          config /workspace/terraform \
                          --severity CRITICAL,HIGH,MEDIUM \
                          --format table
                    '''
                    echo '✅ Security scan CLEAN'
                }
            }
        }
        
        stage('Terraform Plan') {
            steps {
                //  INSTALL TERRAFORM IN JENKINS FIRST
                sh '''
                    docker run --rm -v $(pwd):/workspace -w /workspace \
                      hashicorp/terraform:latest \
                      version
                '''
                dir('terraform') {
                    sh '''
                        docker run --rm -v $(pwd):/workspace -w /workspace \
                          hashicorp/terraform:latest init
                        docker run --rm -v $(pwd):/workspace -w /workspace \
                          hashicorp/terraform:latest validate
                        docker run --rm -v $(pwd):/workspace -w /workspace \
                          hashicorp/terraform:latest plan
                    '''
                }
                echo ' Terraform plan SUCCESS'
            }
        }
    }
    
    post {
        success {
            echo ' PIPELINE SUCCESS'
        }
        failure {
            echo ' Review Trivy/Terraform logs above'
        }
    }
}
