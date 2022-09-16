#!/usr/bin/env groovy

void changeBuildInfo(Map mapArgs) {
    // Argument check first.
    if (null == mapArgs) {
        throw new Exception("Null mapArgs")
    }
    if (!mapArgs.containsKey("currentBuild")) {
        throw new Exception("Missing currentBuild. args: " + mapArgs)
    }
    if (!mapArgs.containsKey("scmVersion")) {
        throw new Exception("Missing scmVersion. args: " + mapArgs)
    }
    
    // Using default args.
    def defaultMapArgs = [:]
    Map mergedMap = defaultMapArgs << mapArgs
    
    // Change the build display.
    changeBuildDisplay(mergedMap)
}

void changeBuildDisplay(Map mapArgs) {
    def currentBuild = mapArgs.currentBuild
    def scmVersion = mapArgs.scmVersion
    
    def user = null
    
    if (mapArgs.containsKey("specificParams")) {
        def specificParams = mapArgs.specificParams
        if (null != specificParams) {
            if (specificParams.containsKey("displayUser")) {
                user = specificParams.displayUser
            }
        }
    }
    
    if (null == user) {
        wrap([$class: 'BuildUser']) {
            // Shows the user id.
            if (null != env.BUILD_USER_ID) {
                user = "${env.BUILD_USER_ID}"
            } else {
                // Most likely a scheduled trigger.
                user = "JenkinsScheduler"
            }
        }
    }

    currentBuild.displayName += "-" + user
    currentBuild.displayName += "-${scmVersion}"
}

	
	// Args.
	String scmUrl = env.scm_ur

    // Same pipeline as before, but with job parameters.
    pipeline {
        agent any
        options {
            // See https://jenkins.io/doc/book/pipeline/syntax/#options .

            skipStagesAfterUnstable()

            // Avoid the 'Declarative: Checkout SCM' stage.
            skipDefaultCheckout true

            // Persist artifacts and console output for the specific number of recent Pipeline runs.
            // daysToKeepStr: if not empty, build records are only kept up to this number of days
            // numToKeepStr: if not empty, only up to this number of build records are kept
            // artifactDaysToKeepStr: if not empty, artifacts from builds older than this number of days will be deleted, but the logs, history, reports, etc for the build will be kept
            // artifactNumToKeepStr: if not empty, only up to this number of builds have their artifacts retained
            buildDiscarder(logRotator(artifactDaysToKeepStr: '3', artifactNumToKeepStr: '', daysToKeepStr: '30', numToKeepStr: '60'))
        }
        // See https://jenkins.io/doc/book/pipeline/syntax/#parameters
        parameters {
            gitParameter(
                branch: '',
                branchFilter: 'origin/(.*)',
                defaultValue: 'main',
                description: 'Reference, which is a branch or a tag.',
                name: 'GIT_REF',
                quickFilterEnabled: true,
                selectedValue: 'DEFAULT',
                sortMode: 'DESCENDING_SMART',
                tagFilter: '*',
                type: 'PT_BRANCH_TAG',
            )
        }
    
        stages {
            stage('Init') {
                steps {
                    // Clean up workspace.
                    deleteDir()
                    
                    // Show environment information.
                    sh """
                        printenv
                        ls -al
                        echo -n "pwd: "
                        pwd
                    """
                }
            }
    
            stage('Scm on agent') {
                steps {
                    script {
                        checkout scm
                        jobParams = params
                        
                        // Change build information (display, description, etc.).
                        changeBuildInfo(
                            currentBuild: currentBuild,
                            scmVersion: jobParams.GIT_REF,
                        )
                    }
                }
            }
            stage ('Build') {
                steps {
                    script {
                        dockerImage = docker.build("${registryPrefix}cnes-lisa-globalfit1-idasoft:dev")
                    }
                }
            }
            stage ('Deploy') {
                steps {
                    script {
                        String credentialsId = "lisa_dockerhub"
                        String url= ""
                        docker.withRegistry(url, credentialsId) {
                            dockerImage.push()
                        }
                    }
                }
            }
        }
        post {
            success {
                script {
                    sh """
                        id
                        pwd
                    """
                }
            }
        }
    }


