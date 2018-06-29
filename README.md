# Pipeline Demo Creator / Destroyer
## Purpose
This project contains automation that will be used to connect tool infrastructure and applications used within a custom application delivery pipeline
#### Pipeline Creator Stages
1. Create a demo-specific Project in Bitbucket
2. Create demo-specific repositories in the new Bitbucket Project
  * `pipeline-demo-app` - Demo application with it's own delivery Pipeline
    * To be cloned from [here](https://github.com/liatrio/pipeline-demo-app), replacing parameterized values
  * `pipeline-home` - Pipeline dashboard application
    * To be cloned from [here](https://github.com/liatrio/pipeline-home), replacing parameterized values
3. Create a demo-specific Jira project with a new project key
4. Create a demo-specific Slack channel with the project name specified
5. Create a demo-specific Confluence space with a new project key

#### Pipeline Destroyer Stages
1. Delete the demo Bitbucket repositories `pipeline-demo-app` and `pipeline-home`
2. Delete the demo Bitbucket Project
3. Delete the Jira Project
4. Delete the Confluence space


## Usage
The files `pipeline-creator.Jenkinsfile` and `pipeline-destroyer.Jenkinsfile` are each built to be configured as Multibranch Pipelines within Jenkins
*  The creator/destroyer jobs are configured by pointing to either specific `*.Jenkinsfile` and running the 'build'
  *  There is no other configuration required
*  The jobs take the parameter `pipeline_name` that is used to determine the pipeline name to either create or destroy
  *  Note: The first run of an unparameterized job will fail while the automatic pipeline configuration is built

#### Pipeline Plugins and Libraries
This project uses commonly referenced Groovy JSON libraries:
* `groovy.json.JsonSlurper`
* `groovy.json.JsonOutput`

This project also uses the [Http Request Jenkins plugin](https://github.com/jenkinsci/http-request-plugin) to make REST API calls to our pipeline applications for both creating and deleting resources. The [Http Request plugin](https://github.com/jenkinsci/http-request-plugin) allows us to include credentials easily for auth and handle REST API (JSON) responses easily by implementing the aforementioned Groovy libraries' functions.
