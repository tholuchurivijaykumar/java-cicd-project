pipeline {
    agent any

    environment {
        DOCKER_HUB_CREDS = credentials('dockerhub-creds')
        DOCKER_HUB_IMAGE = 'vijay14082003/java-cicd-app'
        DOCKER_TAG = "${env.BUILD_NUMBER}"
    }

    triggers {
        cron('H/2 * * * *')
    }

    stages {
        stage('Checkout') {
            steps {
                git branch: 'main',
                    url: 'https://github.com/tholuchurivijaykumar/java-cicd-project.git',
                    credentialsId: 'github-creds'
            }
        }

        stage('Build') {
            steps {
                sh 'mvn clean compile -B'
            }
        }

        stage('Unit Tests') {
            steps {
                sh 'mvn test -B'
            }
            post {
                always {
                    junit '**/target/surefire-reports/*.xml'
                }
            }
        }

        stage('Package') {
            steps {
                sh 'mvn package -DskipTests -B'
            }
        }

        stage('Docker Build and Push') {
            steps {
                script {
                    sh "docker build -t ${DOCKER_HUB_IMAGE}:${DOCKER_TAG} ."
                    sh "docker tag ${DOCKER_HUB_IMAGE}:${DOCKER_TAG} ${DOCKER_HUB_IMAGE}:latest"
                    sh "echo ${DOCKER_HUB_CREDS_PSW} | docker login -u ${DOCKER_HUB_CREDS_USR} --password-stdin"
                    sh "docker push ${DOCKER_HUB_IMAGE}:${DOCKER_TAG}"
                    sh "docker push ${DOCKER_HUB_IMAGE}:latest"
                }
            }
        }

        stage('Deploy to Minikube') {
            steps {
                script {
                    sh "kubectl set image deployment/java-cicd-app java-cicd-app=${DOCKER_HUB_IMAGE}:${DOCKER_TAG} --record"
                    sh "kubectl rollout status deployment/java-cicd-app --timeout=120s"
                    sh "kubectl get pods -l app=java-cicd-app"
                    sh "kubectl get svc java-cicd-app-service"
                }
            }
        }

        stage('Verify Deployment') {
            steps {
                script {
                    sh "kubectl get all | grep java-cicd-app"
                    sh "curl -s http://localhost:\$(kubectl get svc java-cicd-app-service -o jsonpath='{.spec.ports[0].nodePort}')/api/hello || echo 'App starting up...'"
                }
            }
        }
    }

    post {
        success {
            echo 'Pipeline completed successfully! Application deployed to Minikube.'
        }
        failure {
            echo 'Pipeline failed. Check logs for details.'
        }
        always {
            sh 'docker logout || true'
        }
    }
}
