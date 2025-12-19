pipeline {
    agent any
    
    environment {
        PROJECT_NAME = 'DevSecOps-Infrastructure-Pipeline'
        TERRAFORM_DIR = 'terraform'
        SCAN_SEVERITY = 'CRITICAL,HIGH,MEDIUM'
        ASSIGNMENT = 'GET-2026'
    }
    
    stages {
        stage('Checkout') {
            steps {
                echo '========================================='
                echo "🔄 Stage 1: Checking out ${PROJECT_NAME}"
                echo '========================================='
                checkout scm
                
                sh 'echo "Repository contents:"'
                sh 'ls -la'
                
                echo "✅ Code checkout completed successfully!"
                echo "Project: ${PROJECT_NAME}"
                echo "Assignment: ${ASSIGNMENT}"
            }
        }
        
        stage('Infrastructure Security Scan') {
            steps {
                script {
                    echo '========================================='
                    echo '🔒 Stage 2: Running Trivy Security Scan'
                    echo '========================================='
                    echo "Project: ${PROJECT_NAME}"
                    echo 'Scanning Terraform files for vulnerabilities...'
                    echo "Severity levels checked: ${SCAN_SEVERITY}"
                    echo ''
                    
                    // Run Trivy scan - WILL FAIL on first run due to intentional vulnerabilities
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
                    
                    echo "========================================="
                    if (scanResult != 0) {
                        echo '⚠️  SECURITY VULNERABILITIES DETECTED!'
                        echo '========================================='
                        echo 'Scan Result Code: ' + scanResult
                        echo ''
                        echo '📋 ACTION REQUIRED:'
                        echo '1. Review the vulnerability report above'
                        echo '2. Copy the complete report for AI analysis'
                        echo '3. Use AI to understand and fix security issues'
                        echo '4. Update Terraform code with fixes'
                        echo '5. Re-run this pipeline'
                        echo ''
                        echo "Project: ${PROJECT_NAME}"
                        echo "Assignment: ${ASSIGNMENT}"
                        echo '========================================='
                        error('Security scan failed - Infrastructure has critical vulnerabilities!')
                    } else {
                        echo '✅ Security scan PASSED!'
                        echo 'No critical vulnerabilities found.'
                        echo "Project: ${PROJECT_NAME} - Secure Infrastructure"
                        echo '========================================='
                    }
                }
            }
        }
        
        stage('Terraform Plan') {
            steps {
                echo '========================================='
                echo '📝 Stage 3: Running Terraform Plan'
                echo '========================================='
                echo "Project: ${PROJECT_NAME}"
                
                dir("${TERRAFORM_DIR}") {
                    sh 'terraform init'
                    sh 'terraform validate'
                    sh 'terraform plan -out=tfplan'
                }
                
                echo '✅ Terraform plan completed successfully!'
            }
        }
    }
    
    post {
        always {
            echo '========================================='
            echo '📊 Pipeline Execution Summary'
            echo '========================================='
            echo "Project: ${PROJECT_NAME}"
            echo "Assignment: ${ASSIGNMENT}"
            echo "Build Number: ${env.BUILD_NUMBER}"
            echo "Build URL: ${env.BUILD_URL}"
            echo "Build Status: ${currentBuild.result}"
            echo '========================================='
        }
        success {
            echo '✅ ✅ ✅ PIPELINE SUCCESSFUL ✅ ✅ ✅'
            echo ''
            echo "Project: ${PROJECT_NAME}"
            echo 'All stages passed!'
            echo 'Infrastructure code is secure and ready for deployment.'
            echo ''
            echo "Assignment: ${ASSIGNMENT} - DevSecOps Pipeline Complete"
        }
        failure {
            echo '❌ ❌ ❌ PIPELINE FAILED ❌ ❌ ❌'
            echo ''
            echo "Project: ${PROJECT_NAME}"
            echo "Assignment: ${ASSIGNMENT}"
            echo ''
            echo '🔍 Next Steps:'
            echo '1. Check the console output above for error details'
            echo '2. If security scan failed: Copy Trivy report and use AI for remediation'
            echo '3. If Terraform failed: Check your configuration syntax'
            echo '4. Fix issues and re-run the pipeline'
            echo ''
            echo 'For security issues, document the AI remediation process.'
        }
    }
}
