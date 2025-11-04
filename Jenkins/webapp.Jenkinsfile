pipeline {
    agent { label 'wsl' }

    environment {
        REPO_URL = 'https://github.com/HarrisonZz/web_server_in_go.git'
        SONARQUBE_ENV = 'SonarQube'
    }

    stages {

        stage('Checkout Repo') {
            steps {
                // 從 GitHub 抓 main branch
                git branch: 'main', 
                    url: 'https://github.com/HarrisonZz/web_server_in_go.git'
            }
        }

        stage('Build Binary (ARMv7)') {
            steps {
                
                sh '''
                    chmod +x go_build.sh
                    ./go_build.sh bin
                '''
                
            }
        }

        stage('SonarQube Analysis') {
            steps {
                withSonarQubeEnv("${SONARQUBE_ENV}") {
                    withCredentials([string(credentialsId: 'sonar_token', variable: 'SONAR_TOKEN')]) {
                        sh '''
                        docker run --rm \
                            -e SONAR_TOKEN=$SONAR_TOKEN \
                            -v "$(pwd)":/usr/src \
                            -w /usr/src \
                            sonarsource/sonar-scanner-cli:latest \
                            -Dproject.settings=/usr/src/.sonar-project.properties
                        '''
                    }
                }
            }
        }

        stage('Docker Login') {
            steps {
                withCredentials([usernamePassword(
                    credentialsId: 'DockerHub',
                    usernameVariable: 'DOCKER_USER',
                    passwordVariable: 'DOCKER_PASS'
                )]) {
                    sh '''
                        echo "$DOCKER_PASS" | docker login -u "$DOCKER_USER" --password-stdin
                    '''
                }
            }
        }

        stage('Build & Test by Trivy & Push Image') {
            steps {
                
                sh '''
                    ./go_build.sh bin

                    if ! docker buildx inspect builder0 >/dev/null 2>&1; then
                        docker buildx create --use --name builder0 --driver docker-container
                    else
                        docker buildx use builder0
                    fi

                    ./go_build.sh image
                '''
            }
        }
    }

    post {
        success {
            echo "[✔] Build and push completed successfully!"
        }
        failure {
            echo "[✖] Build failed — check logs for details."
        }
    }
}
