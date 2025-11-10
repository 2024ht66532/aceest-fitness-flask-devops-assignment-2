pipeline {
  agent any
  environment {
    DOCKER_IMAGE = "docker.io/<dockerhub-user>/aceest-fitness"
    IMAGE_TAG = "${env.BUILD_ID}"
    SONARQUBE = "SonarQube"
  }
  stages {
    stage('Checkout') { steps { checkout scm } }
    stage('Build & Unit Tests') {
      steps {
        sh 'python -m pip install --upgrade pip'
        sh 'pip install -r requirements.txt'
        sh 'pytest -q --disable-warnings'
      }
    }
    stage('SonarQube Scan') {
      steps {
        withSonarQubeEnv("${SONARQUBE}") {
          sh 'sonar-scanner -Dsonar.projectKey=aceest-fitness -Dsonar.sources=. -Dsonar.python.coverage.reportPaths=coverage.xml || true'
        }
      }
    }
    stage('Build Docker') { steps { sh "docker build -t ${DOCKER_IMAGE}:${IMAGE_TAG} ." } }
    stage('Push Docker') {
      steps {
        withCredentials([usernamePassword(credentialsId: 'dockerhub-creds', usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')]) {
          sh 'echo $DOCKER_PASS | docker login -u $DOCKER_USER --password-stdin'
          sh "docker push ${DOCKER_IMAGE}:${IMAGE_TAG}"
        }
      }
    }
    stage('Deploy to Kubernetes (rolling update)') {
      steps {
        withCredentials([file(credentialsId: 'kubeconfig', variable: 'KUBECONFIG_FILE')]) {
          sh 'export KUBECONFIG=$KUBECONFIG_FILE'
          sh "kubectl set image deployment/aceest-deploy aceest=${DOCKER_IMAGE}:${IMAGE_TAG} --record || kubectl apply -f k8s/rolling-deploy.yaml"
        }
      }
    }
  }
  post { success { echo "Pipeline completed successfully." } }
}
