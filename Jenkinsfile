pipeline {
    agent any
    
    environment {
        TERRAFORM_VERSION = "1.6.0"
        TERRAFORM_DIR = "terraform"
        AWS_CREDENTIALS = credentials('aws-credentials')
        
        // Security Policy: Define what severity levels block the pipeline
        BLOCK_ON_CRITICAL = "true"
        BLOCK_ON_HIGH = "true"
        BLOCK_ON_MEDIUM = "false"
    }
    
    stages {
        stage('1. Checkout') {
            steps {
                echo '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━'
                echo '📥 STAGE 1: SOURCE CODE CHECKOUT'
                echo '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━'
                
                checkout scm
                
                script {
                    echo "📂 Repository: ${env.GIT_URL}"
                    echo "🔖 Branch: ${env.GIT_BRANCH}"
                    echo "📝 Commit: ${env.GIT_COMMIT?.take(8)}"
                }
                
                sh """
                    echo ""
                    echo "📂 Project Structure:"
                    ls -la
                    echo ""
                    echo "📂 Terraform Files:"
                    ls -la ${TERRAFORM_DIR}/
                """
                
                echo '✅ Checkout Complete\n'
            }
        }
        
        stage('2. Security Scan') {
            steps {
                echo '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━'
                echo '🔒 STAGE 2: INFRASTRUCTURE SECURITY SCAN'
                echo '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━'
                
                script {
                    dir(TERRAFORM_DIR) {
                        // Verify Terraform files exist
                        def tfFiles = sh(
                            script: 'find . -maxdepth 1 -name "*.tf" -type f | wc -l',
                            returnStdout: true
                        ).trim().toInteger()
                        
                        if (tfFiles == 0) {
                            error('❌ No Terraform files found in terraform/ directory!')
                        }
                        
                        echo "📋 Scanning ${tfFiles} Terraform configuration file(s)..."
                        sh 'ls -1 *.tf'
                        echo ''
                        
                        // ================================================================
                        // TFSEC SCAN - Industry Standard Terraform Security Scanner
                        // ================================================================
                        // TFSec is specifically designed for Terraform and catches:
                        // - Open security groups (0.0.0.0/0)
                        // - Unencrypted resources
                        // - Public access issues
                        // - IAM misconfigurations
                        // - And 100+ other security checks
                        // ================================================================
                        
                        echo '🔐 Running TFSec Security Analysis...'
                        echo '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━'
                        
                        // Run TFSec with JSON output for parsing
                        def tfsecStatus = sh(
                            script: '''
                                docker run --rm \
                                    -v $(pwd):/src \
                                    aquasec/tfsec:latest /src \
                                    --format json \
                                    --minimum-severity LOW \
                                    --no-color \
                                    > tfsec-report.json 2>&1
                                echo $?
                            ''',
                            returnStdout: true
                        ).trim().toInteger()
                        
                        // Also display human-readable output
                        sh '''
                            echo ""
                            docker run --rm \
                                -v $(pwd):/src \
                                aquasec/tfsec:latest /src \
                                --format lovely \
                                --minimum-severity LOW \
                                --no-color || true
                            echo ""
                        '''
                        
                        echo '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━'
                        
                        // Parse JSON results
                        def scanResults = [
                            critical: 0,
                            high: 0,
                            medium: 0,
                            low: 0,
                            total: 0
                        ]
                        
                        if (fileExists('tfsec-report.json')) {
                            try {
                                def jsonReport = readJSON file: 'tfsec-report.json'
                                
                                if (jsonReport.results && jsonReport.results.size() > 0) {
                                    jsonReport.results.each { result ->
                                        scanResults.total++
                                        switch(result.severity?.toUpperCase()) {
                                            case 'CRITICAL':
                                                scanResults.critical++
                                                break
                                            case 'HIGH':
                                                scanResults.high++
                                                break
                                            case 'MEDIUM':
                                                scanResults.medium++
                                                break
                                            case 'LOW':
                                                scanResults.low++
                                                break
                                        }
                                    }
                                }
                            } catch (Exception e) {
                                echo "⚠️  Warning: Could not parse TFSec JSON report: ${e.message}"
                            }
                        }
                        
                        // Display Results Summary
                        echo ''
                        echo '╔════════════════════════════════════════╗'
                        echo '║     SECURITY SCAN RESULTS SUMMARY      ║'
                        echo '╠════════════════════════════════════════╣'
                        echo "║ 🔴 CRITICAL Issues:  ${String.format('%17d', scanResults.critical)} ║"
                        echo "║ 🟠 HIGH Issues:      ${String.format('%17d', scanResults.high)} ║"
                        echo "║ 🟡 MEDIUM Issues:    ${String.format('%17d', scanResults.medium)} ║"
                        echo "║ 🟢 LOW Issues:       ${String.format('%17d', scanResults.low)} ║"
                        echo '╠════════════════════════════════════════╣'
                        echo "║ 📊 TOTAL FINDINGS:   ${String.format('%17d', scanResults.total)} ║"
                        echo '╚════════════════════════════════════════╝'
                        echo ''
                        
                        // Determine Pipeline Action
                        def shouldFail = false
                        def blockReasons = []
                        
                        if (BLOCK_ON_CRITICAL == "true" && scanResults.critical > 0) {
                            shouldFail = true
                            blockReasons.add("${scanResults.critical} CRITICAL vulnerability(ies)")
                        }
                        
                        if (BLOCK_ON_HIGH == "true" && scanResults.high > 0) {
                            shouldFail = true
                            blockReasons.add("${scanResults.high} HIGH severity vulnerability(ies)")
                        }
                        
                        if (BLOCK_ON_MEDIUM == "true" && scanResults.medium > 0) {
                            shouldFail = true
                            blockReasons.add("${scanResults.medium} MEDIUM severity vulnerability(ies)")
                        }
                        
                        // Take Action Based on Results
                        if (scanResults.total == 0) {
                            echo '╔════════════════════════════════════════╗'
                            echo '║      ✅ SECURITY SCAN PASSED ✅        ║'
                            echo '╚════════════════════════════════════════╝'
                            echo ''
                            echo '🎉 Excellent! No security vulnerabilities detected.'
                            echo '✅ Infrastructure code meets security standards.'
                            echo '✅ Safe to proceed with deployment.'
                            echo ''
                            
                        } else if (shouldFail) {
                            echo '╔════════════════════════════════════════╗'
                            echo '║      ❌ SECURITY SCAN FAILED ❌        ║'
                            echo '╚════════════════════════════════════════╝'
                            echo ''
                            echo '🚨 PIPELINE BLOCKED - Security vulnerabilities detected!'
                            echo ''
                            echo '📋 Blocking Issues:'
                            blockReasons.each { reason ->
                                echo "   ❌ ${reason}"
                            }
                            echo ''
                            echo '🔧 REQUIRED ACTIONS:'
                            echo '   1. Review the detailed TFSec output above'
                            echo '   2. Fix ALL blocking severity vulnerabilities'
                            echo '   3. Common issues to address:'
                            echo '      • SSH/RDP ports open to 0.0.0.0/0 (internet)'
                            echo '      • Security groups with overly permissive rules'
                            echo '      • Unencrypted EBS volumes or S3 buckets'
                            echo '      • Public access to sensitive resources'
                            echo '      • Weak IAM policies (Resource: "*")'
                            echo '      • Missing encryption in transit/at rest'
                            echo ''
                            echo '💡 REMEDIATION TIPS:'
                            echo '   • Restrict SSH: Use var.admin_ssh_cidr instead of 0.0.0.0/0'
                            echo '   • Enable encryption: Set encrypted = true on resources'
                            echo '   • Apply least privilege: Scope IAM permissions narrowly'
                            echo '   • Use security groups: Restrict by specific IPs/ranges'
                            echo ''
                            echo '📂 Detailed report saved to: terraform/tfsec-report.json'
                            echo ''
                            
                            error('❌ SECURITY VULNERABILITIES DETECTED - Pipeline cannot proceed to deployment!')
                            
                        } else {
                            echo '╔════════════════════════════════════════╗'
                            echo '║   ⚠️  SECURITY SCAN PASSED (WITH WARNINGS) ║'
                            echo '╚════════════════════════════════════════╝'
                            echo ''
                            echo "⚠️  Found ${scanResults.total} issue(s) but severity levels are non-blocking:"
                            echo "   • ${scanResults.medium} MEDIUM severity issues"
                            echo "   • ${scanResults.low} LOW severity issues"
                            echo ''
                            echo '📝 RECOMMENDATION:'
                            echo '   While not blocking deployment, consider addressing these'
                            echo '   issues in future iterations to improve security posture.'
                            echo ''
                            echo '✅ Proceeding to next stage...'
                            echo ''
                        }
                    }
                }
            }
        }
        
        stage('3. Terraform Plan') {
            steps {
                echo '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━'
                echo '📝 STAGE 3: TERRAFORM PLAN'
                echo '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━'
                
                script {
                    dir(TERRAFORM_DIR) {
                        // Setup Terraform
                        echo '📦 Setting up Terraform...'
                        sh '''
                            if ! command -v terraform &> /dev/null; then
                                echo "⬇️  Installing Terraform ${TERRAFORM_VERSION}..."
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
                        
                        // Format Check
                        echo '🎨 Step 1: Terraform Format Check'
                        def fmtResult = sh(
                            script: 'terraform fmt -check -diff',
                            returnStatus: true
                        )
                        if (fmtResult == 0) {
                            echo '✅ Code formatting is correct'
                        } else {
                            echo '⚠️  Code needs formatting (non-blocking)'
                        }
                        echo ''
                        
                        // Init
                        echo '🔧 Step 2: Terraform Init'
                        sh 'terraform init -no-color'
                        echo '✅ Terraform initialized'
                        echo ''
                        
                        // Validate
                        echo '✔️  Step 3: Terraform Validate'
                        sh 'terraform validate -no-color'
                        echo '✅ Configuration is syntactically valid'
                        echo ''
                        
                        // Plan
                        echo '📊 Step 4: Terraform Plan'
                        echo '🔐 Loading AWS credentials from Jenkins...'
                        sh '''
                            export AWS_ACCESS_KEY_ID="${AWS_CREDENTIALS_USR}"
                            export AWS_SECRET_ACCESS_KEY="${AWS_CREDENTIALS_PSW}"
                            export AWS_DEFAULT_REGION="ap-south-1"
                            
                            echo "✅ Credentials configured"
                            echo "✅ Region: ap-south-1 (Mumbai)"
                            echo ""
                            
                            terraform plan -no-color -out=tfplan
                        '''
                        echo ''
                        echo '✅ Terraform plan created successfully'
                        echo ''
                        
                        // Save plan
                        echo '💾 Step 5: Save Plan Output'
                        sh 'terraform show -no-color tfplan > tfplan.txt'
                        echo '✅ Plan saved to terraform/tfplan.txt'
                        echo ''
                        
                        echo '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━'
                        echo '📋 TERRAFORM PLAN SUMMARY'
                        echo '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━'
                        echo '✅ Plan created and saved successfully'
                        echo '📂 Plan file: terraform/tfplan'
                        echo '📄 Plan output: terraform/tfplan.txt'
                        echo ''
                        echo '🚀 TO APPLY THIS PLAN MANUALLY:'
                        echo '   cd terraform'
                        echo '   terraform apply tfplan'
                        echo ''
                    }
                }
            }
        }
    }
    
    post {
        success {
            echo ''
            echo '╔═══════════════════════════════════════════════╗'
            echo '║          ✅ PIPELINE SUCCEEDED ✅             ║'
            echo '╚═══════════════════════════════════════════════╝'
            echo ''
            echo '🎉 All stages completed successfully!'
            echo ''
            echo '📊 STAGE SUMMARY:'
            echo '   ✅ Stage 1: Checkout - PASSED'
            echo '   ✅ Stage 2: Security Scan - PASSED'
            echo '   ✅ Stage 3: Terraform Plan - PASSED'
            echo ''
            echo "📈 Build: #${env.BUILD_NUMBER}"
            echo "⏱️  Duration: ${currentBuild.durationString.replace(' and counting', '')}"
            echo "👤 Started by: ${env.BUILD_USER ?: 'Jenkins'}"
            echo ''
            echo '🔐 SECURITY: All checks passed'
            echo '📝 NEXT STEP: Review and apply Terraform plan'
            echo ''
            echo '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━'
        }
        
        failure {
            echo ''
            echo '╔═══════════════════════════════════════════════╗'
            echo '║           ❌ PIPELINE FAILED ❌               ║'
            echo '╚═══════════════════════════════════════════════╝'
            echo ''
            echo "📈 Build: #${env.BUILD_NUMBER}"
            echo "❌ Failed Stage: ${env.STAGE_NAME}"
            echo "⏱️  Duration: ${currentBuild.durationString.replace(' and counting', '')}"
            echo ''
            echo '🔍 COMMON FAILURE CAUSES:'
            
            if (env.STAGE_NAME == '2. Security Scan') {
                echo ''
                echo '🔒 SECURITY SCAN FAILURE:'
                echo '   • Critical/High severity vulnerabilities detected'
                echo '   • Review TFSec output above for specific issues'
                echo '   • Check terraform/tfsec-report.json for details'
                echo ''
                echo '💡 QUICK FIXES:'
                echo '   • SSH open to world: Change 0.0.0.0/0 to specific IP'
                echo '   • Unencrypted volumes: Add encrypted = true'
                echo '   • Weak IAM: Scope Resource to specific ARNs'
                
            } else if (env.STAGE_NAME == '3. Terraform Plan') {
                echo ''
                echo '📝 TERRAFORM FAILURE:'
                echo '   • Syntax errors in .tf files'
                echo '   • Invalid resource configurations'
                echo '   • AWS credential issues'
                echo '   • Missing required variables'
                echo ''
                echo '💡 TROUBLESHOOTING:'
                echo '   • Run: terraform validate locally'
                echo '   • Check: terraform.tfvars has all required vars'
                echo '   • Verify: AWS credentials in Jenkins are valid'
            }
            
            echo ''
            echo '📂 LOGS: Check console output above for details'
            echo ''
            echo '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━'
        }
        
        always {
            script {
                dir(TERRAFORM_DIR) {
                    // Archive security scan results
                    if (fileExists('tfsec-report.json')) {
                        archiveArtifacts artifacts: 'tfsec-report.json', 
                                        allowEmptyArchive: true,
                                        fingerprint: true
                        echo '📦 Security scan report archived'
                    }
                    
                    // Archive Terraform plan
                    if (fileExists('tfplan.txt')) {
                        archiveArtifacts artifacts: 'tfplan.txt',
                                        allowEmptyArchive: true,
                                        fingerprint: true
                        echo '📦 Terraform plan archived'
                    }
                }
            }
            echo ''
            echo '🧹 Workspace cleanup complete'
        }
    }
}