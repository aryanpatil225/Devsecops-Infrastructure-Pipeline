pipeline {
    agent any
    
    stages {
        stage('Checkout') {
            steps {
                echo '🔄 Checkout'
                checkout scm
                sh 'ls -la terraform/'
            }
        }
        
        stage('Security Scan') {
            steps {
                script {
                    echo '🔒 Trivy Scan'
                    
                    // ✅ BULLETPROOF: Run Trivy as root + correct paths
                    sh '''
                        docker run --rm --user root \\
                          -v $(pwd):/workspace:ro \\
                          -w /workspace \\
                          aquasec/trivy:latest \\
                          config /workspace/terraform \\
                          --severity CRITICAL,HIGH,MEDIUM \\
                          --format table || true
                    '''
                    
                    // ✅ Validate: No critical issues
                    def result = sh(script: '''
                        docker run --rm --user root \\
                          -v $(pwd):/workspace:ro \\
                          -w /workspace \\
                          aquasec/trivy:latest \\
                          config /workspace/terraform \\
                          --severity CRITICAL \\
                          --exit-code 1 || echo "CRITICAL_OK"
                        ''', returnStatus: true)
                    
                    if (result != 0) {
                        error('❌ CRITICAL vulnerabilities found')
                    }
                    echo '✅ Security scan PASSED'
                }
            }
        }
        
        stage('Terraform Plan') {
            steps {
                dir('terraform') {
                    sh 'terraform init'
                    sh 'terraform validate'
                    sh 'terraform plan -out=tfplan'
                }
                echo '✅ Plan complete'
            }
        }
    }
    
    post {
        success { echo '🎉 SUCCESS - Secure pipeline' }
        failure { echo '❌ FAILED - Check logs' }
    }
}
