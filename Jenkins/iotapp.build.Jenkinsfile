pipeline {
  agent any

  stages {
    stage('Checkout Repository') {
      steps {
        echo "[*] Cloning main repository..."
        git branch: 'main', url: 'https://github.com/HarrisonZz/DevSecOps_with_BBB.git'
      }
    }

     stage('Copy Certificates & Deploy') {
      steps {
        dir('Ansible_IoT/Build') {
            withCredentials([
            file(credentialsId: 'ROOT_CA_CERT_PATH', variable: 'AWS_CERT'),
            file(credentialsId: 'CLIENT_PRIVATE_KEY_PATH', variable: 'CLIENT_KEY'),
            file(credentialsId: 'CLIENT_CERT_PATH', variable: 'CLIENT_CA')
            ]) {
            sh '''
                echo "[*] Preparing certificates..."
                mkdir -p certs
                cp "$AWS_CERT" certs/AmazonRootCA1.pem
                cp "$CLIENT_KEY"  certs/bbb_cli.key
                cp "$CLIENT_CA"   certs/bbb_cli.pem
            '''
            }
        }
      }
    }

    stage('Deploy and Build on BBB') {
      steps {
        dir('Ansible_IoT/Build') {
            echo "[*] Running Ansible playbook"
            sh '''
                ansible-playbook \
                    -i inventory.yml \
                    playbook_build.yml \
                    --extra-vars "@vault.yml" \
                    --vault-password-file <(echo "$ANSIBLE_VAULT_PASS")
            '''
        }
      }
    }

    
  }

  post {
    success {
      echo "✅ Deployment and build completed successfully!"
    }
    failure {
      echo "❌ Build failed. Please check Ansible logs."
    }
    always {
      cleanWs()
    }
  }
}
