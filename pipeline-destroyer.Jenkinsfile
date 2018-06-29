#!/usr/bin/env groovy
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
        script {
          def deletePipelineHome = httpRequest authentication: 'BitbucketCreds', consoleLogResponseBody: true, contentType: 'APPLICATION_JSON', httpMode: 'DELETE', url: "http://bitbucket.liatr.io/rest/api/1.0/projects/${PROJECT_KEY}/repos/pipeline-home"
          def deleteDemoApp = httpRequest authentication: 'BitbucketCreds', consoleLogResponseBody: true, contentType: 'APPLICATION_JSON', httpMode: 'DELETE', url: "http://bitbucket.liatr.io/rest/api/1.0/projects/${PROJECT_KEY}/repos/pipeline-demo-application"
          def deleteProject = httpRequest authentication: 'BitbucketCreds', consoleLogResponseBody: true, contentType: 'APPLICATION_JSON', httpMode: 'DELETE', url: "http://bitbucket.liatr.io/rest/api/1.0/projects/${PROJECT_KEY}"
        }
      }
    }
    stage('Delete Jira Project') {
      steps {
        script {
          def deleteJiraPoject = httpRequest authentication: 'BitbucketCreds', consoleLogResponseBody: true, contentType: 'APPLICATION_JSON', httpMode: 'DELETE', url: "http://jira.liatr.io/rest/api/2/project/${PROJECT_KEY}"
        }
      }
    }
    // Deleting slack channel with the bot auth scope wasn't working
    stage('Delete Confluence space') {
      agent any
      steps {
        script {
          def deleteConfluenceSpace = httpRequest authentication: 'BitbucketCreds', consoleLogResponseBody: true, contentType: 'APPLICATION_JSON', httpMode: 'DELETE', url: "http://confluence.liatr.io/rest/api/space/${PROJECT_KEY}"
        }
      }
    }
  }
}
