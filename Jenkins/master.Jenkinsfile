pipeline {
  agent { label 'wsl' }

  stages {
    stage('Run Infra-Local') {
      steps {
        build job: 'Infra-Local', wait: true, propagate: true
      }
    }
    stage('Run Config-by-Ansible') {
      steps {
        build job: 'Env-Config/Config-by-Ansible', wait: true, propagate: true
      }
    }
    stage('Run WebApp-Build') {
      steps {
        build job: 'WebApp-Build', wait: true, propagate: true
      }
    }
    stage('Run IoT-App-Build') {
      steps {
        build job: 'AWS-IoT-App/IoT-App-Build', wait: true, propagate: true
      }
    }
    stage('Run K8S-Platform') {
      steps {
        build job: 'K8S-Platform', wait: true, propagate: true
      }
    }
    stage('Run Infra-Cloud') {
      steps {
        build job: 'AWS-IoT-App/Infra-Cloud', wait: true, propagate: true
      }
    }
  }
}
