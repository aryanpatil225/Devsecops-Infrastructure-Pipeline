pipeline {
    agent any
    
    environment {
        TERRAFORM_VERSION = "1.6.0"
        TERRAFORM_DIR = "terraform"
        AWS_CREDENTIALS = credentials('aws_credenntials')
        AWS_ACCESS_KEY_ID = "${AWS_CREDENTIALS_USR}"
        AWS_SECRET_ACCESS_KEY = "${AWS_CREDENTIALS_PSW}"
        AWS_DEFAULT_REGION = "ap-south-1"
        
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
        
        stage('2. TFSec Security Scan') {
            steps {
                echo '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━'
                echo '🔒 STAGE 2: INFRASTRUCTURE SECURITY SCAN (TFSec)'
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
                        
                        echo "📋 Found ${tfFiles} Terraform configuration file(s):"
                        sh 'ls -1 *.tf'
                        echo ''
                        
                        echo '🔍 Running TFSec Security Scanner...'
                        echo '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━'
                        
                        // Run TFSec and save JSON report
                        def tfsecExit = sh(
                            script: '''
                                docker run --rm \
                                    -v $(pwd):/src \
                                    aquasec/tfsec:latest /src \
                                    --format json \
                                    --minimum-severity LOW \
                                    --no-color > tfsec-report.json 2>&1
                                exit 0
                            ''',
                            returnStatus: true
                        )
                        
                        // Display human-readable output
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
                        
                        // Parse results from JSON
                        def scanResults = [
                            critical: 0,
                            high: 0,
                            medium: 0,
                            low: 0,
                            total: 0,
                            issues: []
                        ]
                        
                        if (fileExists('tfsec-report.json')) {
                            try {
                                def jsonReport = readJSON file: 'tfsec-report.json'
                                
                                if (jsonReport.results) {
                                    jsonReport.results.each { result ->
                                        scanResults.total++
                                        def severity = result.severity?.toUpperCase() ?: 'UNKNOWN'
                                        
                                        switch(severity) {
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
                                        
                                        scanResults.issues.add([
                                            severity: severity,
                                            rule: result.rule_id ?: 'UNKNOWN',
                                            file: result.location?.filename ?: 'unknown',
                                            line: result.location?.start_line ?: '?',
                                            message: result.description ?: 'No description'
                                        ])
                                    }
                                }
                            } catch (Exception e) {
                                echo "⚠️  Could not parse TFSec JSON: ${e.message}"
                            }
                        }
                        
                        // Display Summary
                        echo ''
                        echo '╔════════════════════════════════════════════╗'
                        echo '║        SECURITY SCAN RESULTS SUMMARY       ║'
                        echo '╠════════════════════════════════════════════╣'
                        echo "║ 🔴 CRITICAL Issues: ${String.format('%27d', scanResults.critical)} ║"
                        echo "║ 🟠 HIGH Issues:     ${String.format('%27d', scanResults.high)} ║"
                        echo "║ 🟡 MEDIUM Issues:   ${String.format('%27d', scanResults.medium)} ║"
                        echo "║ 🟢 LOW Issues:      ${String.format('%27d', scanResults.low)} ║"
                        echo '╠════════════════════════════════════════════╣'
                        echo "║ 📊 TOTAL FINDINGS: ${String.format('%28d', scanResults.total)} ║"
                        echo '╚════════════════════════════════════════════╝'
                        echo ''
                        
                        // Display Issues if any found
                        if (scanResults.issues.size() > 0) {
                            echo '📋 DETECTED ISSUES:'
                            echo '─────────────────────────────────────────────'
                            scanResults.issues.each { issue ->
                                echo "  [${issue.severity}] ${issue.rule}"
                                echo "    File: ${issue.file}:${issue.line}"
                                echo "    Issue: ${issue.message}"
                                echo ""
                            }
                            echo '─────────────────────────────────────────────'
                        }
                        
                        // Determine if should fail
                        def shouldFail = false
                        def blockReasons = []
                        
                        if (BLOCK_ON_CRITICAL == "true" && scanResults.critical > 0) {
                            shouldFail = true
                            blockReasons.add("${scanResults.critical} CRITICAL vulnerability(ies) found")
                        }
                        
                        if (BLOCK_ON_HIGH == "true" && scanResults.high > 0) {
                            shouldFail = true
                            blockReasons.add("${scanResults.high} HIGH severity vulnerability(ies) found")
                        }
                        
                        if (BLOCK_ON_MEDIUM == "true" && scanResults.medium > 0) {
                            shouldFail = true
                            blockReasons.add("${scanResults.medium} MEDIUM severity vulnerability(ies) found")
                        }
                        
                        // Take Action
                        if (scanResults.total == 0) {
                            echo '╔════════════════════════════════════════════╗'
                            echo '║     ✅ SECURITY SCAN PASSED (0 ISSUES) ✅  ║'
                            echo '╚════════════════════════════════════════════╝'
                            echo ''
                            echo '🎉 Excellent! Infrastructure code is secure.'
                            echo '✅ No vulnerabilities detected.'
                            echo '✅ Safe to proceed to next stage.'
                            echo ''
                            
                        } else if (shouldFail) {
                            echo '╔════════════════════════════════════════════╗'
                            echo '║      ❌ SECURITY SCAN FAILED - BLOCKED ❌   ║'
                            echo '╚════════════════════════════════════════════╝'
                            echo ''
                            echo '🚨 PIPELINE BLOCKED - SECURITY VULNERABILITIES DETECTED!'
                            echo ''
                            echo '📋 BLOCKING ISSUES:'
                            blockReasons.each { reason ->
                                echo "   ❌ ${reason}"
                            }
                            echo ''
                            echo '🔧 REQUIRED REMEDIATION:'
                            echo '   1. Review the detailed TFSec output above'
                            echo '   2. Fix ALL issues listed'
                            echo ''
                            echo '💡 COMMON FIXES:'
                            echo '   • SSH/RDP open to 0.0.0.0/0 → Use admin_ssh_cidr'
                            echo '   • Unencrypted resources → Add encrypted = true'
                            echo '   • Overly permissive IAM → Restrict Action/Resource'
                            echo '   • Public resource access → Use specific IPs only'
                            echo ''
                            echo '📂 Full report: terraform/tfsec-report.json'
                            echo ''
                            
                            error('❌ SECURITY VULNERABILITIES BLOCKING DEPLOYMENT')
                            
                        } else {
                            echo '╔════════════════════════════════════════════╗'
                            echo '║  ⚠️  SECURITY SCAN PASSED (WITH WARNINGS) ⚠️ ║'
                            echo '╚════════════════════════════════════════════╝'
                            echo ''
                            echo "Found ${scanResults.total} non-blocking issue(s):"
                            echo "  • ${scanResults.medium} MEDIUM severity"
                            echo "  • ${scanResults.low} LOW severity"
                            echo ''
                            echo '📝 Consider fixing these in future improvements.'
                            echo '✅ Proceeding to next stage...'
                            echo ''
                        }
                    }
                }
            }
        }
        
        stage('3. Terraform Validate & Plan') {
            steps {
                echo '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━'
                echo '📝 STAGE 3: TERRAFORM VALIDATE & PLAN'
                echo '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━'
                
                script {
                    dir(TERRAFORM_DIR) {
                        echo '📦 Step 1: Initialize Terraform'
                        sh 'terraform init -no-color'
                        echo '✅ Terraform initialized'
                        echo ''
                        
                        echo '✔️  Step 2: Validate Configuration'
                        sh 'terraform validate -no-color'
                        echo '✅ Configuration is valid'
                        echo ''
                        
                        echo '📊 Step 3: Generate Terraform Plan'
                        echo '🔐 AWS Credentials: Loaded from Jenkins'
                        echo ''
                        
                        sh '''
                            echo "🔄 Creating infrastructure plan..."
                            terraform plan -no-color -out=tfplan
                        '''
                        echo ''
                        echo '✅ Terraform plan created successfully'
                        echo ''
                        
                        echo '💾 Step 4: Save Plan Output'
                        sh 'terraform show -no-color tfplan > tfplan.txt'
                        echo '✅ Plan saved to tfplan.txt'
                        echo ''
                        
                        echo '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━'
                        echo '✅ TERRAFORM PLAN COMPLETE'
                        echo '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━'
                        echo ''
                    }
                }
            }
        }
    }
    
    post {
        success {
            script {
                dir(TERRAFORM_DIR) {
                    sh '''
                        echo ""
                        echo "╔═══════════════════════════════════════════════╗"
                        echo "║          ✅ PIPELINE SUCCEEDED ✅             ║"
                        echo "╚═══════════════════════════════════════════════╝"
                        echo ""
                        echo "📊 STAGE SUMMARY:"
                        echo "   ✅ Stage 1: Checkout - PASSED"
                        echo "   ✅ Stage 2: Security Scan (TFSec) - PASSED"
                        echo "   ✅ Stage 3: Terraform Plan - PASSED"
                        echo ""
                        echo "📈 Build: #${BUILD_NUMBER}"
                        echo "👤 Started by: ${BUILD_USER:-Jenkins}"
                        echo ""
                        echo "✅ All security checks passed"
                        echo "📄 Terraform plan ready for review"
                        echo ""
                        echo "🚀 NEXT STEP: terraform apply tfplan"
                        echo ""
                        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
                    '''
                }
            }
        }
        
        failure {
            script {
                sh '''
                    echo ""
                    echo "╔═══════════════════════════════════════════════╗"
                    echo "║           ❌ PIPELINE FAILED ❌               ║"
                    echo "╚═══════════════════════════════════════════════╝"
                    echo ""
                    echo "📈 Build: #${BUILD_NUMBER}"
                    echo "❌ Failed Stage: ${STAGE_NAME}"
                    echo ""
                    echo "🔍 TROUBLESHOOTING:"
                    echo ""
                    echo "If Stage 2 (Security Scan) failed:"
                    echo "  • Review vulnerability details above"
                    echo "  • Fix all CRITICAL/HIGH severity issues"
                    echo "  • Check terraform/tfsec-report.json for full report"
                    echo ""
                    echo "If Stage 3 (Terraform Plan) failed:"
                    echo "  • Check Terraform syntax (terraform validate)"
                    echo "  • Verify terraform.tfvars has all required variables"
                    echo "  • Confirm AWS credentials are valid"
                    echo ""
                    echo "📂 Check console output above for exact error message"
                    echo ""
                    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
                '''
            }
        }
        
        always {
            script {
                dir(TERRAFORM_DIR) {
                    // Archive reports
                    if (fileExists('tfsec-report.json')) {
                        archiveArtifacts artifacts: 'tfsec-report.json',
                                        allowEmptyArchive: true,
                                        fingerprint: true
                    }
                    
                    if (fileExists('tfplan.txt')) {
                        archiveArtifacts artifacts: 'tfplan.txt',
                                        allowEmptyArchive: true,
                                        fingerprint: true
                    }
                }
            }
        }
    }
}
