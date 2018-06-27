pipeline {
  agent any
  parameters {
    string(name: "pipeline_name", description: "What would you like to name the demo application?")
  }
  stages {
    stage('Create Bitbucket Project and Git Repos') {
      steps {
        script {
          PROJECT_KEY = params.pipeline_name.substring(0,4).toUpperCase()
        }
        deleteDir()
        withCredentials([usernamePassword(credentialsId: 'BitbucketCreds', passwordVariable: 'passwordVariable', usernameVariable: 'usernameVariable')]){
          sh "curl -X POST -v -u ${env.usernameVariable}:${env.passwordVariable} http://bitbucket.liatr.io/rest/api/1.0/projects -H \"Content-Type: application/json\" -d \'{\"key\": \"\'${PROJECT_KEY}\'\", \"name\": \"\'${params.pipeline_name}\'\", \"description\": \"\'${params.pipeline_name}\'- Built by automation\"}\'"
          sh "curl -X POST -v -u ${env.usernameVariable}:${env.passwordVariable} http://bitbucket.liatr.io/rest/api/1.0/projects/${PROJECT_KEY}/repos -H \"Content-Type: application/json\" -d \'{\"name\": \"pipeline-demo-application\", \"scmId\": \"git\", \"forkable\": true}\'"
          sh """git clone --depth 1 -b master https://github.com/liatrio/pipeline-demo-app.git pipeline-demo-app
              cd pipeline-demo-app
              rm -rf .git
              git init
              git add .
              git commit -m \"Initial Commit\"
              git remote add origin http://${env.usernameVariable}:${env.passwordVariable}@bitbucket.liatr.io/scm/${PROJECT_KEY}/pipeline-demo-application.git
              git push -u origin master
              """
          sh "curl -X POST -v -u ${env.usernameVariable}:${env.passwordVariable} http://bitbucket.liatr.io/rest/api/1.0/projects/${PROJECT_KEY}/repos -H \"Content-Type: application/json\" -d \'{\"name\": \"pipeline-dashboard\", \"scmId\": \"git\", \"forkable\": true}\'"
          sh """git clone --depth 1 -b master https://github.com/liatrio/pipeline-home pipeline-home
              cd pipeline-home
              rm -rf .git
              git init
              git add .
              git commit -m \"Initial Commit\"
              git remote add origin http://${env.usernameVariable}:${env.passwordVariable}@bitbucket.liatr.io/scm/${PROJECT_KEY}/pipeline-dashboard.git
              git push -u origin master
              """
        }
      }
    }
    stage('Create Jira Project') {
      steps {
        withCredentials([usernamePassword(credentialsId: 'BitbucketCreds', passwordVariable: 'passwordVariable', usernameVariable: 'usernameVariable')]){
          sh "curl -X POST -v -u ${env.usernameVariable}:${env.passwordVariable} http://jira.liatr.io/rest/api/2/project -H \"Content-Type: application/json\" -d \'{\"key\": \"\'${PROJECT_KEY}\'\", \"name\": \"\'${params.pipeline_name}\'\", \"projectTypeKey\": \"\'software\'\", \"lead\": \"\'${env.usernameVariable}\'\", \"description\": \"\'${params.pipeline_name}\'- Built by automation\"}\'"
        }
      }
    }
    stage('Create Slack Channel') {
      steps {
        withCredentials([string(credentialsId: 'liatrio-demo-slack', variable: 'token')]){
          sh "curl -X POST -H \'Authorization: Bearer ${env.token}\' -H \"Content-Type: application/json\" -d \'{\"name\": \"\'${params.pipeline_name}\'\", \"token\": \"\'${env.token}\'\"}\' https://liatrio-demo.slack.com/api/channels.create"
        }
      }
    }
    stage('Create Confluence space') {
      agent any
      steps {
        script {
          withCredentials([usernamePassword(credentialsId: 'BitbucketCreds', passwordVariable: 'passwordVariable', usernameVariable: 'usernameVariable')]){
            sh """
            curl -u ${env.usernameVariable}:${env.passwordVariable} -d '{ "key": "${PROJECT_KEY}", "name": "${params.pipeline_name}", "metadata": {} }' -H 'Content-Type: application/json' -X POST http://confluence.liatr.io/rest/api/space/
            """
          }
        }
      }
    }
  }
}
