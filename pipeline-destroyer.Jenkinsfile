pipeline {
  agent any
  parameters {
    string(name: "pipeline_name", description: "Which pipeline are we destroying today?")
  }
  stages {
    stage('Delete Bitbucket Repos and Project') {
      steps {
        script {
          PROJECT_NAME = params.pipeline_name.replaceAll("[^A-Za-z0-9\\- ]", "").replace(' ', '-').toLowerCase()
          PROJECT_KEY = PROJECT_NAME.substring(0,4).toUpperCase()
        }
        deleteDir()
        withCredentials([usernamePassword(credentialsId: 'BitbucketCreds', passwordVariable: 'passwordVariable', usernameVariable: 'usernameVariable')]){
          sh "curl -X DELETE -v -u ${env.usernameVariable}:${env.passwordVariable} http://bitbucket.liatr.io/rest/api/1.0/projects/${PROJECT_KEY}/repos/pipeline-home"
          sh "curl -X DELETE -v -u ${env.usernameVariable}:${env.passwordVariable} http://bitbucket.liatr.io/rest/api/1.0/projects/${PROJECT_KEY}/repos/pipeline-demo-application"
          sh "curl -X DELETE -v -u ${env.usernameVariable}:${env.passwordVariable} http://bitbucket.liatr.io/rest/api/1.0/projects/${PROJECT_KEY}"
        }
      }
    }
    stage('Delete Jira Project') {
      steps {
        withCredentials([usernamePassword(credentialsId: 'BitbucketCreds', passwordVariable: 'passwordVariable', usernameVariable: 'usernameVariable')]){
          sh "curl -X DELETE -v -u ${env.usernameVariable}:${env.passwordVariable} http://jira.liatr.io/rest/api/2/project/${PROJECT_KEY}"
        }
      }
    }
    /*
    stage('Delete Slack Channel') {
      //TODO - get the slack channel ID and then delete it
      steps {
        withCredentials([string(credentialsId: 'liatrio-demo-slack', variable: 'token')]){
          sh "curl -X POST -H \'Authorization: Bearer ${env.token}\' -H \"Content-Type: application/json\" -d \'{\"name\": \"\'${PROJECT_NAME}\'\", \"token\": \"\'${env.token}\'\"}\' https://liatrio-demo.slack.com/api/channels.delete"
        }
      }
    }
    */
    stage('Delete Confluence space') {
      agent any
      steps {
        script {
          withCredentials([usernamePassword(credentialsId: 'BitbucketCreds', passwordVariable: 'passwordVariable', usernameVariable: 'usernameVariable')]){
            sh "curl -X DELETE -u ${env.usernameVariable}:${env.passwordVariable} http://confluence.liatr.io/rest/api/space/${PROJECT_KEY}"
          }
        }
      }
    }
  }
}
