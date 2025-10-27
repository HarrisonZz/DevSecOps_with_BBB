pipeline {
    agent { label 'windows' }

    environment {
        JENKINS_NODE_COOKIE = 'dontKillMe'
        TF_VAR_copy_script = "copy_to_jenkins.sh"
    }

    stages {

        stage('Checkout Repo') {
            steps {
                // 從 GitHub 抓 main branch
                git branch: 'main', 
                    url: 'https://github.com/HarrisonZz/DevSecOps_with_BBB.git'
            }
        }

        stage('Init Terraform (on-premises)') {
            steps {
                dir('Terraform_and_Vagrant/on-premises') {
                    bat '''
                        echo "[INFO] Initialize Terraform..."
                        terraform init -input=false
                    '''
                }
            }
        }

        stage('Plan Infrastructure') {
            steps {
                dir('Terraform_and_Vagrant/on-premises') {
                    bat '''
                        echo "[INFO] Terraform Plan"
                        terraform plan -out=tfplan
                    '''
                }
            }
        }

        stage('Apply Infrastructure') {
            steps {
                dir('Terraform_and_Vagrant/on-premises') {
                    bat '''
                        echo "[INFO] Applying Terraform..."
                        terraform apply -auto-approve tfplan
                    '''
                }
            }
        }

        stage('Cleanup') {
            steps {
                dir('Terraform_and_Vagrant/on-premises') {
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
