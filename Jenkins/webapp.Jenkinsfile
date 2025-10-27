pipeline {
    agent any

    environment {
        REPO_URL = 'https://github.com/HarrisonZz/web_server_in_go.git'
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

        stage('Build & Push Image') {
            steps {
                dir('web_server_in_go') {
                    sh '''
                        ./build_bbb.sh image
                    '''
                }
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
