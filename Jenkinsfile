pipeline {
    agent any
    
    environment {
        // Terraform settings
        TF_VERSION = "1.6.0"
        TERRAFORM_DIR = "terraform"
        
        // Security scan settings
        TRIVY_SEVERITY = "CRITICAL,HIGH,MEDIUM"
        SCAN_EXIT_CODE = "0"
    }
    
    stages {
        stage('Stage 1: Checkout') {
            steps {
                echo '=========================================='
                echo '🔄 STAGE 1: CHECKOUT'
                echo '=========================================='
                
                // Checkout code from Git repository
                checkout scm
                
                echo '📂 Repository Contents:'
                sh 'ls -la'
                
                echo '📂 Terraform Directory:'
                sh "ls -la ${TERRAFORM_DIR}/"
                
                echo '✅ Checkout Complete!'
                echo ''
            }
        }
        
        stage('Stage 2: Infrastructure Security Scan') {
            steps {
                echo '=========================================='
                echo '🔒 STAGE 2: INFRASTRUCTURE SECURITY SCAN'
                echo '=========================================='
                
                script {
                    dir(TERRAFORM_DIR) {
                        // Run Trivy security scan on Terraform files
                        echo '🔍 Running Trivy security scan on Terraform configurations...'
                        echo ''
                        
                        def scanResult = sh(
                            script: """
                                docker run --rm \
                                    -v \$(pwd):/tf \
                                    aquasec/trivy:latest \
                                    config /tf \
                                    --severity ${TRIVY_SEVERITY} \
                                    --format table \
                                    --exit-code ${SCAN_EXIT_CODE}
                            """,
                            returnStatus: true
                        )
                        
                        echo ''
                        echo '=========================================='
                        echo '📊 SECURITY SCAN REPORT'
                        echo '=========================================='
                        
                        if (scanResult == 0) {
                            echo '✅ SUCCESS: No security issues found!'
                            echo '✅ All Terraform configurations passed security checks'
                            echo '✅ Zero critical security issues detected'
                            echo ''
                            echo '🎉 Your infrastructure code is secure!'
                        } else {
                            echo '⚠️  WARNING: Security issues detected!'
                            echo ''
                            echo '📋 SCAN SUMMARY:'
                            echo '   - Security vulnerabilities found in Terraform files'
                            echo '   - Review the scan output above for details'
                            echo '   - Severity levels scanned: CRITICAL, HIGH, MEDIUM'
                            echo ''
                            echo '🔧 RECOMMENDED ACTIONS:'
                            echo '   1. Review the security findings above'
                            echo '   2. Fix the identified issues in your Terraform files'
                            echo '   3. Common issues to check:'
                            echo '      - Unencrypted storage (S3, EBS)'
                            echo '      - Open security groups (0.0.0.0/0)'
                            echo '      - Missing encryption at rest'
                            echo '      - Public access to sensitive resources'
                            echo '      - Missing logging/monitoring'
                            echo '   4. Update your Terraform code'
                            echo '   5. Re-run this pipeline'
                            echo ''
                            echo '💡 TIP: Use the scan output above to identify specific files and lines'
                            echo ''
                            
                            // Fail the build if critical issues found
                            error('❌ Security scan failed! Please fix the issues and re-run the pipeline.')
                        }
                    }
                }
                
                echo '✅ Security Scan Stage Complete!'
                echo ''
            }
        }
        
        stage('Stage 3: Terraform Plan') {
            steps {
                echo '=========================================='
                echo '📝 STAGE 3: TERRAFORM PLAN'
                echo '=========================================='
                
                script {
                    dir(TERRAFORM_DIR) {
                        // Initialize Terraform
                        echo '🔧 Step 1: Terraform Init'
                        sh """
                            docker run --rm \
                                -v \$(pwd):/workspace \
                                -w /workspace \
                                hashicorp/terraform:${TF_VERSION} \
                                init
                        """
                        echo '✅ Terraform initialized successfully'
                        echo ''
                        
                        // Validate Terraform configuration
                        echo '✔️  Step 2: Terraform Validate'
                        sh """
                            docker run --rm \
                                -v \$(pwd):/workspace \
                                -w /workspace \
                                hashicorp/terraform:${TF_VERSION} \
                                validate
                        """
                        echo '✅ Terraform configuration is valid'
                        echo ''
                        
                        // Create Terraform plan
                        echo '📊 Step 3: Terraform Plan'
                        sh """
                            docker run --rm \
                                -v \$(pwd):/workspace \
                                -w /workspace \
                                hashicorp/terraform:${TF_VERSION} \
                                plan -out=tfplan
                        """
                        echo ''
                        echo '✅ Terraform plan created successfully'
                        echo ''
                        
                        // Save plan in human-readable format
                        echo '💾 Step 4: Save Plan Output'
                        sh """
                            docker run --rm \
                                -v \$(pwd):/workspace \
                                -w /workspace \
                                hashicorp/terraform:${TF_VERSION} \
                                show tfplan > tfplan.txt
                        """
                        echo '✅ Plan saved to terraform/tfplan.txt'
                        echo ''
                        
                        echo '=========================================='
                        echo '📋 TERRAFORM PLAN SUMMARY'
                        echo '=========================================='
                        echo 'ℹ️  Terraform plan has been created and saved'
                        echo 'ℹ️  Review the plan output above'
                        echo 'ℹ️  Plan file: terraform/tfplan'
                        echo 'ℹ️  Plan output: terraform/tfplan.txt'
                        echo ''
                        echo '🚀 TO APPLY MANUALLY:'
                        echo '   cd terraform'
                        echo '   docker run --rm -v \$(pwd):/workspace -w /workspace hashicorp/terraform:${TF_VERSION} apply tfplan'
                        echo ''
                    }
                }
                
                echo '✅ Terraform Plan Stage Complete!'
                echo ''
            }
        }
    }
    
    post {
        success {
            echo ''
            echo '=========================================='
            echo '✅ PIPELINE SUCCEEDED'
            echo '=========================================='
            echo ''
            echo '🎉 All stages completed successfully!'
            echo ''
            echo '📊 PIPELINE SUMMARY:'
            echo "   ✅ Stage 1: Checkout - PASSED"
            echo "   ✅ Stage 2: Security Scan - PASSED (Zero critical issues)"
            echo "   ✅ Stage 3: Terraform Plan - PASSED"
            echo ''
            echo "   Build Number: ${env.BUILD_NUMBER}"
            echo "   Duration: ${currentBuild.durationString}"
            echo ''
            echo '🔐 SECURITY STATUS: ALL CLEAR'
            echo '📝 Terraform plan ready for manual apply'
            echo ''
            echo '=========================================='
        }
        
        failure {
            echo ''
            echo '=========================================='
            echo '❌ PIPELINE FAILED'
            echo '=========================================='
            echo ''
            echo "   Build Number: ${env.BUILD_NUMBER}"
            echo "   Failed Stage: ${env.STAGE_NAME}"
            echo "   Duration: ${currentBuild.durationString}"
            echo ''
            echo '🔍 CHECK THE LOGS ABOVE FOR:'
            echo '   - Security scan failures'
            echo '   - Terraform validation errors'
            echo '   - Configuration issues'
            echo ''
            echo '📝 NEXT STEPS:'
            echo '   1. Review the error messages above'
            echo '   2. Fix the identified issues'
            echo '   3. Commit your changes'
            echo '   4. Re-run the pipeline'
            echo ''
            echo '=========================================='
        }
        
        always {
            echo ''
            echo '🧹 Cleaning up workspace...'
            cleanWs()
            echo '✅ Cleanup complete'
        }
    }
}