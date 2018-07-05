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
          SLACK_CHANNEL = "#pipeline-notify"
          SLACK_URL = "https://liatrio.slack.com/services/hooks/jenkins-ci/"
        }
        slackSend baseUrl: SLACK_URL, channel: SLACK_CHANNEL, color: "A9ACB6", message: "Pipeline-Creator started for the *${PROJECT_NAME}* app at ${env.BUILD_URL}", teamDomain: 'liatrio', failOnError: true
        script {
          def bitbucketProjectPayload = [
            key: PROJECT_KEY,
            name: PROJECT_NAME,
            description: PROJECT_NAME + "-Built by automation"
          ]
          def bitbucketProjectResponse = httpRequest validResponseCodes: '409,201', authentication: 'BitbucketCreds', consoleLogResponseBody: true, acceptType: 'APPLICATION_JSON', contentType: 'APPLICATION_JSON', httpMode: 'POST', requestBody: JsonOutput.toJson(bitbucketProjectPayload), url: "http://bitbucket.liatr.io/rest/api/1.0/projects/"
          if (bitbucketProjectResponse.getStatus() == 409) {
            slackSend baseUrl: SLACK_URL, channel: SLACK_CHANNEL, color: "B80000", message: ":x: Pipeline for *${PROJECT_NAME}* already exists. Aborting. :x:", teamDomain: 'liatrio', failOnError: true
            currentBuild.result = 'ABORTED'
            error('Stopping early. Pipeline exists.')
          }
          def parsedResponse = new JsonSlurperClassic().parseText(bitbucketProjectResponse.content)
          BITBUCKET_PROJECT_LINK = parsedResponse.links.self[0].href
          slackSend baseUrl: SLACK_URL, channel: SLACK_CHANNEL, color: "A9ACB6", message: "Bitbucket project for app ${PROJECT_NAME} created at ${BITBUCKET_PROJECT_LINK}", teamDomain: 'liatrio', failOnError: true
        }
        script {
          def demoAppRepoPayload = [
            name: "pipeline-demo-application",
            scmId: "git",
            forkable: true
          ]
          def appCreationResponse = httpRequest authentication: 'BitbucketCreds', consoleLogResponseBody: true, acceptType: 'APPLICATION_JSON', contentType: 'APPLICATION_JSON', httpMode: 'POST', requestBody: JsonOutput.toJson(demoAppRepoPayload), url: "http://bitbucket.liatr.io/rest/api/1.0/projects/${PROJECT_KEY}/repos"
          slackSend baseUrl: SLACK_URL, channel: SLACK_CHANNEL, color: "A9ACB6", message: "Demo App Repo for ${PROJECT_NAME} created in Bitbucket at ${BITBUCKET_PROJECT_LINK}/repos/pipeline-demo-application/browse", teamDomain: 'liatrio', failOnError: true
        }
        script {
          def dashboardRepoPayload = [
            name: "pipeline-home",
            scmId: "git",
            forkable: true
          ]
          def dashboardCreationResponse = httpRequest authentication: 'BitbucketCreds', consoleLogResponseBody: true, acceptType: 'APPLICATION_JSON', contentType: 'APPLICATION_JSON', httpMode: 'POST', requestBody: JsonOutput.toJson(dashboardRepoPayload), url: "http://bitbucket.liatr.io/rest/api/1.0/projects/${PROJECT_KEY}/repos"
          slackSend baseUrl: SLACK_URL, channel: SLACK_CHANNEL, color: "A9ACB6", message: "Dashboard Repo for ${PROJECT_NAME} created in Bitbucket at ${BITBUCKET_PROJECT_LINK}/repos/pipeline-home/browse", teamDomain: 'liatrio', failOnError: true
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
        slackSend baseUrl: SLACK_URL, channel: SLACK_CHANNEL, color: "A9ACB6", message: "Demo App and Dashboard code replicated for ${PROJECT_NAME}", teamDomain: 'liatrio', failOnError: true
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
          slackSend baseUrl: SLACK_URL, channel: SLACK_CHANNEL, color: "A9ACB6", message: "Jira project for app ${PROJECT_NAME} created at http://jira.liatr.io/projects/${PROJECT_KEY}", teamDomain: 'liatrio', failOnError: true
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
          slackSend baseUrl: SLACK_URL, channel: SLACK_CHANNEL, color: "A9ACB6", message: "Confluence space for app ${PROJECT_NAME} created at http://confluence.liatr.io/display/${PROJECT_KEY}", teamDomain: 'liatrio', failOnError: true
        }
      }
    }
    stage('Create Slack Channel') {
      steps {
        script {
          withCredentials([string(credentialsId: 'liatrio-demo-slack', variable: 'token')]) {
          def slackPayload = [name: PIPELINE_NAME]
          def slackChannelCreationResponse = httpRequest customHeaders: [[name: 'Authorization', value: 'Bearer '+"${env.token}"]], consoleLogResponseBody: true, acceptType: 'APPLICATION_JSON', contentType: 'APPLICATION_JSON', httpMode: 'POST', requestBody: JsonOutput.toJson(slackPayload), url: "https://liatrio-demo.slack.com/api/channels.create"
          def parsedResponse = new JsonSlurperClassic().parseText(slackChannelCreationResponse.content)
          def slackChannelLink = "https://liatrio-demo.slack.com/messages/"+parsedResponse.channel.id
          slackSend baseUrl: SLACK_URL, channel: SLACK_CHANNEL, color: "A9ACB6", message: "Slack channel for ${PROJECT_NAME} created at ${slackChannelLink}", teamDomain: 'liatrio', failOnError: true
          slackSend baseUrl: SLACK_URL, channel: SLACK_CHANNEL, color: "good", message: ":white_check_mark: Pipeline for the *${PROJECT_NAME}* app successfully created :white_check_mark:", teamDomain: 'liatrio', failOnError: true
          }
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
        withCredentials([sshUserPrivateKey(credentialsId: '71d94074-215d-4798-8430-40b98e223d8c', keyFileVariable: 'KEY_FILE', passphraseVariable: '', usernameVariable: 'usernameVariable')]) {
//          slackSend channel: env.SLACK_ROOM, message: "Provisioning dev environment"
          sh """export TF_VAR_app_name=${PROJECT_NAME} && export TF_VAR_key_file=${KEY_FILE}
          terraform init -input=false -no-color -reconfigure -backend-config='key=liatristorage/${PROJECT_NAME}/${PROJECT_NAME}-terraform.tfstate'
          terraform workspace select ${PROJECT_NAME} -no-color || terraform workspace new ${PROJECT_NAME} -no-color
          export TF_VAR_app_name=${PROJECT_NAME} && terraform plan -out=plan_${PROJECT_NAME} -input=false -no-color
          terraform apply -input=false plan_${PROJECT_NAME} -no-color
          """
        }
        slackSend baseUrl: SLACK_URL, channel: SLACK_CHANNEL, color: "A9ACB6", message: "Deployment environment for ${PROJECT_NAME} created at http://dev.${PROJECT_NAME}.liatr.io", teamDomain: 'liatrio', failOnError: true
      }
    }
  }
}
