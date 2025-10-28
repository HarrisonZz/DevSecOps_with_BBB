pipeline {
  agent { label 'wsl' }

  environment {
        KUBECONFIG = '/var/lib/jenkins/.kubeconfig'
    }

  stages {
    stage('Checkout Repository') {
      steps {
        echo "[*] Cloning main repository..."
        git branch: 'main', url: 'https://github.com/HarrisonZz/DevSecOps_with_BBB.git'
      }
    }

    stage('Check Node Readiness') {
        steps {
            dir('Kubernetes/web_app') {
                sh '''
                echo "[*] Verifying all nodes are Ready..."

                NOT_READY=$(kubectl get nodes --no-headers | grep -v " Ready " || true)
                if [ -n "$NOT_READY" ]; then
                    echo "❌ Some nodes are not Ready:"
                    echo "$NOT_READY"
                    exit 1
                fi
                echo "✅ All nodes are Ready."
                '''
            }
        }
    }

    stage('Apply Configs') {        // Secret / ConfigMap / Namespace
        steps {
            dir('Kubernetes') {
                sh '''

                kubectl apply -f web_app/role/
                kubectl apply -f web_app/fluent-bit_cm.yaml
                kubectl apply -f redis/secret.yaml

                '''
            }
        }
    }

    stage('Deploy Web App to K3S') {
      steps {
        dir('Kubernetes') {
            sh '''

            echo "[*] Applying manifests..."

            kubectl apply -f redis/
            kubectl apply -f web_app/

            kubectl rollout status deployment/web-app -n default --timeout=120s
            '''
        }
      }
    }
  }

  post {
        success {
            echo "✅ Test passed, cleaning up resources..."
        }

        failure {
            echo "❌ Test failed, printing diagnostics before cleanup..."
        }

        always {
            echo "[*] Post stage completed — cluster state after cleanup:"
            sh '''
            kubectl delete -f Kubernetes/web_app/ --ignore-not-found=true -n default
            kubectl delete -f Kubernetes/web_app/role/ --ignore-not-found=true -n default

            kubectl delete -f Kubernetes/redis/ --ignore-not-found=true -n default
            '''
        }
    }
}