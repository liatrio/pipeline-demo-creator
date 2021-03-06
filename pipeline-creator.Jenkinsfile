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
          DEMO_SLACK_CHANNEL = ""
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
    stage('Create Slack Channel') {
      steps {
        script {
          withCredentials([string(credentialsId: 'liatrio-demo-slack', variable: 'token')]) {
          def slackPayload = [name: PIPELINE_NAME]
          def slackChannelCreationResponse = httpRequest customHeaders: [[name: 'Authorization', value: 'Bearer '+"${env.token}"]], consoleLogResponseBody: true, acceptType: 'APPLICATION_JSON', contentType: 'APPLICATION_JSON', httpMode: 'POST', requestBody: JsonOutput.toJson(slackPayload), url: "https://liatrio-demo.slack.com/api/channels.create"
          def parsedResponse = new JsonSlurperClassic().parseText(slackChannelCreationResponse.content)
          DEMO_SLACK_CHANNEL = parsedResponse.channel.id
          def slackChannelLink = "https://liatrio-demo.slack.com/messages/${DEMO_SLACK_CHANNEL}"
          slackSend baseUrl: SLACK_URL, channel: SLACK_CHANNEL, color: "A9ACB6", message: "Slack channel for ${PROJECT_NAME} created at ${slackChannelLink}", teamDomain: 'liatrio', failOnError: true
          }
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
              sed -i -e 's/__CHAT_ROOM__/${DEMO_SLACK_CHANNEL}/g' src/template/site.js
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
    stage('Create Jenkins Org Folder') {
      agent any
      steps {
        script {
            JENKINS_URL = "http://jenkins.liatr.io"
            def jenkinsCrumb = httpRequest validResponseCodes: '200,404', authentication: 'jenkins.liatr.io_creds', consoleLogResponseBody: true, contentType: 'APPLICATION_JSON', httpMode: 'GET', url: "${JENKINS_URL}/crumbIssuer/api/json"
            def customHeaders
            if (jenkinsCrumb.status == 200){
                def crumbJson = new JsonSlurperClassic().parseText(jenkinsCrumb.content)
                customHeaders = [[name: crumbJson.crumbRequestField, value: crumbJson.crumb]]
            } else {
                customHeaders = []
            }
            def createJenkinsFolder = httpRequest validResponseCodes: '201', authentication: 'jenkins.liatr.io_creds', customHeaders: customHeaders, consoleLogResponseBody: true, contentType: 'APPLICATION_JSON', httpMode: 'POST', url: "${JENKINS_URL}/job/demo-pipelines/job/demo-pipeline-manager/buildWithParameters?pipeline_name=${PROJECT_NAME}"
        }
        slackSend baseUrl: SLACK_URL, channel: SLACK_CHANNEL, color: "A9ACB6", message: "Jenkins Organizational Folder created for the ${PROJECT_NAME} app pipeline at ${JENKINS_URL}/job/demo-pipelines/job/${PROJECT_NAME}/", teamDomain: 'liatrio', failOnError: true
      }
    }
    stage("Provision Dev Environment") {
      agent any
      environment {
        TF_IN_AUTOMATION = "true"
      }
      steps {
        script {
          STAGE = env.STAGE_NAME
          DEV_IP = "dev.${PROJECT_NAME}.liatr.io"
        }
        slackSend baseUrl: SLACK_URL, channel: SLACK_CHANNEL, color: "A9ACB6", message: "Starting creation of the Dev environment for the *${PROJECT_NAME}* pipeline. This process may take 3-4 min.", teamDomain: 'liatrio', failOnError: true
        wrap([$class: 'BuildUser']) {
          withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'AWS-SVC-Jenkins-non-prod-dev' ]]) {
            withCredentials([sshUserPrivateKey(credentialsId: '71d94074-215d-4798-8430-40b98e223d8c', keyFileVariable: 'KEY_FILE', passphraseVariable: '', usernameVariable: 'usernameVariable')]) {
              sh """ 
              terraform init -input=false -no-color -force-copy -reconfigure
              terraform workspace select ${PROJECT_NAME} -no-color || terraform workspace new ${PROJECT_NAME} -no-color
              terraform plan -out=plan_${PROJECT_NAME}_devenv -input=false -no-color -var key_file=${KEY_FILE} -var app_name=${PROJECT_NAME} -var 'jenkins_user=${BUILD_USER}'
              terraform apply -input=false plan_${PROJECT_NAME}_devenv -no-color
              """
            }
          }
        }
        slackSend baseUrl: SLACK_URL, channel: SLACK_CHANNEL, color: "A9ACB6", message: "Deployment environment for ${PROJECT_NAME} created at http://dev.${PROJECT_NAME}.liatr.io", teamDomain: 'liatrio', failOnError: true
      }
   }
   stage('Create Dashboard Server') {
    agent any
      environment {
        TF_IN_AUTOMATION = "true"
      }
      steps {
        wrap([$class: 'BuildUser']) {
          withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'AWS-SVC-Jenkins-non-prod-dev' ]]) {
            slackSend baseUrl: SLACK_URL, channel: SLACK_CHANNEL, color: "A9ACB6", message: "Creating dashboard infrastructure. This can take ~ 1 minute", teamDomain: 'liatrio', failOnError: true
            git 'https://github.com/liatrio/pipeline-home.git'
            sh """
            terraform init -input=false -no-color -force-copy -reconfigure
            terraform workspace select ${PROJECT_NAME} -no-color || terraform workspace new ${PROJECT_NAME} -no-color
            terraform plan -out=plan_${PROJECT_NAME}_dashboard -input=false -no-color -var bucket_name=${PROJECT_NAME}.liatr.io -var app_name=${PROJECT_NAME} -var 'jenkins_user=${BUILD_USER}'
            terraform apply -input=false plan_${PROJECT_NAME}_dashboard -no-color
            """
          }
        }
        slackSend baseUrl: SLACK_URL, channel: SLACK_CHANNEL, color: "A9ACB6", message: "Dashboard for ${PROJECT_NAME} created at http://${PROJECT_NAME}.liatr.io", teamDomain: 'liatrio', failOnError: true
      }
    }
    stage('Scan for New Repos to Build, Deploy') {
      agent any
      steps {
        script {
            JENKINS_URL = "http://jenkins.liatr.io"
            def jenkinsCrumb = httpRequest validResponseCodes: '200,404', authentication: 'jenkins.liatr.io_creds', consoleLogResponseBody: true, contentType: 'APPLICATION_JSON', httpMode: 'GET', url: "${JENKINS_URL}/crumbIssuer/api/json"
            def customHeaders
            if (jenkinsCrumb.status == 200){
                def crumbJson = new JsonSlurperClassic().parseText(jenkinsCrumb.content)
                customHeaders = [[name: crumbJson.crumbRequestField, value: crumbJson.crumb]]
            } else {
                customHeaders = []
            }
            def scanJenkinsFolder = httpRequest validResponseCodes: '302', authentication: 'jenkins.liatr.io_creds', customHeaders: customHeaders, consoleLogResponseBody: true, contentType: 'APPLICATION_JSON', httpMode: 'POST', url: "${JENKINS_URL}/job/demo-pipelines/job/${PROJECT_NAME}/build?delay=0"
        }
        slackSend baseUrl: SLACK_URL, channel: SLACK_CHANNEL, color: "A9ACB6", message: "Jenkins now scanning for new repos to build and deploy at ${JENKINS_URL}/job/demo-pipelines/job/${PROJECT_NAME}/", teamDomain: 'liatrio', failOnError: true
      }
    }
  }
  post {
    success {
      slackSend baseUrl: SLACK_URL, channel: SLACK_CHANNEL, color: "good", message: ":white_check_mark: Pipeline for the *${PROJECT_NAME}* app successfully created :white_check_mark:", teamDomain: 'liatrio', failOnError: true
    }
    failure {
      slackSend baseUrl: SLACK_URL, channel: SLACK_CHANNEL, color: "danger", message: "Pipeline creator failed. See details here: ${env.BUILD_URL}", teamDomain: 'liatrio', failOnError: true
    }
  }
}
