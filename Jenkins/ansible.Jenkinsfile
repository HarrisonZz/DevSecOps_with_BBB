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
        dir('Ansible') {
          echo "📘 Verifying Ansible installation..."
          sh '''
            ansible --version || (echo "❌ Ansible not installed" && exit 1)
            ansible-config dump --only-changed || true
          '''
        }
      }
    }

    stage('Test Connection') {
      steps {
        dir('Ansible') {
          echo "🔗 Testing inventory connectivity..."
          sh '''
            echo "Current directory: $(pwd)"
            ls -l
            ansible -i ${INVENTORY_FILE} all -m ping
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
