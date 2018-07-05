#!/usr/bin/env groovy
import groovy.json.JsonSlurperClassic
import groovy.json.JsonOutput
pipeline {
  agent any
  parameters {
    string(name: "pipeline_name", description: "What would you like to name the demo application?")
  }
  stages {
    stage('Create Bitbucket Project and Git Repos') {
      steps {
        script {
          PROJECT_NAME = params.pipeline_name.replaceAll("[^A-Za-z0-9\\- ]", "").replace(' ', '-').toLowerCase()
          PROJECT_KEY = PROJECT_NAME.substring(0,4).toUpperCase()
        }
        script {
          def bitbucketProjectPayload = [
            key: PROJECT_KEY,
            name: PROJECT_NAME,
            description: PROJECT_NAME + "-Built by automation"
          ]
          def bitbucketProjectResponse = httpRequest authentication: 'BitbucketCreds', consoleLogResponseBody: true, acceptType: 'APPLICATION_JSON', contentType: 'APPLICATION_JSON', httpMode: 'POST', requestBody: JsonOutput.toJson(bitbucketProjectPayload), url: "http://bitbucket.liatr.io/rest/api/1.0/projects/"
          def parsedResponse = new JsonSlurperClassic().parseText(bitbucketProjectResponse.content)
          //TODO: slack send the link with success
          println parsedResponse.links.self[0].href
        }
        script {
          def demoAppRepoPayload = [
            name: "pipeline-demo-application",
            scmId: "git",
            forkable: true
          ]
          def appCreationResponse = httpRequest authentication: 'BitbucketCreds', consoleLogResponseBody: true, acceptType: 'APPLICATION_JSON', contentType: 'APPLICATION_JSON', httpMode: 'POST', requestBody: JsonOutput.toJson(demoAppRepoPayload), url: "http://bitbucket.liatr.io/rest/api/1.0/projects/${PROJECT_KEY}/repos"
          //def parsedResponse = new JsonSlurper().parseText(appCreationResponse.content)
          //TODO: slack send the link with success
        }
        script {
          def dashboardRepoPayload = [
            name: "pipeline-home",
            scmId: "git",
            forkable: true
          ]
          def dashboardCreationResponse = httpRequest authentication: 'BitbucketCreds', consoleLogResponseBody: true, acceptType: 'APPLICATION_JSON', contentType: 'APPLICATION_JSON', httpMode: 'POST', requestBody: JsonOutput.toJson(dashboardRepoPayload), url: "http://bitbucket.liatr.io/rest/api/1.0/projects/${PROJECT_KEY}/repos"
          //def parsedResponse = new JsonSlurper().parseText(dashboardCreationResponse.content)
          //TODO: slack send the link with success
        }
      }
    }
    stage('Clone Demo Application and Dashboard') {
      steps {
        deleteDir()
        withCredentials([usernamePassword(credentialsId: 'BitbucketCreds', passwordVariable: 'passwordVariable', usernameVariable: 'usernameVariable')]) {
          sh """git clone --depth 1 -b master https://github.com/liatrio/pipeline-demo-app.git pipeline-demo-app
              cd pipeline-demo-app
              rm -rf .git
              git init
              sed -i -e 's/__APP_NAME__/${PROJECT_NAME}/g' Jenkinsfile
              sed -i -e 's/__PROJECT_KEY__/${PROJECT_KEY}/g' Jenkinsfile
              git add .
              git commit -m \"Initial Commit\"
              git remote add origin http://${env.usernameVariable}:${env.passwordVariable}@bitbucket.liatr.io/scm/${PROJECT_KEY}/pipeline-demo-application.git
              git push -u origin master
              """
          sh """git clone --depth 1 -b master https://github.com/liatrio/pipeline-home pipeline-home
              cd pipeline-home
              rm -rf .git
              git init
              sed -i -e 's/__APP_NAME__/${PROJECT_NAME}/g' Jenkinsfile
              sed -i -e 's/__PROJECT_NAME__/${PROJECT_NAME}/g' src/template/site.js
              sed -i -e 's/__PROJECT_KEY__/${PROJECT_KEY}/g' src/template/site.js
              sed -i -e 's/__APP_NAME__/${PROJECT_NAME}/g' src/template/site.js
              git add .
              git commit -m \"Initial Commit\"
              git remote add origin http://${env.usernameVariable}:${env.passwordVariable}@bitbucket.liatr.io/scm/${PROJECT_KEY}/pipeline-home.git
              git push -u origin master
              """
        }
      }
    }
    stage('Create Jira Project') {
      steps {
        script {
          def jiraProjectPayload = [
            key: PROJECT_KEY,
            name: PROJECT_NAME,
            projectTypeKey: "software",
            lead: "liatrio",
            description: PROJECT_NAME + " - Built by automation"
          ]
          def jiraProjectCreationResponse = httpRequest authentication: 'BitbucketCreds', consoleLogResponseBody: true, acceptType: 'APPLICATION_JSON', contentType: 'APPLICATION_JSON', httpMode: 'POST', requestBody: JsonOutput.toJson(jiraProjectPayload), url: "http://jira.liatr.io/rest/api/2/project"
          //TODO: slack send the link with success
        }
      }
    }
    stage('Create Slack Channel') {
      steps {
        script {
          withCredentials([string(credentialsId: 'liatrio-demo-slack', variable: 'token')]) {
          def slackPayload = [name: PIPELINE_NAME]
          def slackChannelCreationResponse = httpRequest customHeaders: [[name: 'Authorization', value: 'Bearer '+"${env.token}"]], consoleLogResponseBody: true, acceptType: 'APPLICATION_JSON', contentType: 'APPLICATION_JSON', httpMode: 'POST', requestBody: JsonOutput.toJson(slackPayload), url: "https://liatrio-demo.slack.com/api/channels.create"
          //TODO: slack send the link with success
          }
        }
      }
    }
    stage('Create Confluence space') {
      agent any
      steps {
        script {
          def confluenceSpacePayload = [
            key: PROJECT_KEY,
            name: PIPELINE_NAME
          ]
          def confluenceSpaceCreationResponse = httpRequest authentication: 'BitbucketCreds', consoleLogResponseBody: true, acceptType: 'APPLICATION_JSON', contentType: 'APPLICATION_JSON', httpMode: 'POST', requestBody: JsonOutput.toJson(confluenceSpacePayload), url: "http://confluence.liatr.io/rest/api/space/"
          //TODO: slack send the link with success
        }
      }
    }
    stage("Provisioning Dev Environment") {
      agent any
      steps {
        script {
          STAGE = env.STAGE_NAME
          DEV_IP = "dev.${PROJECT_NAME}.liatr.io"
        }
        withCredentials([sshUserPrivateKey(credentialsId: '71d94074-215d-4798-8430-40b98e223d8c', keyFileVariable: 'keyFileVariable', passphraseVariable: '', usernameVariable: 'usernameVariable')]) {
//          slackSend channel: env.SLACK_ROOM, message: "Provisioning dev environment"
          sh "export TF_VAR_key_file=${keyFileVariable} && export TF_WORKSPACE=${env.PROJECT_NAME} && export TF_VAR_app_name=${env.PROJECT_NAME}"
          sh "terraform init -input=false -no-color -backend-config='key=liatristorage/${env.PROJECT_NAME}/${env.PROJECT_NAME}-terraform.tfstate'"
          sh "terraform workspace new ${env.PROJECT_NAME} -no-color"
          sh "terraform plan -out=plan_${env.PROJECT_NAME} -input=false -no-color"
          sh "terraform apply -input=false plan_${env.PROJECT_NAME} -no-color"
        }
      }
    }
  }
}
