def Clean(String stageName) {
    echo "🧹 [Clean] Starting cleanup from stage: ${stageName}"

    def stages = ['ELKStack', 'Prometheus&Grafana', 'GatewayAPI', 'WebApp', 'Config']

    def index = stages.indexOf(stageName)
    if (index == -1) {
        echo "⚠️ Unknown stage name: ${stageName}, skip cleanup."
        return
    }

    for (int i = index; i < stages.size(); i++) {
        def current = stages[i]
        echo "🧹 [Clean] Cleaning resources for: ${current}"

        if (current == 'ELKStack') {
            sh '''
            echo "[ELKStack] 清理 ELK Stack 資源"
            kubectl delete -f Kubernetes/monitor/ELK/logstash.yaml --ignore-not-found=true
            kubectl delete -f Kubernetes/monitor/ELK/logstash_configmap.yaml --ignore-not-found=true
            kubectl delete -f Kubernetes/monitor/ELK/es.yaml --ignore-not-found=true
            kubectl delete -f Kubernetes/monitor/ELK/test-elasticsearch-health.yaml --ignore-not-found=true
            kubectl delete -f Kubernetes/Nginx/gateway-api/es-proxy.yaml --ignore-not-found=true
            kubectl delete -f Kubernetes/Nginx/gateway-api/referenceGrant.yaml --ignore-not-found=true
            helm uninstall kibana -n logging || true
            kubectl label nodes node-agent task- || true
            '''
        }

        if (current == 'Prometheus&Grafana') {
            sh '''
            echo "[Prometheus&Grafana] 清理監控堆疊資源"
            kubectl delete -f Kubernetes/monitor/Grafana/grafana.yaml --ignore-not-found=true
            kubectl delete -f Kubernetes/monitor/Prometheus/prometheus.yaml --ignore-not-found=true
            '''
        }

        if (current == 'GatewayAPI') {
            sh '''
            echo "[GatewayAPI] 清理 Gateway API 元件"
            kubectl delete -f Kubernetes/Nginx/gateway-api/httproute.yaml --ignore-not-found=true
            kubectl delete -f Kubernetes/Nginx/gateway-api/gateway.yaml --ignore-not-found=true
            helm uninstall ngf -n nginx-gateway || true
            kubectl delete -f Kubernetes/Nginx/gateway-api/standard-install.yaml --ignore-not-found=true
            '''
        }

        if (current == 'WebApp') {
            sh '''
            echo "[WebApp] 清理 Web 應用資源"
            kubectl delete -f Kubernetes/web_app/ --ignore-not-found=true
            kubectl delete -f Kubernetes/redis/ --ignore-not-found=true
            '''
        }

        if (current == 'Config') {
            sh '''
            echo "[Config] 清理共用設定資源"
            kubectl delete -f Kubernetes/web_app/role/ --ignore-not-found=true
            kubectl delete -f Kubernetes/web_app/fluent-bit_cm.yaml --ignore-not-found=true
            kubectl delete -f Kubernetes/redis/secret.yaml --ignore-not-found=true
            kubectl delete secret web-tls --ignore-not-found=true
            '''
        }
    }

    echo "✅ [Clean] Finished cleanup up to stage: ${stageName}"
}

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

        post {
            success {
                echo '✅ Config 部署成功'
            }
            failure {
                echo '❌ Config 部署失敗'
                Clean('Config')
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

      post {
            success {
                echo '✅ WebApp 部署成功'
            }
            failure {
                echo '❌ WebApp 部署失敗'
                Clean('WebApp')
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
      post {
            success {
                echo '✅ Gateway API 部署成功'
            }
            failure {
                echo '❌ Gateway API 部署失敗'
                
                Clean('GatewayAPI')
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

      post {
            success {
                echo '✅ Prometheus and Grafana 部署成功'
            }
            failure {
                echo '❌ Prometheus and Grafana 部署失敗'
                
                Clean('Prometheus&Grafana')
            }
        }
    }

    stage('Deploy ELK Stack to K3S') {
      steps {
        dir('Kubernetes/monitor') {
            sh '''

            kubectl label nodes node-agent task=monitor
            echo "[*] Applying ELK Stack manifests..."

            echo "[*] Waiting for ElasticSearch startup..."
            kubectl apply -f ELK/es.yaml
            kubectl rollout status statefulset/elasticsearch-single -n logging --timeout=600s
            kubectl apply -f ELK/test-elasticsearch-health.yaml
            kubectl apply -f ../Nginx/gateway-api/es-proxy.yaml
            kubectl apply -f ../Nginx/gateway-api/referenceGrant.yaml

            echo "[*] Waiting for LogStash startup..."
            kubectl apply -f ELK/logstash_configmap.yaml
            kubectl apply -f ELK/logstash.yaml
            kubectl rollout status deploy/logstash -n logging --timeout=600s

            echo "[*] Waiting for Kibana startup..."
            helm install kibana ./ELK/kibana -n logging -f ./ELK/values/kibana-values.yaml
            kubectl rollout status deploy/kibana -n logging --timeout=600s

    
            '''
        }
      }

      post {
            success {
                echo '✅ ELK Stack 部署成功'
            }
            failure {
                echo '❌ ELK Stack 部署失敗'
                Clean('ELKStack')
            }
        }
    }

  }

  post {
        success {
            echo "✅ Test passed, cleaning up resources..."
            deleteDir()
        }

        failure {
            echo "❌ Test failed, printing diagnostics before cleanup..."
            //deleteDir()
        }

        always {
            echo "[*] Post stage completed — cluster state after cleanup:"
        }
    }
}