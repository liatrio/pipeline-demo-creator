pipeline {
  agent any
  parameters {
    string(name: "pipeline_name", description: "What would you like to name the demo application?")
  }
  stages {
    stage('Create Bitbucket Project') {
      steps {
        script {
          BITBUCKET_PROJECT_KEY = params.pipeline_name.substring(0,2).toUpperCase()
        }
        withCredentials([usernamePassword(credentialsId: 'BitbucketCreds', passwordVariable: 'passwordVariable', usernameVariable: 'usernameVariable')]){
          sh "curl -X POST -v -u ${env.usernameVariable}:${env.passwordVariable} http://bitbucket.liatr.io/rest/api/1.0/projects -H \"Content-Type: application/json\" -d \'{\"key\": \"\'${BITBUCKET_PROJECT_KEY}\'\", \"name\": \"\'${params.pipeline_name}\'\", \"description\": \"\'${params.pipeline_name}\'- Built by automation\"}\'"
        }
      }
    }
    stage('Stage 2') {
      steps {
        echo 'Stage 2'
      }
    }
  }
}
