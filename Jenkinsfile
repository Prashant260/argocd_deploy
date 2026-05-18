pipeline {
  agent any

  parameters {
    string(name: 'IMAGE_TAG', defaultValue: 'latest', description: 'Docker image tag')
    string(name: 'JFROG_REPO', defaultValue: 'docker-local', description: 'JFrog docker repo')
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

    stage('Build Docker Image') {
      steps {
        sh '''
          docker build -t ${IMAGE_NAME}:${IMAGE_TAG} .
        '''
      }
    }

    stage('Scan Image') {
      steps {
        sh '''
          if command -v trivy >/dev/null 2>&1; then
            trivy image --severity HIGH,CRITICAL ${IMAGE_NAME}:${IMAGE_TAG}
          else
            echo "Trivy is not installed, skipping scan"
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
            SHORT_SHA=$(git rev-parse --short HEAD)

            echo "${JFROG_PASS}" | docker login "${JFROG_REGISTRY}" -u "${JFROG_USER}" --password-stdin

            docker tag ${IMAGE_NAME}:${IMAGE_TAG} ${JFROG_REGISTRY}/${JFROG_REPO}/${IMAGE_NAME}:${IMAGE_TAG}
            docker tag ${IMAGE_NAME}:${IMAGE_TAG} ${JFROG_REGISTRY}/${JFROG_REPO}/${IMAGE_NAME}:${SHORT_SHA}

            docker push ${JFROG_REGISTRY}/${JFROG_REPO}/${IMAGE_NAME}:${IMAGE_TAG}
            docker push ${JFROG_REGISTRY}/${JFROG_REPO}/${IMAGE_NAME}:${SHORT_SHA}
          '''
        }
      }
    }
  }

  post {
    always {
      sh '''
        docker logout ${JFROG_REGISTRY} || true
        docker image prune -f || true
      '''
    }
  }
}
