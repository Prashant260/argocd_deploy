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
    booleanParam(name: 'RUN_SECURITY_SCAN', defaultValue: true, description: 'Run Trivy image scan if Trivy is installed')
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
        }
        sh '''
          echo "Image name: ${IMAGE_NAME}"
          echo "Image tag: ${IMAGE_TAG}"
          echo "Runner version: ${RUNNER_VERSION}"
        '''
      }
    }

    stage('Build Docker Image') {
      steps {
        sh '''
          docker build \
            --build-arg RUNNER_VERSION=${RUNNER_VERSION} \
            -t ${IMAGE_NAME}:${IMAGE_TAG} \
            -t ${IMAGE_NAME}:${SHORT_SHA} .
        '''
      }
    }

    stage('Security Scan') {
      when {
        expression { return params.RUN_SECURITY_SCAN }
      }
      steps {
        sh '''
          if command -v trivy >/dev/null 2>&1; then
            trivy image --severity HIGH,CRITICAL ${IMAGE_NAME}:${IMAGE_TAG}
          else
            echo "Trivy is not installed on this Jenkins agent, skipping scan"
          fi
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

            JFROG_IMAGE="${JFROG_REGISTRY}/${JFROG_REPO}/${IMAGE_NAME}"

            echo "${JFROG_PASS}" | docker login "${JFROG_REGISTRY}" -u "${JFROG_USER}" --password-stdin

            docker tag ${IMAGE_NAME}:${IMAGE_TAG} ${JFROG_IMAGE}:${IMAGE_TAG}
            docker tag ${IMAGE_NAME}:${SHORT_SHA} ${JFROG_IMAGE}:${SHORT_SHA}

            docker push ${JFROG_IMAGE}:${IMAGE_TAG}
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
