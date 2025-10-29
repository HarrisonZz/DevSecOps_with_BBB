pipeline {
  agent { label 'wsl' }

  environment {
    AWS_REGION = 'ap-northeast-2'
    S3_BUCKET  = 'bbb-iot-artifact-registry'
    ARTIFACT_NAME = 'iot_build.tar.gz'
    ARTIFACT_PATH = '/tmp/bbb_iot/iot_build.tar.gz'
  }


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

    stage('Run Playbook (Vault Enabled)') {
      steps {
        dir('Ansible_IoT/Build') {
          echo "🚀 Running Ansible playbook with Vault decryption..."
          withCredentials([string(credentialsId: 'vault_pass', variable: 'VAULT_PASS')]) {
            sh '''
              echo "$VAULT_PASS" > /tmp/vault_pass.txt
              chmod 600 /tmp/vault_pass.txt

              ansible-playbook \
                    -i inventory.yml \
                    playbook_build.yml \
                    --extra-vars "@vault.yml" \
                    --vault-password-file /tmp/vault_pass.txt
            '''
          }
        }
      }
    }  
  }

  post {
    success {
      echo "✅ Deployment and build completed successfully! — uploading binary to S3..."
      sh '''
        if [ -f "${ARTIFACT_PATH}" ]; then
          echo "[*] Uploading ${BINARY_NAME} to S3 bucket: ${S3_BUCKET}"
          aws s3 cp "${ARTIFACT_PATH}" "s3://${S3_BUCKET}/artifacts/${ARTIFACT_NAME}" --region ${AWS_REGION}
          echo "[✓] Upload completed and versioned."

        else
          echo "[!] Artifact not found at ${ARTIFACT_PATH}, skipping upload."
        fi
      '''

    }
    failure {
      echo "❌ Build failed. Please check Ansible logs."
    }
    always {
      cleanWs()
    }
  }
}
