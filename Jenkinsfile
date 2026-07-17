pipeline {
    agent any

    triggers {
        cron('H/2 * * * *')
    }

    stages {
        stage('Checkout') {
            steps {
                git branch: 'main',
                    url: 'https://github.com/tholuchurivijaykumar/java-cicd-project.git'
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
                    junit allowEmptyResults: true, testResults: '**/target/surefire-reports/*.xml'
                }
            }
        }

        stage('Package') {
            steps {
                sh 'mvn package -DskipTests -B'
            }
        }

        stage('Docker Build') {
            steps {
                script {
                    def imageTag = "${env.BUILD_NUMBER}"
                    def dockerImage = "vijay14082003/java-cicd-app"
                    sh "docker build -t ${dockerImage}:${imageTag} ."
                    sh "docker tag ${dockerImage}:${imageTag} ${dockerImage}:latest"
                }
            }
        }

        stage('Push to DockerHub') {
            steps {
                catchError(buildResult: 'UNSTABLE', stageResult: 'FAILURE') {
                    script {
                        def imageTag = "${env.BUILD_NUMBER}"
                        def dockerImage = "vijay14082003/java-cicd-app"
                        withCredentials([usernamePassword(credentialsId: 'dockerhub-creds', usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')]) {
                            sh "echo \$DOCKER_PASS | docker login -u \$DOCKER_USER --password-stdin"
                        }
                        sh "docker push ${dockerImage}:${imageTag}"
                        sh "docker push ${dockerImage}:latest"
                    }
                }
            }
        }

        stage('Deploy to Minikube') {
            steps {
                script {
                    def imageTag = "${env.BUILD_NUMBER}"
                    def dockerImage = "vijay14082003/java-cicd-app"
                    sh "minikube image load ${dockerImage}:${imageTag}"
                    sh "minikube image load ${dockerImage}:latest"
                    sh "kubectl set image deployment/java-cicd-app java-cicd-app=${dockerImage}:${imageTag} --record"
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
