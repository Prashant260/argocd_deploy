pipeline {
  agent any

  options {
    timestamps()
    disableConcurrentBuilds()
  }

  parameters {
    string(name: 'IMAGE_TAG', defaultValue: 'latest', description: 'Docker image tag')
    string(name: 'JFROG_REPO', defaultValue: 'docker-local', description: 'JFrog Docker repository')
    string(name: 'RUNNER_VERSION', defaultValue: '2.334.0', description: 'GitHub Actions runner version')
    string(name: 'DOCKER_CLI_VERSION', defaultValue: '27.5.1', description: 'Docker CLI version installed in the runner image')
  }

  environment {
    IMAGE_NAME = 'github-runner'
  }

  stages {
    stage('Checkout') {
      steps {
        checkout scm
      }
    }

    stage('Prepare') {
      steps {
        script {
          env.SHORT_SHA = sh(script: 'git rev-parse --short HEAD', returnStdout: true).trim()
          env.BUILD_IMAGE_TAG = params.IMAGE_TAG?.trim() ? params.IMAGE_TAG.trim() : 'latest'
          env.BUILD_JFROG_REPO = params.JFROG_REPO?.trim() ? params.JFROG_REPO.trim() : 'docker-local'
          env.BUILD_RUNNER_VERSION = params.RUNNER_VERSION?.trim() ? params.RUNNER_VERSION.trim() : '2.334.0'
          env.BUILD_DOCKER_CLI_VERSION = params.DOCKER_CLI_VERSION?.trim() ? params.DOCKER_CLI_VERSION.trim() : '27.5.1'
        }
        sh '''
          echo "Image name: ${IMAGE_NAME}"
          echo "Image tag: ${BUILD_IMAGE_TAG}"
          echo "JFrog repo: ${BUILD_JFROG_REPO}"
          echo "Runner version: ${BUILD_RUNNER_VERSION}"
          echo "Docker CLI version: ${BUILD_DOCKER_CLI_VERSION}"
        '''
      }
    }

    stage('Build Docker Image') {
      steps {
        sh '''
          docker build \
            --build-arg RUNNER_VERSION=${BUILD_RUNNER_VERSION} \
            --build-arg DOCKER_CLI_VERSION=${BUILD_DOCKER_CLI_VERSION} \
            -t ${IMAGE_NAME}:${BUILD_IMAGE_TAG} \
            -t ${IMAGE_NAME}:${SHORT_SHA} .
        '''
      }
    }
    stage('Push to JFrog') {
      steps {
        withCredentials([
          string(credentialsId: 'jfrog-registry-url', variable: 'JFROG_REGISTRY'),
          usernamePassword(credentialsId: 'jfrog-credentials', usernameVariable: 'JFROG_USER', passwordVariable: 'JFROG_PASS')
        ]) {
          sh '''
            set -e

            JFROG_IMAGE="${JFROG_REGISTRY}/${BUILD_JFROG_REPO}/${IMAGE_NAME}"

            echo "${JFROG_PASS}" | docker login "${JFROG_REGISTRY}" -u "${JFROG_USER}" --password-stdin

            docker tag ${IMAGE_NAME}:${BUILD_IMAGE_TAG} ${JFROG_IMAGE}:${BUILD_IMAGE_TAG}
            docker tag ${IMAGE_NAME}:${SHORT_SHA} ${JFROG_IMAGE}:${SHORT_SHA}

            docker push ${JFROG_IMAGE}:${BUILD_IMAGE_TAG}
            docker push ${JFROG_IMAGE}:${SHORT_SHA}
          '''
        }
      }
    }
  }

  post {
    always {
      sh '''
        docker logout || true
        docker image prune -f || true
      '''
    }
  }
}
