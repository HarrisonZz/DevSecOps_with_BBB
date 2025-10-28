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
                # Web App
                kubectl apply -f web_app/role/
                kubectl apply -f web_app/fluent-bit_cm.yaml
                kubectl apply -f redis/secret.yaml

                # Nginx Gateway API
                kubectl apply -f Nginx/certs_for_test/tls_secret.yaml

                '''
            }
        }
    }

    stage('Deploy Web App to K3S') {
      steps {
        dir('Kubernetes') {
            sh '''

            echo "[*] Applying Web app manifests..."
            
            kubectl apply -f redis/ 
            kubectl apply -f web_app/

            kubectl rollout status deployment/web-app -n default --timeout=120s
            '''
        }
      }
    }

    stage('Deploy Gateway API to K3S') {
      steps {
        dir('Kubernetes') {
            sh '''

            echo "[*] Applying Nginx Gateway API manifests..."

            kubectl apply -f Nginx/gateway-api/standard-install.yaml
            helm install ngf Nginx/gateway-api/nginx-gateway-fabric -n nginx-gateway --create-namespace
            
            echo "[*] Waiting for NGINX Gateway controller startup..."
            kubectl rollout status deploy/nginx-gateway -n nginx-gateway --timeout=120s

            kubectl apply -f Nginx/gateway-api/gateway.yaml
            kubectl apply -f Nginx/gateway-api/httproute.yaml

            for i in {1..30}; do
                STATUS=$(kubectl get httproute web-route -n default -o jsonpath='{.status.parents[0].conditions[?(@.type=="Accepted")].status}')
                if [ "$STATUS" != "True" ]; then
                    echo "❌ HTTPRoute not accepted by Gateway!"
                    break
                fi
                sleep 2
            done

            if [ "$STATUS" != "True" ]; then
                echo "❌ HTTPRoute not accepted!"
                kubectl describe httproute web-route -n default
                exit 1
            fi
    
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
            sh '''
            kubectl delete -f Kubernetes/web_app/ --ignore-not-found=true
            kubectl delete -f Kubernetes/web_app/role/ --ignore-not-found=true

            kubectl delete -f Kubernetes/redis/ --ignore-not-found=true

            kubectl delete -f Nginx/gateway-api/httproute.yaml
            kubectl delete -f Nginx/gateway-api/gateway.yaml
            helm uninstall ngf -n nginx-gateway --create-namespace
            kubectl delete -f Nginx/gateway-api/standard-install.yaml
            
            '''
        }

        always {
            echo "[*] Post stage completed — cluster state after cleanup:"
        }
    }
}