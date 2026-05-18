pipeline {
  agent any

  parameters {
    string(name: 'IMAGE_TAG', defaultValue: 'latest', description: 'Docker image tag')
    string(name: 'JFROG_REPO', defaultValue: 'docker-local', description: 'JFrog docker repo')
    string(name: 'RUNNER_VERSION', defaultValue: '2.334.0', description: 'GitHub Actions runner version')
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
          docker build \
            --build-arg RUNNER_VERSION=${RUNNER_VERSION} \
            -t ${IMAGE_NAME}:${IMAGE_TAG} .
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
