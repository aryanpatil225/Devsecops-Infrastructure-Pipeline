pipeline {
    agent any
    
    environment {
        TERRAFORM_VERSION = "1.6.0"
        TERRAFORM_DIR = "terraform"
        AWS_CREDENTIALS = credentials('aws-credentials')
    }
    
    stages {
        stage('Stage 1: Checkout') {
            steps {
                echo '=========================================='
                echo '🔄 STAGE 1: CHECKOUT'
                echo '=========================================='
                
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
                        echo '🔍 Scanning Terraform configurations for security vulnerabilities...'
                        echo ''
                        
                        echo '📋 Terraform files in directory:'
                        sh 'pwd'
                        sh 'ls -lah *.tf'
                        echo ''
                        
                        echo '🔐 Running Trivy misconfiguration scan...'
                        echo '📊 Scanning for: CRITICAL, HIGH, MEDIUM severity issues'
                        echo ''
                        
                        def trivyScanExitCode = sh(
                            script: '''
                                docker run --rm \
                                    -v "$(pwd)":/workspace:ro \
                                    -w /workspace \
                                    aquasec/trivy:latest \
                                    config . \
                                    --scanners misconfig \
                                    --severity CRITICAL,HIGH,MEDIUM \
                                    --format table \
                                    --exit-code 1
                            ''',
                            returnStatus: true
                        )
                        
                        echo ''
                        echo '=========================================='
                        echo '📊 SECURITY SCAN RESULTS'
                        echo '=========================================='
                        
                        if (trivyScanExitCode == 0) {
                            echo '✅ SUCCESS: No security vulnerabilities detected!'
                            echo '✅ All Terraform configurations passed security checks'
                            echo '✅ Infrastructure code is production-ready'
                            echo ''
                            echo '🔐 Security Status: CLEAN'
                        } else {
                            echo '❌ SECURITY VULNERABILITIES DETECTED!'
                            echo ''
                            echo '🔴 CRITICAL: Pipeline is STOPPING due to security issues'
                            echo ''
                            echo '📋 Review the vulnerability table above for:'
                            echo '   • Vulnerability ID (e.g., AVD-AWS-0107)'
                            echo '   • Severity level (CRITICAL/HIGH/MEDIUM)'
                            echo '   • Affected file and line number'
                            echo '   • Description of the security issue'
                            echo ''
                            echo '🔧 Common Security Issues:'
                            echo '   • Security groups open to 0.0.0.0/0'
                            echo '   • Unencrypted storage volumes'
                            echo '   • Public access to resources'
                            echo '   • Missing IMDSv2 enforcement'
                            echo '   • Insufficient logging/monitoring'
                            echo '   • Weak IAM policies'
                            echo ''
                            echo '📝 Required Actions:'
                            echo '   1. Note the vulnerability ID and file location'
                            echo '   2. Fix the security issue in your Terraform code'
                            echo '   3. Commit and push your changes'
                            echo '   4. Re-run this pipeline'
                            echo ''
                            
                            error('❌ PIPELINE FAILED: Security vulnerabilities must be fixed before deployment!')
                        }
                        
                        echo ''
                        echo '✅ Security Scan Stage Complete!'
                        echo ''
                    }
                }
            }
        }
        
        stage('Stage 3: Terraform Plan') {
            steps {
                echo '=========================================='
                echo '📝 STAGE 3: TERRAFORM PLAN'
                echo '=========================================='
                
                script {
                    dir(TERRAFORM_DIR) {
                        echo '📂 Verifying Terraform files...'
                        sh 'pwd'
                        sh 'ls -la *.tf'
                        echo ''
                        
                        echo '📦 Setting up Terraform...'
                        sh '''
                            if ! command -v terraform &> /dev/null; then
                                echo "Installing Terraform ${TERRAFORM_VERSION}..."
                                rm -f /etc/apt/sources.list.d/hashicorp.list
                                apt-get update -qq
                                apt-get install -y -qq wget unzip > /dev/null 2>&1
                                wget -q https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip
                                unzip -q terraform_${TERRAFORM_VERSION}_linux_amd64.zip
                                mv terraform /usr/local/bin/
                                rm terraform_${TERRAFORM_VERSION}_linux_amd64.zip
                                echo "✅ Terraform ${TERRAFORM_VERSION} installed"
                            else
                                echo "✅ Terraform already available"
                            fi
                            terraform version
                        '''
                        echo ''
                        
                        echo '🎨 Step 1: Terraform Format Check'
                        def fmtResult = sh(
                            script: 'terraform fmt -check -diff',
                            returnStatus: true
                        )
                        if (fmtResult == 0) {
                            echo '✅ All files are properly formatted'
                        } else {
                            echo '⚠️  Some files need formatting (non-blocking)'
                        }
                        echo ''
                        
                        echo '🔧 Step 2: Terraform Init'
                        sh '''
                            export AWS_ACCESS_KEY_ID="${AWS_CREDENTIALS_USR}"
                            export AWS_SECRET_ACCESS_KEY="${AWS_CREDENTIALS_PSW}"
                            export AWS_DEFAULT_REGION="ap-south-1"
                            terraform init -no-color
                        '''
                        echo '✅ Terraform initialized successfully'
                        echo ''
                        
                        echo '✔️  Step 3: Terraform Validate'
                        sh 'terraform validate -no-color'
                        echo '✅ Configuration is valid'
                        echo ''
                        
                        echo '📊 Step 4: Terraform Plan'
                        echo '🔐 Using AWS credentials from Jenkins'
                        sh '''
                            export AWS_ACCESS_KEY_ID="${AWS_CREDENTIALS_USR}"
                            export AWS_SECRET_ACCESS_KEY="${AWS_CREDENTIALS_PSW}"
                            export AWS_DEFAULT_REGION="ap-south-1"
                            
                            echo "✅ AWS credentials loaded"
                            echo "✅ Region: ap-south-1 (Mumbai)"
                            
                            terraform plan -no-color -out=tfplan
                        '''
                        echo '✅ Terraform plan created successfully'
                        echo ''
                        
                        echo '💾 Step 5: Save Plan Output'
                        sh 'terraform show -no-color tfplan > tfplan.txt'
                        echo '✅ Plan saved to terraform/tfplan.txt'
                        echo ''
                        
                        echo '=========================================='
                        echo '📋 TERRAFORM PLAN SUMMARY'
                        echo '=========================================='
                        echo 'ℹ️  Terraform plan created and saved'
                        echo 'ℹ️  Plan file: terraform/tfplan'
                        echo 'ℹ️  Plan output: terraform/tfplan.txt'
                        echo ''
                        echo '🚀 TO APPLY THIS PLAN:'
                        echo '   cd terraform'
                        echo '   terraform apply tfplan'
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
            echo '   ✅ Stage 1: Checkout - PASSED'
            echo '   ✅ Stage 2: Security Scan - PASSED (No vulnerabilities)'
            echo '   ✅ Stage 3: Terraform Plan - PASSED'
            echo ''
            echo "   Build Number: ${env.BUILD_NUMBER}"
            echo "   Duration: ${currentBuild.durationString}"
            echo ''
            echo '🔐 SECURITY STATUS: VERIFIED CLEAN'
            echo '📝 Infrastructure plan ready for deployment'
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
            echo '🔍 FAILURE ANALYSIS:'
            
            if (env.STAGE_NAME == 'Stage 2: Infrastructure Security Scan') {
                echo '   ⚠️  Security vulnerabilities detected in Terraform code'
                echo '   → Review the scan output above'
                echo '   → Fix vulnerabilities in terraform/ directory'
                echo '   → Commit fixes and re-run pipeline'
            } else if (env.STAGE_NAME == 'Stage 3: Terraform Plan') {
                echo '   ⚠️  Terraform configuration error'
                echo '   → Check AWS credentials in Jenkins (ID: aws-credentials)'
                echo '   → Verify terraform.tfvars has admin_ssh_cidr'
                echo '   → Review Terraform syntax in .tf files'
            } else {
                echo '   ⚠️  General pipeline error'
                echo '   → Check console output above for error details'
            }
            
            echo ''
            echo '📝 NEXT STEPS:'
            echo '   1. Review error messages in console output'
            echo '   2. Fix the identified issue'
            echo '   3. Commit your changes to Git'
            echo '   4. Re-run the pipeline'
            echo ''
            echo '=========================================='
        }
        
        always {
            echo ''
            echo '🧹 Cleaning up workspace...'
            dir(TERRAFORM_DIR) {
                sh 'rm -f trivy-results.json 2>/dev/null || true'
            }
            echo '✅ Cleanup complete'
        }
    }
}
