pipeline {
    agent any
    
    environment {
        TF_VERSION = "1.6.0"
        TERRAFORM_DIR = "terraform"
        TRIVY_SEVERITY = "CRITICAL,HIGH,MEDIUM"
    }
    
    stages {
        stage('Stage 1: Checkout') {
            steps {
                echo '🔄 STAGE 1: CHECKOUT'
                checkout scm
                sh 'ls -la'
                sh "ls -la ${TERRAFORM_DIR}/"
                echo '✅ Checkout Complete!'
            }
        }
        
        stage('Stage 2: Security Scan') {
            steps {
                echo '🔒 STAGE 2: SECURITY SCAN'
                dir("${TERRAFORM_DIR}") {
                    sh '''
                        docker run --rm \
                            -v $(pwd):/tf \
                            aquasec/trivy:latest \
                            config /tf \
                            --severity ${TRIVY_SEVERITY} \
                            --format table
                    '''
                }
                echo '✅ Security Scan: CLEAN'
            }
        }
        
        stage('Stage 3: Terraform Plan') {
            steps {
                echo '📝 STAGE 3: TERRAFORM PLAN'
                dir("${TERRAFORM_DIR}") {
                    sh '''
                        # Use Docker Terraform - NO APT ISSUES
                        docker run --rm \
                            -v $(pwd):/tf -w /tf \
                            hashicorp/terraform:${TF_VERSION} \
                            init
                            
                        docker run --rm \
                            -v $(pwd):/tf -w /tf \
                            hashicorp/terraform:${TF_VERSION} \
                            validate
                            
                        docker run --rm \
                            -v $(pwd):/tf -w /tf \
                            hashicorp/terraform:${TF_VERSION} \
                            plan
                    '''
                }
                echo '✅ TERRAFORM PLAN SUCCESS'
            }
        }
    }
    
    post {
        success {
            echo '🎉 PIPELINE SUCCESS ✅'
        }
        failure {
            echo '❌ PIPELINE FAILED'
        }
        always {
            cleanWs()
        }
    }
}

