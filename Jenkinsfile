pipeline {
    agent any

    environment {
        GITHUB_REPO = 'https://github.com/staillansag/HelloWorld.git'
        OPENSHIFT_PROJECT = 'staillansag-dev' 
        BUILD_CONFIG_NAME = 'msr-hello-world-build' 
        IMAGESTREAM_NAME = 'msr-hello-world'
    }

    stages {
        stage('Checkout') {
            steps {
                git credentialsId: 'github-credentials', url: GITHUB_REPO, branch: 'main'
            }
        }

        stage('Build Docker Image in OpenShift') {
            steps {
                script {
                    openshift.withCluster('Sandbox', 'openshift-credentials') {
                        openshift.withProject(OPENSHIFT_PROJECT) {
                            def build = openshift.startBuild(BUILD_CONFIG_NAME)
                            env.BUILD_ID = build.object().metadata.name
                        }
                    }
                }
            }
        }

        stage('Wait for OpenShift Build to Complete') {
            steps {
                script {
                    openshift.withCluster('Sandbox', 'openshift-credentials') {
                        openshift.withProject(OPENSHIFT_PROJECT) {
                            def buildStatus = ""
                            def counter = 0
                            def maxAttempts = 12
                            
                            while (buildStatus != "Complete" && buildStatus != "Failed" && counter < maxAttempts) {
                                // Use the captured BUILD_ID to get its status
                                buildStatus = openshift.selector('build', env.BUILD_ID).object().status.phase
                                if (buildStatus != "Complete" && buildStatus != "Failed") {
                                    sleep(time: 10, unit: "SECONDS")
                                    counter++
                                }
                            }
                            
                            if (buildStatus == "Failed" || counter == maxAttempts) {
                                error("Build failed or timeout reached")
                            }
                        }
                    }
                }
            }
        }        

        stage('Tag and Push to OpenShift ImageStream') {
            steps {
                script {
                    openshift.withCluster('Sandbox', 'openshift-credentials') {
                        openshift.withProject(OPENSHIFT_PROJECT) {
                            openshift.tag("${OPENSHIFT_PROJECT}/${IMAGESTREAM_NAME}:latest", "${OPENSHIFT_PROJECT}/${IMAGESTREAM_NAME}:${BUILD_ID}")
                        }
                    }
                }
            }
        }
    }
}
