pipeline {
    agent any
    
    environment {
        TERRAFORM_DIR = 'terraform'
        SCAN_SEVERITY = 'CRITICAL,HIGH,MEDIUM'
    }
    
    stages {
        stage('Checkout') {
            steps {
                echo '========================================='
                echo 'Stage 1: Checking out code from repository'
                echo '========================================='
                checkout scm
                
                echo 'Code checkout completed successfully!'
                sh 'ls -la'
            }
        }
        
        stage('Infrastructure Security Scan') {
            steps {
                script {
                    echo '========================================='
                    echo 'Stage 2: Running Trivy Security Scan'
                    echo '========================================='
                    echo 'Scanning Terraform files for security vulnerabilities...'
                    
                    // This will FAIL on first run due to intentional vulnerabilities
                    def scanResult = sh(
                        script: """
                            docker run --rm \
                              -v \$(pwd):/src \
                              aquasec/trivy:latest \
                              config /src/${TERRAFORM_DIR} \
                              --severity ${SCAN_SEVERITY} \
                              --format table \
                              --exit-code 1
                        """,
                        returnStatus: true
                    )
                    
                    if (scanResult != 0) {
                        echo '⚠️  SECURITY VULNERABILITIES DETECTED! ⚠️'
                        echo 'Check the scan output above for details.'
                        echo 'Pipeline will fail to prevent insecure deployment.'
                        error('Security scan failed - vulnerabilities found!')
                    } else {
                        echo '✅ Security scan passed - no critical vulnerabilities found!'
                    }
                }
            }
        }
        
        stage('Terraform Plan') {
            steps {
                echo '========================================='
                echo 'Stage 3: Running Terraform Plan'
                echo '========================================='
                
                dir("${TERRAFORM_DIR}") {
                    sh 'terraform init'
                    sh 'terraform validate'
                    sh 'terraform plan -out=tfplan'
                }
                
                echo 'Terraform plan completed successfully!'
            }
        }
    }
    
    post {
        always {
            echo '========================================='
            echo 'Pipeline Execution Summary'
            echo '========================================='
            echo "Build Number: ${env.BUILD_NUMBER}"
            echo "Build Status: ${currentBuild.result}"
        }
        success {
            echo '✅ Pipeline completed successfully!'
            echo 'All security checks passed.'
        }
        failure {
            echo '❌ Pipeline failed!'
            echo 'Please review the security scan results above.'
            echo 'Fix the vulnerabilities and re-run the pipeline.'
        }
    }
}