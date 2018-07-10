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
          def deletePipelineHome = httpRequest authentication: 'BitbucketCreds', consoleLogResponseBody: true, contentType: 'APPLICATION_JSON', httpMode: 'DELETE', url: "http://bitbucket.liatr.io/rest/api/1.0/projects/${PROJECT_KEY}/repos/pipeline-home"
          def deleteDemoApp = httpRequest authentication: 'BitbucketCreds', consoleLogResponseBody: true, contentType: 'APPLICATION_JSON', httpMode: 'DELETE', url: "http://bitbucket.liatr.io/rest/api/1.0/projects/${PROJECT_KEY}/repos/pipeline-demo-application"
          def deleteProject = httpRequest authentication: 'BitbucketCreds', consoleLogResponseBody: true, contentType: 'APPLICATION_JSON', httpMode: 'DELETE', url: "http://bitbucket.liatr.io/rest/api/1.0/projects/${PROJECT_KEY}"
        }
        slackSend baseUrl: SLACK_URL, channel: SLACK_CHANNEL, color: "A9ACB6", message: "Bitbucket project and repositories deleted for the ${PROJECT_NAME} app pipeline", teamDomain: 'liatrio', failOnError: true
      }
    }
    stage('Delete Jira Project') {
      steps {
        script {
          def deleteJiraPoject = httpRequest authentication: 'BitbucketCreds', consoleLogResponseBody: true, contentType: 'APPLICATION_JSON', httpMode: 'DELETE', url: "http://jira.liatr.io/rest/api/2/project/${PROJECT_KEY}"
        }
        slackSend baseUrl: SLACK_URL, channel: SLACK_CHANNEL, color: "A9ACB6", message: "Jira project deleted for the ${PROJECT_NAME} app pipeline", teamDomain: 'liatrio', failOnError: true
      }
    }
    stage('Delete Confluence space') {
      agent any
      steps {
        script {
          def deleteConfluenceSpace = httpRequest authentication: 'BitbucketCreds', consoleLogResponseBody: true, contentType: 'APPLICATION_JSON', httpMode: 'DELETE', url: "http://confluence.liatr.io/rest/api/space/${PROJECT_KEY}"
        }
        slackSend baseUrl: SLACK_URL, channel: SLACK_CHANNEL, color: "A9ACB6", message: "Confluence space deleted for the ${PROJECT_NAME} app pipeline", teamDomain: 'liatrio', failOnError: true
      }
    }
    stage('Delete Jenkins Folder') {
      agent any
      steps {
        script {
            JENKINS_URL = "http://jenkins.liatr.io"
            def jenkinsCrumb = httpRequest validResponseCodes: '200,404', authentication: 'jenkins.liatr.io_creds', consoleLogResponseBody: true, contentType: 'APPLICATION_JSON', httpMode: 'GET', url: "${JENKINS_URL}/crumbIssuer/api/json"
            def crumbJson
            if (jenkinsCrumb.status == 200){
                crumbJson = new JsonSlurperClassic().parseText(jenkinsCrumb.content)
            } else {
                crumbJson = new JsonSlurperClassic().parseText(JsonOutput.toJson([crumbRequestField: "crumb", crumb: "blank"]))
            }
            def deleteJenkinsFolder = httpRequest authentication: 'jenkins.liatr.io_creds', customHeaders: [[name: crumbJson.crumbRequestField, value: crumbJson.crumb]], consoleLogResponseBody: true, contentType: 'APPLICATION_JSON', httpMode: 'POST', url: "${JENKINS_URL}/job/demo-pipelines/job/${PROJECT_NAME}/doDelete"
        }
        slackSend baseUrl: SLACK_URL, channel: SLACK_CHANNEL, color: "A9ACB6", message: "Jenkins folder deleted for the ${PROJECT_NAME} app pipeline", teamDomain: 'liatrio', failOnError: true
      }
    }
    stage('Delete Slack Channel') {
      steps {
        script {
          withCredentials([string(credentialsId: 'liatrio-demo-slack', variable: 'token')]) {
            def channelData = httpRequest customHeaders: [[name: 'Authorization', value: 'Bearer '+"${env.token}"]], acceptType: 'APPLICATION_JSON', contentType: 'APPLICATION_JSON', httpMode: 'GET', url: "https://liatrio-demo.slack.com/api/channels.list"
            def channelJson = new JsonSlurperClassic().parseText(channelData.content)
            for ( prop in channelJson.channels ) {
              if ( prop.name == PROJECT_NAME ) {
                println "Deleting ChannelID: ${prop.id}"
                def deleteSlackChannel = httpRequest customHeaders: [[name: 'Authorization', value: 'Bearer '+"${env.token}"]], consoleLogResponseBody: true, contentType: 'APPLICATION_JSON', httpMode: 'POST', url: "https://liatrio-demo.slack.com/api/channels.delete?channel=${prop.id}"
                break
              }
            }
          }
        }
        slackSend baseUrl: SLACK_URL, channel: SLACK_CHANNEL, color: "A9ACB6", message: "Slack channel deleted for the ${PROJECT_NAME} app pipeline", teamDomain: 'liatrio', failOnError: true
        slackSend baseUrl: SLACK_URL, channel: SLACK_CHANNEL, color: "good", message: ":negative_squared_cross_mark: The *${PROJECT_NAME}* app pipeline has been removed :negative_squared_cross_mark:", teamDomain: 'liatrio', failOnError: true
      }
    }
  }
}
