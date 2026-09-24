// Jenkinsfile - ISEC6000 Assessment 2 - 23354447
// Install -> Unit tests -> Snyk security gate -> Build image -> Smoke test -> Push to Docker Hub

pipeline {
  // Default agent: the Jenkins container (has the Docker CLI and talks to DinD over TLS)
  agent any

  options {
    buildDiscarder(logRotator(numToKeepStr: '10', artifactNumToKeepStr: '5'))  // keep the last 10 builds
    timestamps()                          // time on every log line
    timeout(time: 30, unit: 'MINUTES')    // stop a stuck build
    disableConcurrentBuilds()             // one build at a time
  }

  triggers {
    pollSCM('H/2 * * * *')                // check GitHub for new commits about every 2 minutes
  }

  environment {
    IMAGE_NAME = 'nehanazesh/isec6000-express-app'   // Docker Hub repository
    IMAGE_TAG  = "${env.BUILD_NUMBER}"              // every build gets its own tag
  }

  stages {

    stage('Install Dependencies') {
      // Node 16 image as the build agent - no "-u root", so steps run as a normal user
      agent { docker { image 'node:16'; reuseNode true } }
      steps {
        sh 'node --version && npm --version && id'
        sh 'npm ci'                       // exact versions from package-lock.json
      }
    }

    stage('Unit Tests') {
      agent { docker { image 'node:16'; reuseNode true } }
      steps {
        sh 'npm test'
      }
      post {
        always { junit 'reports/junit.xml' }   // shows results on the Test Result page
      }
    }

    stage('Security Scan (Snyk)') {
      agent { docker { image 'node:16'; reuseNode true } }
      steps {
        withCredentials([string(credentialsId: 'snyktoken', variable: 'SNYK_TOKEN')]) {
          sh '''
            mkdir -p reports
            npx --yes snyk@1.1307.4 test --severity-threshold=high --json-file-output=reports/snyk.json --sarif-file-output=reports/snyk.sarif
            echo "SECURITY GATE PASSED: no High or Critical vulnerabilities"
          '''
        }
      }
      post {
        always {
          recordIssues enabledForFailure: true, tool: sarif(pattern: 'reports/snyk.sarif', id: 'snyk', name: 'Snyk Open Source')
        }
        failure {
          echo 'SECURITY GATE FAILED: High/Critical vulnerabilities found - image will NOT be built or pushed'
        }
      }
    }

    stage('Build Docker Image') {
      steps {
        sh 'docker build -t "$IMAGE_NAME:$IMAGE_TAG" -t "$IMAGE_NAME:latest" .'
      }
    }

    stage('Smoke Test') {
      steps {
        sh '''
          docker run -d --name "smoke-$BUILD_NUMBER" "$IMAGE_NAME:$IMAGE_TAG"
          for i in 1 2 3 4 5 6 7 8 9 10; do
            if docker exec "smoke-$BUILD_NUMBER" wget -qO- http://localhost:8080/health; then
              echo ""
              echo "Container runs as user: $(docker exec smoke-$BUILD_NUMBER whoami)"
              echo "SMOKE TEST PASSED"
              exit 0
            fi
            sleep 2
          done
          echo "SMOKE TEST FAILED"
          exit 1
        '''
      }
      post {
        always { sh 'docker rm -f "smoke-$BUILD_NUMBER" || true' }
      }
    }

    stage('Push to Docker Hub') {
      steps {
        withCredentials([usernamePassword(credentialsId: 'dockerhub-credentials', usernameVariable: 'DOCKERHUB_USER', passwordVariable: 'DOCKERHUB_TOKEN')]) {
          sh '''
            echo "$DOCKERHUB_TOKEN" | docker login -u "$DOCKERHUB_USER" --password-stdin
            docker push "$IMAGE_NAME:$IMAGE_TAG"
            docker push "$IMAGE_NAME:latest"
          '''
        }
      }
      post {
        always { sh 'docker logout || true' }
      }
    }
  }

  post {
    always {
      archiveArtifacts artifacts: 'reports/**, coverage/**', allowEmptyArchive: true, fingerprint: true
    }
    success { echo "Pipeline succeeded - pushed ${env.IMAGE_NAME}:${env.IMAGE_TAG}" }
    failure { echo 'Pipeline failed - check the stage logs above' }
  }
}
