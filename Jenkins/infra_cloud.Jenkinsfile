pipeline {
    agent { label 'windows' }

    environment {
        JENKINS_NODE_COOKIE = 'dontKillMe'
    }

    stages {

        stage('Checkout Repo') {
            steps {
                // 從 GitHub 抓 main branch
                git branch: 'main', 
                    url: 'https://github.com/HarrisonZz/DevSecOps_with_BBB.git'
            }
        }

        stage('Init Terraform (Cloud)') {
            steps {
                dir('Terraform_and_Vagrant/aws') {
                    bat '''
                        echo "[INFO] Initialize Terraform..."
                        terraform init -input=false
                    '''
                }
            }
        }

        stage('Plan Infrastructure (PaaS)') {
            steps {
                dir('Terraform_and_Vagrant/aws') {
                    bat '''
                        echo "[INFO] Terraform Plan"
                        terraform plan -out=tfplan
                    '''
                }
            }
        }

        stage('Apply Infrastructure (PaaS)') {
            steps {
                dir('Terraform_and_Vagrant/aws') {
                    bat '''
                        echo "[INFO] Applying Terraform..."
                        terraform apply -auto-approve tfplan
                    '''
                }
            }
        }

        stage('Cleanup') {
            steps {
                dir('Terraform_and_Vagrant/aws') {
                    bat '''
                        echo "[INFO] Cleaning temporary files..."
                        del /f /q tfplan
                    '''
                }
            }
        }
    }

    post {
        failure {
            echo "❌ Build failed. Please check logs."
        }
        success {
            echo "✅ Infrastructure successfully deployed."
        }
    }
}
