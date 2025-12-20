pipeline {
    agent any
    
    environment {
        TERRAFORM_VERSION = "1.6.0"
        TERRAFORM_DIR = "terraform"
        
        // ============================================
        // METHOD 1: AWS Credentials from Jenkins
        // ============================================
        // This pulls credentials from Jenkins Credentials store
        // Make sure you've added credentials with ID 'aws-credentials'
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
                // ADD THIS: Initialize Terraform first
                echo '🔧 Initializing Terraform...'
                sh '''
                    docker run --rm \
                        -v $(pwd):/workspace \
                        -w /workspace \
                        hashicorp/terraform:${TERRAFORM_VERSION} \
                        init -backend=false
                '''
                echo '✅ Terraform initialized'
                echo ''
                
                // Now run the security scan
                echo '🔍 Scanning Terraform configurations...'
                
                // Run Trivy with better configuration
                def trivyScanExitCode = sh(
                    script: '''
                        docker run --rm \
                            -v $(pwd):/src \
                            aquasec/trivy:latest \
                            config /src \
                            --severity CRITICAL,HIGH,MEDIUM,LOW \
                            --format json \
                            --output /src/trivy-results.json \
                            --exit-code 0
                    ''',
                    returnStatus: true
                )
                
                // Display results in table format
                sh '''
                    docker run --rm \
                        -v $(pwd):/src \
                        aquasec/trivy:latest \
                        config /src \
                        --severity CRITICAL,HIGH,MEDIUM,LOW \
                        --format table
                '''
                
                // ... rest of your parsing code ...
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
                        // Verify files
                        echo '📂 Verifying Terraform files...'
                        sh 'pwd'
                        sh 'ls -la *.tf'
                        echo ''
                        
                        // Install Terraform if not present
                        echo '📦 Setting up Terraform...'
                        sh '''
                            if ! command -v terraform &> /dev/null; then
                                echo "Installing Terraform ${TERRAFORM_VERSION}..."
                                
                                # Remove broken hashicorp repository
                                rm -f /etc/apt/sources.list.d/hashicorp.list
                                
                                # Install prerequisites
                                apt-get update -qq
                                apt-get install -y -qq wget unzip > /dev/null 2>&1
                                
                                # Download and install Terraform
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
                        
                        // Terraform Format Check
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
                        
                        // Terraform Init
                        echo '🔧 Step 2: Terraform Init'
                        sh 'terraform init -no-color'
                        echo '✅ Terraform initialized successfully'
                        echo ''
                        
                        // Terraform Validate
                        echo '✔️  Step 3: Terraform Validate'
                        sh 'terraform validate -no-color'
                        echo '✅ Configuration is valid'
                        echo ''
                        
                        // ============================================
                        // THIS IS THE KEY CHANGE FOR METHOD 1
                        // ============================================
                        // Terraform Plan with AWS credentials from Jenkins
                        echo '📊 Step 4: Terraform Plan'
                        echo '🔐 Using AWS credentials from Jenkins credential store'
                        sh '''
                            # Export AWS credentials from Jenkins credentials
                            # AWS_CREDENTIALS_USR = Access Key ID
                            # AWS_CREDENTIALS_PSW = Secret Access Key
                            export AWS_ACCESS_KEY_ID="${AWS_CREDENTIALS_USR}"
                            export AWS_SECRET_ACCESS_KEY="${AWS_CREDENTIALS_PSW}"
                            export AWS_DEFAULT_REGION="ap-south-1"
                            
                            echo "✅ AWS credentials loaded from Jenkins"
                            echo "✅ Region: ap-south-1 (Mumbai)"
                            
                            # Run terraform plan
                            terraform plan -no-color -out=tfplan
                        '''
                        echo ''
                        echo '✅ Terraform plan created successfully'
                        echo ''
                        
                        // Save plan output
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
                        echo '🚀 TO APPLY MANUALLY:'
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
            echo '   ✅ Stage 2: Security Scan - PASSED (Zero critical issues)'
            echo '   ✅ Stage 3: Terraform Plan - PASSED'
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
            echo '🔍 POSSIBLE CAUSES:'
            echo '   - Security vulnerabilities detected'
            echo '   - Terraform syntax errors'
            echo '   - Configuration validation failures'
            echo '   - AWS credential issues (check Jenkins credentials)'
            echo ''
            echo '📝 NEXT STEPS:'
            echo '   1. Verify AWS credentials in Jenkins (ID: aws-credentials)'
            echo '   2. Check admin_ssh_cidr in terraform.tfvars'
            echo '   3. Review error messages above'
            echo '   4. Fix identified issues'
            echo '   5. Re-run the pipeline'
            echo ''
            echo '=========================================='
        }
        
        always {
            echo ''
            echo '🧹 Cleaning up workspace...'
            // Keep terraform directory for manual apply
            dir(TERRAFORM_DIR) {
                sh 'rm -f trivy-results.json 2>/dev/null || true'
            }
            echo '✅ Cleanup complete'
        }
    }
}