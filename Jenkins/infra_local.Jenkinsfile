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
            script {
                echo "✅ Infra-local pipeline completed successfully — preparing GitHub PR..."

                def jobNameSafe = 'infra-local'
                def newBranch = "${jobNameSafe}-build-${env.BUILD_NUMBER}"

                withCredentials([string(credentialsId: 'github-token', variable: 'GITHUB_TOKEN')]) {
                sh """
                    set -e
                    echo "[*] Cloning Deploy Repo..."

                    rm -rf /tmp/devops_deploy
                    git config --global user.email "jenkins@local"
                    git config --global user.name "Jenkins CI"

                    git clone --depth=1 https://${GIT_USER}:${GITHUB_TOKEN}@github.com/${GIT_USER}/DevOps_Deploy.git /tmp/devops_deploy
                    cd /tmp/devops_deploy

                    echo "[*] Creating new branch: ${newBranch}"
                    git checkout -b ${newBranch}

                    echo "[*] Copying artifacts from pipeline..."
                    mkdir -p terraform/local
                    cp -r ${WORKSPACE}/Terraform_and_Vagrant/on-premises/* terraform/local/

                    git add .
                    git commit -m "CI: ${env.JOB_NAME} build #${env.BUILD_NUMBER} at $(date '+%Y-%m-%d %H:%M:%S')" || echo "No changes to commit"
                    git push -u origin ${newBranch}

                    echo "[*] Creating Pull Request via GitHub API..."
                    curl -s -X POST -H "Authorization: token ${GITHUB_TOKEN}" \
                        -H "Accept: application/vnd.github+json" \
                        https://api.github.com/repos/${GIT_USER}/DevOps_Deploy/pulls \
                        -d "{
                        \\"title\\\": \\"${env.JOB_NAME} build #${env.BUILD_NUMBER}\\",
                        \\"body\\\": \\"Auto-generated PR from Jenkins pipeline.\\",
                        \\"head\\\": \\"${newBranch}\\",
                        \\"base\\\": \\"${BASE_BRANCH}\\"
                        }"
                """
                }
            
            }
        }
    }
}
