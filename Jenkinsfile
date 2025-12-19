pipeline {
    agent any
    
    environment {
        PROJECT_NAME = 'DevSecOps-Infrastructure-Pipeline'
        TERRAFORM_DIR = 'terraform'
        SCAN_SEVERITY = 'CRITICAL,HIGH,MEDIUM'
    }
    
    stages {
        stage('Checkout') {
            steps {
                echo '🔄 Stage 1: Checkout'
                checkout scm
                sh 'ls -la'
                sh 'ls -la terraform/'
                echo '✅ Checkout complete'
            }
        }
        
        stage('Security Scan') {
            steps {
                script {
                    echo '🔒 Stage 2: Trivy Security Scan'
                    
                    // ✅ FIXED: Correct Docker volume mount & working directory
                    def scanResult = sh(
                        script: """
                            docker run --rm \\
                              -v \$(pwd):/workspace \\
                              -w /workspace \\
                              aquasec/trivy:latest \\
                              config /workspace/${TERRAFORM_DIR} \\
                              --severity ${SCAN_SEVERITY} \\
                              --format table \\
                              --exit-code 1
                        """,
                        returnStatus: true
                    )
                    
                    if (scanResult != 0) {
                        echo '❌ Security vulnerabilities detected'
                        error('Security scan failed')
                    }
                    echo '✅ Security scan PASSED - 0 vulnerabilities'
                }
            }
        }
        
        stage('Terraform Plan') {
            steps {
                echo '📝 Stage 3: Terraform Plan'
                dir("${TERRAFORM_DIR}") {
                    sh '''
                        terraform init
                        terraform validate
                        terraform plan -out=tfplan
                    '''
                }
                echo '✅ Terraform plan complete'
            }
        }
    }
    
    post {
        success {
            echo '🎉 PIPELINE SUCCESS - Secure infrastructure ready for deployment'
        }
        failure {
            echo '❌ PIPELINE FAILED - Review security scan results'
        }
    }
}
