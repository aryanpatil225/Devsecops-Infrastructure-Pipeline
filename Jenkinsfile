pipeline {
    agent any
    
    environment {
        TERRAFORM_VERSION = "1.6.0"
        TERRAFORM_DIR = "terraform"
        AWS_CREDENTIALS = credentials('aws-credentials')
        
        // Security scan thresholds
        FAIL_ON_CRITICAL = "true"
        FAIL_ON_HIGH = "true"
        FAIL_ON_MEDIUM = "false"  // Set to "true" for stricter enforcement
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
                        
                        // Verify Terraform files exist
                        def tfFiles = sh(
                            script: 'find . -name "*.tf" -type f | wc -l',
                            returnStdout: true
                        ).trim()
                        
                        if (tfFiles.toInteger() == 0) {
                            error('❌ No Terraform files found! Aborting pipeline.')
                        }
                        
                        echo "📋 Found ${tfFiles} Terraform configuration file(s)"
                        sh 'find . -name "*.tf" -type f'
                        echo ''
                        
                        // Run TFSec - Production-grade Terraform security scanner
                        echo '🔐 Running TFSec Security Analysis...'
                        echo '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━'
                        
                        def scanStatus = sh(
                            script: '''
                                docker run --rm \
                                    -v $(pwd):/src \
                                    aquasec/tfsec:latest /src \
                                    --format lovely \
                                    --minimum-severity LOW \
                                    --no-color 2>&1 || true
                            ''',
                            returnStdout: true
                        ).trim()
                        
                        echo scanStatus
                        echo '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━'
                        echo ''
                        
                        // Get detailed results with JSON for parsing
                        def scanExitCode = sh(
                            script: '''
                                docker run --rm \
                                    -v $(pwd):/src \
                                    aquasec/tfsec:latest /src \
                                    --format json \
                                    --minimum-severity LOW \
                                    > tfsec-results.json 2>&1
                                echo $?
                            ''',
                            returnStdout: true
                        ).trim().toInteger()
                        
                        // Parse results
                        def results = readJSON file: 'tfsec-results.json'
                        def criticalCount = 0
                        def highCount = 0
                        def mediumCount = 0
                        def lowCount = 0
                        
                        if (results.results) {
                            results.results.each { issue ->
                                switch(issue.severity) {
                                    case 'CRITICAL':
                                        criticalCount++
                                        break
                                    case 'HIGH':
                                        highCount++
                                        break
                                    case 'MEDIUM':
                                        mediumCount++
                                        break
                                    case 'LOW':
                                        lowCount++
                                        break
                                }
                            }
                        }
                        
                        // Display summary
                        echo '=========================================='
                        echo '📊 SECURITY SCAN SUMMARY'
                        echo '=========================================='
                        echo "🔴 CRITICAL Issues: ${criticalCount}"
                        echo "🟠 HIGH Issues: ${highCount}"
                        echo "🟡 MEDIUM Issues: ${mediumCount}"
                        echo "🟢 LOW Issues: ${lowCount}"
                        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
                        echo "📋 Total Issues Found: ${criticalCount + highCount + mediumCount + lowCount}"
                        echo '=========================================='
                        echo ''
                        
                        // Determine if pipeline should fail
                        def shouldFail = false
                        def failureReasons = []
                        
                        if (FAIL_ON_CRITICAL == "true" && criticalCount > 0) {
                            shouldFail = true
                            failureReasons.add("${criticalCount} CRITICAL vulnerability(ies)")
                        }
                        
                        if (FAIL_ON_HIGH == "true" && highCount > 0) {
                            shouldFail = true
                            failureReasons.add("${highCount} HIGH severity vulnerability(ies)")
                        }
                        
                        if (FAIL_ON_MEDIUM == "true" && mediumCount > 0) {
                            shouldFail = true
                            failureReasons.add("${mediumCount} MEDIUM severity vulnerability(ies)")
                        }
                        
                        if (shouldFail) {
                            echo '❌ SECURITY SCAN FAILED'
                            echo ''
                            echo '🚨 PIPELINE BLOCKED DUE TO:'
                            failureReasons.each { reason ->
                                echo "   ❌ ${reason}"
                            }
                            echo ''
                            echo '🔧 ACTION REQUIRED:'
                            echo '   1. Review the detailed scan results above'
                            echo '   2. Fix ALL security vulnerabilities'
                            echo '   3. Common issues to address:'
                            echo '      • SSH/RDP ports open to 0.0.0.0/0'
                            echo '      • Unencrypted storage volumes'
                            echo '      • Missing security group restrictions'
                            echo '      • Publicly accessible resources'
                            echo '      • Weak IAM permissions'
                            echo '   4. Commit fixes and re-run pipeline'
                            echo ''
                            echo '💡 TIP: Check tfsec-results.json for detailed findings'
                            echo ''
                            
                            error('❌ Security vulnerabilities detected! Pipeline cannot proceed to deployment.')
                        } else {
                            echo '✅ SECURITY SCAN PASSED'
                            echo ''
                            if (lowCount > 0 || mediumCount > 0) {
                                echo '⚠️  NOTE: Low/Medium severity issues detected but not blocking deployment'
                                echo '📝 Consider addressing these in future iterations'
                            } else {
                                echo '🎉 No security vulnerabilities detected!'
                                echo '✅ Infrastructure code meets security standards'
                            }
                            echo ''
                            echo '✅ Proceeding to next stage...'
                        }
                        
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
                        // Verify files
                        echo '📂 Verifying Terraform files...'
                        sh 'pwd'
                        sh 'ls -la *.tf'
                        echo ''
                        
                        // Install Terraform
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
                        
                        // Terraform Plan
                        echo '📊 Step 4: Terraform Plan'
                        echo '🔐 Using AWS credentials from Jenkins credential store'
                        sh '''
                            export AWS_ACCESS_KEY_ID="${AWS_CREDENTIALS_USR}"
                            export AWS_SECRET_ACCESS_KEY="${AWS_CREDENTIALS_PSW}"
                            export AWS_DEFAULT_REGION="ap-south-1"
                            
                            echo "✅ AWS credentials loaded from Jenkins"
                            echo "✅ Region: ap-south-1 (Mumbai)"
                            
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
            echo '   ✅ Stage 2: Security Scan - PASSED'
            echo '   ✅ Stage 3: Terraform Plan - PASSED'
            echo ''
            echo "   Build Number: ${env.BUILD_NUMBER}"
            echo "   Duration: ${currentBuild.durationString}"
            echo ''
            echo '🔐 SECURITY: All checks passed'
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
            echo '🔍 COMMON FAILURE CAUSES:'
            echo '   - Security vulnerabilities in Terraform code'
            echo '   - Terraform syntax/validation errors'
            echo '   - AWS credential issues'
            echo '   - Missing required variables'
            echo ''
            echo '📝 TROUBLESHOOTING STEPS:'
            echo '   1. Check the stage that failed above'
            echo '   2. Review error messages in the console output'
            echo '   3. For security failures: Fix vulnerabilities and re-run'
            echo '   4. For Terraform errors: Validate syntax locally'
            echo '   5. For AWS errors: Verify credentials in Jenkins'
            echo ''
            echo '=========================================='
        }
        
        always {
            echo ''
            echo '🧹 Cleaning up workspace...'
            dir(TERRAFORM_DIR) {
                sh 'rm -f tfsec-results.json 2>/dev/null || true'
            }
            echo '✅ Cleanup complete'
        }
    }
}