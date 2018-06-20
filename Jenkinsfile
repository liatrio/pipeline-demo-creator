pipeline {
  agent any

  stages {
    stage('Create Bitbucket Project') {
      steps {
        sh 'curl -X POST -v -u user:password http://bitbucket.liatr.io/rest/api/1.0/projects -H "Content-Type: application/json" -d '/{"key": "KEY", "name": "Project Name", "description": "Project Project Name created by automation"/}''
      }
    }
    stage('Stage 2') {
      steps {
        echo 'Stage 2'
      }
    }

  post {
    always {
      // etc...
    }
    failure {
      echo 'Failure'
      // etc
    }
  }
}
