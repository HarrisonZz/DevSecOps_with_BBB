pipeline {

  environment {
    ANSIBLE_CONFIG = "ansible.jenkins.cfg"
    INVENTORY_FILE = 'inventory.yml'
    PLAYBOOK_FILE  = 'playbooks/site.yml'
    KUBECONFIG_FILE = '.kubeconfig'

    GIT_REPO_URL = 'https://github.com/HarrisonZz/DevOps_Deploy.git'
    GIT_USER = 'HarrisonZz'
    BRANCH = 'main'
  }

  agent { label 'wsl' }
  stages {
    stage('Verify Environment') {
      steps {
        dir('Ansible') {
          echo "📘 Verifying Ansible installation..."
          sh '''
            ansible --version || (echo "❌ Ansible not installed" && exit 1)
            ansible-config dump --only-changed || true
            ansible-galaxy collection install -r requirements.yml
          '''
        }
      }
    }

    stage('Syntax Check (Optional)') {
      steps {
        dir('Ansible') {
          echo "🧩 Checking playbook syntax..."
          sh '''
            ansible-playbook -i ${INVENTORY_FILE} ${PLAYBOOK_FILE} --syntax-check
          '''
        }
      }
    }

    stage('Run Playbook (Vault Enabled)') {
      steps {
        dir('Ansible') {
          echo "🚀 Running Ansible playbook with Vault decryption..."
          withCredentials([string(credentialsId: 'ansible-vault-pass', variable: 'VAULT_PASS')]) {
            sh '''
              echo "$VAULT_PASS" > /tmp/vault_pass.txt
              chmod 600 /tmp/vault_pass.txt

              ansible-playbook -i ${INVENTORY_FILE} ${PLAYBOOK_FILE} \
                --vault-password-file /tmp/vault_pass.txt
            '''
          }
        }
      }
    }

    stage('Fetch Kubeconfig') {
            steps {
                script {
                    // 1. 獲取 Jenkins Agent 的 $HOME 絕對路徑
                    def agentHome = sh(script: 'echo $HOME', returnStdout: true).trim()
                    def agentKubeconfigPath = "${agentHome}/.kubeconfig"
                    
                    env.KUBECONFIG = agentKubeconfigPath
                    
                    echo "✅ KUBECONFIG 變數已設定為: ${env.KUBECONFIG}"
                }
            }
    }

    stage('Test kubectl Connection') {
            steps {
                // 在此階段，KUBECONFIG 變數將自動可用
                sh '''
                    echo "--- Testing kubectl ---"
                    kubectl get nodes
                '''
            }
    }
    
  }


  post {
    always {
      echo "Cleaning workspace..."
    }
    success {
      echo "Ansible pipeline completed successfully."
      script {
        echo "✅ Ansible pipeline completed successfully — preparing GitHub PR..."

        def newBranch = "${env.JOB_NAME}-build-${env.BUILD_NUMBER}"

        withCredentials([string(credentialsId: 'github-token', variable: 'GITHUB_TOKEN')]) {
            withEnv(["NEW_BRANCH=${newBranch}"]) { 
            sh '''#!/bin/bash
              set -e
              echo "[*] Cloning Deploy Repo..."

              rm -rf /tmp/devops_deploy
              git config --global user.email "jenkins@local"
              git config --global user.name "Jenkins CI"
              git config --global commit.gpgsign false

              git clone --depth=1 https://$GIT_USER:$GITHUB_TOKEN@github.com/$GIT_USER/DevOps_Deploy.git /tmp/devops_deploy
              cd /tmp/devops_deploy

              echo "[*] Creating new branch: $NEW_BRANCH"
              git checkout -b "$NEW_BRANCH"

              echo "[*] Copying artifacts from pipeline..."
              mkdir -p ansible/local
              cp -r "$WORKSPACE/Ansible/"* ansible/local/

              git add .
              git commit -m "CI: $JOB_NAME build #$BUILD_NUMBER at $(date '+%Y-%m-%d %H:%M:%S')" || echo "No changes to commit"

              if ! git diff --cached --quiet; then
                git push -u origin "$NEW_BRANCH"

                echo "[*] Creating Pull Request via GitHub API..."
                PR_DATA=$(cat <<EOF
                {
                  "title": "$JOB_NAME build #$BUILD_NUMBER",
                  "body": "Auto-generated PR from Jenkins pipeline.",
                  "head": "$NEW_BRANCH",
                  "base": "main"
                }
                EOF
                )
                curl -s -X POST -H "Authorization: token $GITHUB_TOKEN" \
                    -H "Accept: application/vnd.github+json" \
                    "https://api.github.com/repos/$GIT_USER/DevOps_Deploy/pulls" \
                    -d "$PR_DATA"
              else
                echo "[!] No changes detected. Skipping push and PR creation."
              fi
            '''
          }
        }
      
      }
    }
    failure {
      echo "Ansible pipeline failed."
    }
  }
}
