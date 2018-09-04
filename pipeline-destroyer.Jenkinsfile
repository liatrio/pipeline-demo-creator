#!/usr/bin/env groovy
import groovy.json.JsonSlurperClassic
import groovy.json.JsonOutput
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
          SLACK_CHANNEL = "#pipeline-notify"
          SLACK_URL = "https://liatrio.slack.com/services/hooks/jenkins-ci/"
        }
        slackSend baseUrl: SLACK_URL, channel: SLACK_CHANNEL, color: "A9ACB6", message: "Beginning deletion of the *${PROJECT_NAME}* app pipeline", teamDomain: 'liatrio', failOnError: true
        script {
          def deletePipelineHome = httpRequest validResponseCodes: '200, 204, 404', authentication: 'BitbucketCreds', consoleLogResponseBody: true, contentType: 'APPLICATION_JSON', httpMode: 'DELETE', url: "http://bitbucket.liatr.io/rest/api/1.0/projects/${PROJECT_KEY}/repos/pipeline-home"
          def deleteDemoApp = httpRequest validResponseCodes: '200, 204, 404', authentication: 'BitbucketCreds', consoleLogResponseBody: true, contentType: 'APPLICATION_JSON', httpMode: 'DELETE', url: "http://bitbucket.liatr.io/rest/api/1.0/projects/${PROJECT_KEY}/repos/pipeline-demo-application"
          def deleteProject = httpRequest validResponseCodes: '200, 204, 404', authentication: 'BitbucketCreds', consoleLogResponseBody: true, contentType: 'APPLICATION_JSON', httpMode: 'DELETE', url: "http://bitbucket.liatr.io/rest/api/1.0/projects/${PROJECT_KEY}"
          if (deleteProject.status == 404) {
            slackSend baseUrl: SLACK_URL, channel: SLACK_CHANNEL, color: "warning", message: "Bitbucket project for the ${PROJECT_NAME} app pipeline not found", teamDomain: 'liatrio', failOnError: true
          } else {
            slackSend baseUrl: SLACK_URL, channel: SLACK_CHANNEL, color: "good", message: "Bitbucket project and repositories deleted for the ${PROJECT_NAME} app pipeline", teamDomain: 'liatrio', failOnError: true
          }
        }
      }
    }
    stage('Delete Jira Project') {
      steps {
        script {
          def deleteJiraPoject = httpRequest validResponseCodes: '200, 204, 404', authentication: 'BitbucketCreds', consoleLogResponseBody: true, contentType: 'APPLICATION_JSON', httpMode: 'DELETE', url: "http://jira.liatr.io/rest/api/2/project/${PROJECT_KEY}"
          if (deleteJiraPoject.status == 404) {
            slackSend baseUrl: SLACK_URL, channel: SLACK_CHANNEL, color: "warning", message: "Jira project for the ${PROJECT_NAME} app pipeline not found", teamDomain: 'liatrio', failOnError: true
          } else {
            slackSend baseUrl: SLACK_URL, channel: SLACK_CHANNEL, color: "good", message: "Jira project deleted for the ${PROJECT_NAME} app pipeline", teamDomain: 'liatrio', failOnError: true
          }
        }
      }
    }
    stage('Delete Confluence space') {
      agent any
      steps {
        script {
          def deleteConfluenceSpace = httpRequest validResponseCodes: '200, 204, 404', authentication: 'BitbucketCreds', consoleLogResponseBody: true, contentType: 'APPLICATION_JSON', httpMode: 'DELETE', url: "http://confluence.liatr.io/rest/api/space/${PROJECT_KEY}"
          if (deleteConfluenceSpace.status == 404) {
            slackSend baseUrl: SLACK_URL, channel: SLACK_CHANNEL, color: "warning", message: "Confluence space for the ${PROJECT_NAME} app pipeline not found", teamDomain: 'liatrio', failOnError: true
          } else {
            slackSend baseUrl: SLACK_URL, channel: SLACK_CHANNEL, color: "good", message: "Confluence space deleted for the ${PROJECT_NAME} app pipeline", teamDomain: 'liatrio', failOnError: true
          }
        }
      }
    }
    stage('Delete Jenkins Folder') {
      agent any
      steps {
        script {
          JENKINS_URL = "http://jenkins.liatr.io"
          def jenkinsCrumb = httpRequest validResponseCodes: '200,404', authentication: 'jenkins.liatr.io_creds', consoleLogResponseBody: true, contentType: 'APPLICATION_JSON', httpMode: 'GET', url: "${JENKINS_URL}/crumbIssuer/api/json"
          def customHeaders
          if (jenkinsCrumb.status == 200) {
            def crumbJson = new JsonSlurperClassic().parseText(jenkinsCrumb.content)
            customHeaders = [[name: crumbJson.crumbRequestField, value: crumbJson.crumb]]
          } else {
            customHeaders = []
          }
          def deleteJenkinsFolder = httpRequest validResponseCodes: '200,302,404', authentication: 'jenkins.liatr.io_creds', customHeaders: customHeaders, consoleLogResponseBody: true, contentType: 'APPLICATION_JSON', httpMode: 'POST', url: "${JENKINS_URL}/job/demo-pipelines/job/${PROJECT_NAME}/doDelete"
          if (deleteJenkinsFolder.status == 404) {
            slackSend baseUrl: SLACK_URL, channel: SLACK_CHANNEL, color: "warning", message: "Jenkins folder for the ${PROJECT_NAME} app pipeline not found", teamDomain: 'liatrio', failOnError: true
          } else {
            slackSend baseUrl: SLACK_URL, channel: SLACK_CHANNEL, color: "good", message: "Jenkins folder deleted for the ${PROJECT_NAME} app pipeline", teamDomain: 'liatrio', failOnError: true
          }
        }
      }
    }
    stage('Delete Slack Channel') {
      steps {
        script {
          def channelFound = false
          withCredentials([string(credentialsId: 'liatrio-demo-slack', variable: 'token')]) {
            def channelData = httpRequest customHeaders: [[name: 'Authorization', value: 'Bearer '+"${env.token}"]], acceptType: 'APPLICATION_JSON', contentType: 'APPLICATION_JSON', httpMode: 'GET', url: "https://liatrio-demo.slack.com/api/channels.list"
            def channelJson = new JsonSlurperClassic().parseText(channelData.content)
            for ( prop in channelJson.channels ) {
              if ( prop.name == PROJECT_NAME ) {
                println "Deleting ChannelID: ${prop.id}"
                def deleteSlackChannel = httpRequest customHeaders: [[name: 'Authorization', value: 'Bearer ' + "${env.token}"]], consoleLogResponseBody: true, contentType: 'APPLICATION_JSON', httpMode: 'POST', url: "https://liatrio-demo.slack.com/api/channels.delete?channel=${prop.id}"
                channelFound = true
                break
              }
            }
          }
          if (channelFound == false) {
            slackSend baseUrl: SLACK_URL, channel: SLACK_CHANNEL, color: "warning", message: "Slack channel for the ${PROJECT_NAME} app pipeline not found", teamDomain: 'liatrio', failOnError: true
          } else {
            slackSend baseUrl: SLACK_URL, channel: SLACK_CHANNEL, color: "good", message: "Slack channel deleted for the ${PROJECT_NAME} app pipeline", teamDomain: 'liatrio', failOnError: true
          }
        }
      }
    }
    stage('Delete Dev Environment') {
      steps {
        slackSend baseUrl: SLACK_URL, channel: SLACK_CHANNEL, color: "A9ACB6", message: "Tearing down the Dev deployment environment at http://dev.${PROJECT_NAME}.liatr.io. This process usually takes 2-3 min.", teamDomain: 'liatrio', failOnError: true
        withCredentials([sshUserPrivateKey(credentialsId: '71d94074-215d-4798-8430-40b98e223d8c', keyFileVariable: 'KEY_FILE', passphraseVariable: '', usernameVariable: 'usernameVariable')]) {
          sh """export TF_VAR_app_name=${PROJECT_NAME} && export TF_VAR_key_file=${KEY_FILE}
          terraform init -input=false -no-color -reconfigure -backend-config='key=liatristorage/${PROJECT_NAME}/${PROJECT_NAME}-terraform.tfstate'
          terraform workspace select ${PROJECT_NAME} -no-color || terraform workspace new ${PROJECT_NAME} -no-color
          export TF_VAR_app_name=${PROJECT_NAME}
          terraform destroy -auto-approve -no-color
          """
        }
        slackSend baseUrl: SLACK_URL, channel: SLACK_CHANNEL, color: "A9ACB6", message: "Dev deployment environment for ${PROJECT_NAME} has been destroyed", teamDomain: 'liatrio', failOnError: true
      }
    }
    stage('Destroy Dashboard Server') {
        agent any
        environment {
            TF_VAR_bucket_name = "${PROJECT_NAME}.liatr.io"
        }
        steps {
            slackSend baseUrl: SLACK_URL, channel: SLACK_CHANNEL, color: "A9ACB6", message: "Destroying dashboard infrastructure. This can take ~ 1 minute", teamDomain: 'liatrio', failOnError: true
            withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'Jenkins AWS Creds' ]]) {
                git 'https://github.com/liatrio/pipeline-home.git'
                sh "terraform init -reconfigure -input=false -no-color -backend-config='key=liatristorage/${PROJECT_NAME}/dashboard-terraform.tfstate'"
                sh 'terraform destroy -auto-approve -no-color'
            }
            slackSend baseUrl: SLACK_URL, channel: SLACK_CHANNEL, color: "A9ACB6", message: "Dashboard for ${PROJECT_NAME} destroyed", teamDomain: 'liatrio', failOnError: true
        }
    }
  }
  post {
      success {
          slackSend baseUrl: SLACK_URL, channel: SLACK_CHANNEL, color: "good", message: ":negative_squared_cross_mark: The *${PROJECT_NAME}* app pipeline has been removed :negative_squared_cross_mark:", teamDomain: 'liatrio', failOnError: true
      }
      failure {
          slackSend baseUrl: SLACK_URL, channel: SLACK_CHANNEL, color: "#ff0000", message: "Pipeline destroyer failed at stage ${STAGE}", teamDomain: 'liatrio', failOnError: true
      }
  }
}
