pipeline {

  environment {
    ANSIBLE_CONFIG = "ansible.jenkins.cfg"
    INVENTORY_FILE = 'inventory.ini'
    PLAYBOOK_FILE  = 'playbooks/sites.yml'
  }

  agent { label 'wsl' }
  stages {
    stage('Verify Environment') {
      steps {
        echo "Verifying Ansible installation..."
        sh '''
          ${ANSIBLE_CMD} --version || (echo "Ansible not installed" && exit 1)
        '''
      }
    }

    stage('Test Connection') {
      steps {
        echo "🔗 Testing inventory connectivity..."
        sh '''
          ansible -i ${INVENTORY_FILE} all -m ping
        '''
      }
    }

    stage('Run Playbook (Vault Enabled)') {
      steps {
        echo "🚀 Running Ansible playbook with Vault decryption..."

        // 透過 Jenkins Secret Text Credential 安全注入 Vault 密碼
        withCredentials([string(credentialsId: 'ansible-vault-pass', variable: 'VAULT_PASS')]) {
          sh '''
            echo "$VAULT_PASS" > /tmp/vault_pass.txt
            chmod 600 /tmp/vault_pass.txt

            ansible -i ${INVENTORY_FILE} ${PLAYBOOK_FILE} \
              --vault-password-file /tmp/vault_pass.txt

            shred -u /tmp/vault_pass.txt || rm -f /tmp/vault_pass.txt
          '''
        }
      }
    }
    
    stage('Ansible Deploy') {
      steps {
        withCredentials([string(credentialsId: 'ansible-vault-pass', variable: 'VAULT_PASS')]) {
          sh '''
            echo "$VAULT_PASS" > /tmp/vault_pass.txt
            chmod 600 /tmp/vault_pass.txt

            ansible-playbook -i inventory.ini playbooks/deploy.yml \
              --vault-password-file /tmp/vault_pass.txt

            shred -u /tmp/vault_pass.txt || rm -f /tmp/vault_pass.txt
          '''
        }
      }
    }
  }

  post {
    always {
      echo "Cleaning workspace..."
      deleteDir()
    }
    success {
      echo "Ansible pipeline completed successfully."
    }
    failure {
      echo "Ansible pipeline failed."
    }
  }
}
