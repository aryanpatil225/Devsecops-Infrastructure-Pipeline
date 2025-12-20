pipeline {
    agent any
    
    environment {
        TERRAFORM_VERSION = "1.6.0"
        AWS_CREDENTIALS = credentials('aws-credentials')
    }
    
    stages {
        stage('1. Checkout') {
            steps {
                echo '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━'
                echo '📥 Stage 1: Checkout'
                echo '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━'
                checkout scm
                sh 'ls -la terraform/'
            }
        }
        
        stage('2. Security Scan') {
            steps {
                echo '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━'
                echo '🔒 Stage 2: Security Scan'
                echo '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━'
                
                script {
                    dir('terraform') {
                        // Run TFSec scan
                        def scanExit = sh(
                            script: '''
                                docker run --rm -v $(pwd):/src aquasec/tfsec:latest /src \
                                    --format lovely --minimum-severity LOW --no-color
                            ''',
                            returnStatus: true
                        )
                        
                        echo "\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
                        
                        if (scanExit == 0) {
                            echo '✅ Security Scan: PASSED'
                            echo '✅ Zero critical issues found'
                        } else {
                            echo '❌ Security Scan: FAILED'
                            echo '⚠️  Vulnerabilities detected above'
                            echo '📝 Fix issues and re-run pipeline'
                            error('Security vulnerabilities found!')
                        }
                        
                        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n"
                    }
                }
            }
        }
        
        stage('3. Terraform Plan') {
            steps {
                echo '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━'
                echo '📝 Stage 3: Terraform Plan'
                echo '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━'
                
                script {
                    dir('terraform') {
                        // Install Terraform
                        sh '''
                            if ! command -v terraform &> /dev/null; then
                                apt-get update -qq
                                apt-get install -y -qq wget unzip
                                wget -q https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip
                                unzip -q terraform_${TERRAFORM_VERSION}_linux_amd64.zip
                                mv terraform /usr/local/bin/
                                rm terraform_${TERRAFORM_VERSION}_linux_amd64.zip
                            fi
                        '''
                        
                        // Terraform commands
                        sh 'terraform init -no-color'
                        sh 'terraform validate -no-color'
                        
                        sh '''
                            export AWS_ACCESS_KEY_ID="${AWS_CREDENTIALS_USR}"
                            export AWS_SECRET_ACCESS_KEY="${AWS_CREDENTIALS_PSW}"
                            export AWS_DEFAULT_REGION="ap-south-1"
                            terraform plan -no-color -out=tfplan
                        '''
                        
                        echo '\n✅ Terraform plan created: terraform/tfplan'
                    }
                }
            }
        }
    }
    
    post {
        success {
            echo '\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━'
            echo '✅ PIPELINE SUCCEEDED'
            echo "Build #${env.BUILD_NUMBER}"
            echo '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n'
        }
        failure {
            echo '\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━'
            echo '❌ PIPELINE FAILED'
            echo "Build #${env.BUILD_NUMBER}"
            echo "Failed at: ${env.STAGE_NAME}"
            echo '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n'
        }
    }
}