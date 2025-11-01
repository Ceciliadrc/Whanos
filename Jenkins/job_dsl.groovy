folder('Whanos base images') {
    description('Whanos Base Images')
    displayName('Whanos base images')
}

folder('Projects') {
    description('Projects')
    displayName('Projects')
}

job('Whanos base images/whanos-c') {
    parameters {
        stringParam('IMAGE_NAME_C', '', 'Image name for C')
    }
    steps {
        wrappers {
            preBuildCleanup()
        }
        shell('docker build -t ${IMAGE_NAME_C} -f images/c/Dockerfile.base .')
    }
}

job('Whanos base images/whanos-java') {
    parameters {
        stringParam('IMAGE_NAME_JAVA', '', 'Image name for Java')
    }
    steps {
        wrappers {
            preBuildCleanup()
        }
        shell('docker build -t ${IMAGE_NAME_JAVA} -f images/java/Dockerfile.base .')
    }
}

job('Whanos base images/whanos-javascript') {
    parameters {
        stringParam('IMAGE_NAME_JAVASCRIPT', '', 'Image name for Javascript')
    }
    steps {
        wrappers {
            preBuildCleanup()
        }
        shell('docker build -t ${IMAGE_NAME_JAVASCRIPT} -f images/javascript/Dockerfile.base .')
    }
}

job('Whanos base images/whanos-python') {
    parameters {
        stringParam('IMAGE_NAME_PYTHON', '', 'Image name for Python')
    }
    steps {
        wrappers {
            preBuildCleanup()
        }
        shell('docker build -t ${IMAGE_NAME_PYTHON} -f images/python/Dockerfile.base .')
    }
}

job('Whanos base images/whanos-befunge') {
    parameters {
        stringParam('IMAGE_NAME_BEFUNGE', '', 'Image name for Befunge')
    }
    steps {
        wrappers {
            preBuildCleanup()
        }
        shell('docker build -t ${IMAGE_NAME_BEFUNGE} -f images/befunge/Dockerfile.base .')
    }
}

job('Whanos base images/Build all base images') {
    stage('Trigger build of all jobs') {
        steps {
            parallel (
                c: {
                    build job: 'Whanos base images/whanos-c'
                },
                java: {
                    build job: 'Whanos base images/whanos-java'
                },
                javascript: {
                    build job: 'Whanos base images/whanos-javascript'
                },
                python: {
                    build job: 'Whanos base images/whanos-python'
                },
                befunge: {
                    build job: 'Whanos base images/whanos-befunge'
                }
            )
        }
    }
}

job('link-project') {
    parameters {
        stringParam('REPO_URL', '', 'Git repository URL')
        stringParam('PROJECT_NAME', '', 'Name for the job to create')
    }
    steps {
        dsl {
            text('''
                freeStyleJob("Projects/${PROJECT_NAME}") {
                    scm {
                        git {
                            remote {
                                url("${REPO_URL}")
                            }
                            branches("main")
                        }
                    }
                    triggers {
                        scm("H/5 * * * *")
                    }
                    wrappers {
                        preBuildCleanup()
                    }
                    steps {
                        shell("""
                            chmod +x /var/jenkins_home/deploy.sh
                            /var/jenkins_home/deploy.sh "${PROJECT_NAME}"
                        """)
                    }
                }
            ''')
        }
    }
    wrappers {
        preBuildCleanup()
    }
}

pipelineJob('Deployments/whanos-deploy') {
    definition {
        cpsScm {
            scm {
                git {
                    remote {
                        url('https://github.com/Ceciliadrc/Whanos')
                    }
                    branch('main')
                }
            }
            scriptPath('Kubernetes/Jenkinsfile')
        }
    }
    parameters {
        stringParam('IMAGE_URL', '', 'Docker image URL')
        stringParam('APP_NAME', '', 'Application name')
        stringParam('HOST_NAME', '', 'Host name')
        textParam('YAML_CONTENT', '', 'Custom YAML configuration')
    }
}