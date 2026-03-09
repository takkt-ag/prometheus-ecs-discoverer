@Library('aws-ecom-jsl') _

/*
 * Following variables should only be modified by renovate
 * Please do only modify if you are absolutely certain you
 * know what you are about to unleash
 * Doc: https://bitbucket.org/kkeu/renovate-bot/pull-requests/46
 */

def docker_version_linter = '2.867.0' // docker.shared.ecom.kkeu.de/ecom-tools-linter

/* End of renovate version variables */

pipeline {
    environment {
        ECR_REGISTRY = '191578016373.dkr.ecr.eu-central-1.amazonaws.com'
        ECR_REPOSITORY = 'kkeu/monitoring/promecsdiscovery'
        NEXUS_REGISTRY = 'docker.priv.ecom.kkeu.de'
        AWS_REGION = 'eu-central-1'
    }
    agent {
        label 'docker'
    }
    stages {
        stage('Get Version') {
            steps {
                script {
                    // Extract version from pyproject.toml
                    env.IMAGE_TAG = sh(
                        script: "grep '^version = ' pyproject.toml | sed 's/version = \"\\(.*\\)\"/\\1/'",
                        returnStdout: true
                    ).trim()
                    echo "Building version: ${env.IMAGE_TAG}"
                }
            }
        }

        stage('Linting (ecom-tools-linter)') {
            agent {
                docker {
                    image "docker.shared.ecom.kkeu.de/ecom-tools-linter:${docker_version_linter}"
                    reuseNode true
                }
            }

            stages {
                stage('Linting') {
                    parallel {
                        stage('YAML Lint') {
                            steps {
                                sh '''
                                    rm -rf */node_modules/ ||:
                                    find . \
                                        -not -path './.git/*' \
                                        -not -path './.github/*' \
                                        -not -path './*/node_modules/*' \
                                        \\( -name '*.yaml' -o -name '*.yml' \\) \
                                        -type f \
                                        -print0 \
                                    | xargs -0 -r yamllint
                                '''
                            }
                        }

                        stage('JSON Lint') {
                            steps {
                                sh '''
                                    find . \
                                        -not -path './.git/*' \
                                        -not -path './*/node_modules/*' \
                                        -name '*.json' \
                                        -type f \
                                        -print0 \
                                    | parallel \
                                        --will-cite -k -0 -n1 \
                                            jsonlint -cq
                                '''
                            }
                        }

                        stage('tomlcheck') {
                            steps {
                                sh '''
                                    find . \
                                        -not -path './.git/*' \
                                        -not -path './*/node_modules/*' \
                                        -name '*.toml' \
                                        -type f \
                                        -print0 \
                                    | parallel \
                                        --will-cite -k -0 -n1 \
                                        tomlcheck --file
                                '''
                            }
                        }
                    }
                }
            }
        }

        stage('Linting (Python)') {
            agent {
                dockerfile {
                    label 'docker'
                    filename 'Dockerfile'
                    reuseNode true
                }
            }

            environment {
                POETRY_VIRTUALENVS_IN_PROJECT = 'true'
                POETRY_VIRTUALENVS_PATH = "${env.WORKSPACE}/.venv"
                POETRY_CONFIG_DIR = "${env.WORKSPACE}/.poetry-config"
                POETRY_CACHE_DIR = "${env.WORKSPACE}/.poetry-cache"
                PIP_CONFIG_FILE = "${env.WORKSPACE}/pip.conf"
            }

            stages {
                stage('Prepare') {
                    steps {
                        sh '''
                        python -m pip install poetry
                        poetry install
                        '''
                    }
                }

                stage('Black (Python code-style)') {
                    steps {
                        sh '''
                        poetry run black \
                            --verbose \
                            --check \
                            --target-version py39 \
                            .
                        '''
                    }
                }

                stage('Flake8') {
                    steps {
                        sh '''
                        poetry run flake8 \
                            prometheus_ecs_discoverer tests
                        '''
                    }
                }
            }
        }

        stage('Build Docker Image') {
            when {
                anyOf {
                    branch 'takkt-fix-for-3-3-3'
                }
            }
            steps {
                script {
                    sh """
                        docker image build \
                            -t ${env.NEXUS_REGISTRY}/${env.ECR_REPOSITORY}:${env.IMAGE_TAG} \
                            -t ${env.ECR_REGISTRY}/${env.ECR_REPOSITORY}:${env.IMAGE_TAG} \
                            . \
                            ;
                    """
                }
            }
        }

        stage('Push Docker Image') {
            when {
                anyOf {
                    branch 'takkt-fix-for-3-3-3'
                }
            }
            steps {
                script {
                    // Push image to Nexus
                    withDockerRegistry([
                        url          : "https://${env.NEXUS_REGISTRY}",
                        credentialsId: 'nexus_beg_serviceuser',
                    ]) {
                        sh """
                            docker image push \
                                ${env.NEXUS_REGISTRY}/${env.ECR_REPOSITORY}:${env.IMAGE_TAG} \
                                ;
                        """
                    }

                    // Push image into ECR (only on master)
                    if ( env.BRANCH_NAME == 'takkt-fix-for-3-3-3' ) {
                        withCredentials([[
                            $class       : 'AmazonWebServicesCredentialsBinding',
                            credentialsId: 'aws_jenkins_packer',
                        ]]) {
                            sh '''
                                # To avoid printing the login-data, we disable the extended execution output.
                                set +x
                                eval "$(aws ecr get-login --region eu-central-1 --no-include-email)"
                            '''
                            sh """
                                docker image push \
                                    ${env.ECR_REGISTRY}/${env.ECR_REPOSITORY}:${env.IMAGE_TAG} \
                                    ;
                            """
                        }
                    }
                }
            }
        }
    }

    post {
        always {
            // Clean up Docker images
            sh """
                docker rmi ${env.NEXUS_REGISTRY}/${env.ECR_REPOSITORY}:${env.IMAGE_TAG} || true
                docker rmi ${env.ECR_REGISTRY}/${env.ECR_REPOSITORY}:${env.IMAGE_TAG} || true
            """
        }
        failure {
            sendBuildStatus()
        }
    }
}
