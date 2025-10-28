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
            kubectl rollout status deploy/ngf-nginx-gateway-fabric -n nginx-gateway --timeout=120s

            kubectl apply -f Nginx/gateway-api/gateway.yaml
            kubectl apply -f Nginx/gateway-api/httproute.yaml
    
            '''
        }
      }
    }

    stage('Deploy Prometheus and Grafana to K3S') {
      steps {
        dir('Kubernetes/monitor') {
            sh '''

            echo "[*] Applying Prometheus and Grafana manifests..."

            kubectl apply -f Prometheus/prometheus.yaml
            kubectl rollout status deploy/prometheus-server -n monitoring --timeout=600s
            kubectl rollout status daemonset/prometheus-prometheus-node-exporter -n monitoring --timeout=600s
            
            echo "[*] Waiting for Grafana startup..."
            kubectl apply -f Grafana/grafana.yaml
            kubectl rollout status deploy/grafana -n monitoring --timeout=600s

    
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

            # Web App
            kubectl delete -f Kubernetes/web_app/ --ignore-not-found=true
            kubectl delete -f Kubernetes/web_app/role/ --ignore-not-found=true

            kubectl delete -f Kubernetes/redis/ --ignore-not-found=true
            
            # Gateway API
            kubectl delete -f Kubernetes/Nginx/gateway-api/httproute.yaml --ignore-not-found=true
            kubectl delete -f Kubernetes/Nginx/gateway-api/gateway.yaml --ignore-not-found=true
            helm uninstall ngf -n nginx-gateway
            kubectl delete -f Kubernetes/Nginx/gateway-api/standard-install.yaml

            # Prometheus & Grafana
            kubectl delete -f Kubernetes/monitor/Grafana/grafana.yaml --ignore-not-found=true
            kubectl delete -f Kubernetes/monitor/Prometheus/prometheus.yaml --ignore-not-found=true

            # Config
            kubectl delete -f Kubernetes/web_app/role/ --ignore-not-found=true
            kubectl delete -f Kubernetes/web_app/fluent-bit_cm.yaml --ignore-not-found=true
            kubectl delete -f Kubernetes/redis/secret.yaml --ignore-not-found=true
            kubectl delete secrets web-tls --ignore-not-found=true
            
            '''
            //deleteDir()
        }

        always {
            echo "[*] Post stage completed — cluster state after cleanup:"
        }
    }
}