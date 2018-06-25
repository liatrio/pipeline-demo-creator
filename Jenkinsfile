pipeline {
  agent any
  parameters {
    string(name: 'CONF_SPACE_KEY', defaultValue: 'EX', description: 'Key for confluence space.')
    string(name: 'CONF_SPACE_NAME', defaultValue: 'example_name', description: 'Name of confluence space to create.')
  }
  stages {
    stage('Create Confluence space') {
      agent any
      steps {
        script {
          withCredentials([usernamePassword(credentialsId: 'BitbucketCreds', passwordVariable: 'passwordVariable', usernameVariable: 'usernameVariable')]){
          sh """
          curl -u ${env.usernameVariable}:${env.passwordVariable} -d '{ "key": "${params.CONF_SPACE_KEY}", "name": "${params.CONF_SPACE_NAME}", "description": { "plain": { "value": "This is an example space", "representation": "plain" } }, "metadata": {} }' -H 'Content-Type: application/json' -X POST http://confluence.liatr.io/rest/api/space/
          """
        }
      }
    }
  }
}
