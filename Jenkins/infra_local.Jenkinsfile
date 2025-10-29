pipeline {
    agent { label 'windows' }

    environment {
        JENKINS_NODE_COOKIE = 'dontKillMe'
        TF_VAR_copy_script = "copy_to_jenkins.sh"

        GIT_USER = 'HarrisonZz'
        BASE_BRANCH = 'main'
    }

    stages {

        stage('Checkout Repo') {
            steps {
                // 從 GitHub 抓 main branch
                git branch: 'main', 
                    url: 'https://github.com/HarrisonZz/DevSecOps_with_BBB.git'
            }
        }

        stage('Init Terraform (on-premises)') {
            steps {
                dir('Terraform_and_Vagrant/on-premises') {
                    bat '''
                        echo "[INFO] Initialize Terraform..."
                        terraform init -input=false
                    '''
                }
            }
        }

        stage('Plan Infrastructure') {
            steps {
                dir('Terraform_and_Vagrant/on-premises') {
                    bat '''
                        echo "[INFO] Terraform Plan"
                        terraform plan -out=tfplan
                    '''
                }
            }
        }

        stage('Apply Infrastructure') {
            steps {
                dir('Terraform_and_Vagrant/on-premises') {
                    bat '''
                        echo "[INFO] Applying Terraform..."
                        terraform apply -auto-approve tfplan
                    '''
                }
            }
        }

        stage('Cleanup') {
            steps {
                dir('Terraform_and_Vagrant/on-premises') {
                    bat '''
                        echo "[INFO] Cleaning temporary files..."
                        del /f /q tfplan
                    '''
                }
            }
        }
    }

    post {
        failure {
            echo "❌ Build failed. Please check logs."
        }
        success {
            echo "✅ Infrastructure successfully deployed."
            script {
                echo "✅ Infra-local pipeline completed successfully — preparing GitHub PR..."

                def jobNameSafe = 'infra-local'
                def newBranch = "${jobNameSafe}-build-${env.BUILD_NUMBER}"

                withCredentials([string(credentialsId: 'github-token', variable: 'GITHUB_TOKEN')]) {
                powershell '''
                    Write-Host "[*] Cloning Deploy Repo..."

                    Remove-Item -Recurse -Force "D:\\tmp\\devops_deploy" -ErrorAction SilentlyContinue
                    New-Item -ItemType Directory -Path "D:\\tmp\\devops_deploy"

                    git config --global user.email "jenkins@local"
                    git config --global user.name "Jenkins CI"
                    git config --global commit.gpgsign false


                    git clone --depth=1 "https://$env:GIT_USER:$env:GITHUB_TOKEN@github.com/$env:GIT_USER/DevOps_Deploy.git" "D:\\tmp\\devops_deploy"
                    Set-Location "D:\\tmp\\devops_deploy"

                    $NewBranch = "$env:JOB_NAME-build-$env:BUILD_NUMBER"
                    Write-Host "[*] Creating new branch: $NewBranch"
                    git checkout -b $NewBranch

                    Write-Host "[*] Copying artifacts..."
                    New-Item -ItemType Directory -Force -Path "terraform\\local" | Out-Null
                    Copy-Item "$env:WORKSPACE\\Terraform_and_Vagrant\\on-premises\\scripts" -Destination "terraform\\local" -Recurse -Force
                    Copy-Item "$env:WORKSPACE\\Terraform_and_Vagrant\\on-premises\\main.tf" -Destination "terraform\\local" -Force
                    Copy-Item "$env:WORKSPACE\\Terraform_and_Vagrant\\on-premises\\Vagrantfile" -Destination "terraform\\local" -Force
                    Copy-Item "$env:WORKSPACE\\Terraform_and_Vagrant\\on-premises\\variable.tf" -Destination "terraform\\local" -Force

                    git add .
                    $DateNow = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
                    git commit -m "CI: $env:JOB_NAME build #$env:BUILD_NUMBER at $DateNow"
                    git push -u origin $NewBranch

                    Write-Host "[*] Creating Pull Request via GitHub API..."
                    $body = @{
                        title = "$env:JOB_NAME build #$env:BUILD_NUMBER"
                        body  = "Auto-generated PR from Jenkins pipeline."
                        head  = "$NewBranch"
                        base  = "$env:BASE_BRANCH"
                    } | ConvertTo-Json

                    Invoke-RestMethod -Uri "https://api.github.com/repos/$env:GIT_USER/DevOps_Deploy/pulls" `
                        -Headers @{ Authorization = "token $env:GITHUB_TOKEN"; Accept = "application/vnd.github+json" } `
                        -Method POST -Body $body

                '''
                }
            
            }
        }
    }
}
