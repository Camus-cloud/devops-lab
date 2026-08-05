pipeline {
    agent any

    environment {
        REGISTRY = "ghcr.io"
        IMAGE_NAME = "camus-cloud/devops-lab"
        IMAGE_TAG = "${env.BUILD_NUMBER}"
        KUBE_NAMESPACE = "default"
        DEPLOYMENT_NAME = "myapp"
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Build Docker Image') {
            steps {
                sh "docker build -t ${REGISTRY}/${IMAGE_NAME}:${IMAGE_TAG} ."
            }
        }

        stage('Push to Registry') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'ghcr-creds', usernameVariable: 'REG_USER', passwordVariable: 'REG_PASS')]) {
                    sh """
                        echo \$REG_PASS | docker login ${REGISTRY} -u \$REG_USER --password-stdin
                        docker push ${REGISTRY}/${IMAGE_NAME}:${IMAGE_TAG}
                    """
                }
            }
        }

        stage('Deploy to Kubernetes') {
            steps {
                withCredentials([file(credentialsId: 'k8s-kubeconfig', variable: 'KUBECONFIG_FILE')]) {
                    sh """
                        export KUBECONFIG=\$KUBECONFIG_FILE
                        kubectl set image deployment/${DEPLOYMENT_NAME} ${DEPLOYMENT_NAME}=${REGISTRY}/${IMAGE_NAME}:${IMAGE_TAG} -n ${KUBE_NAMESPACE}
                        kubectl rollout status deployment/${DEPLOYMENT_NAME} -n ${KUBE_NAMESPACE} --timeout=120s
                    """
                }
            }
        }
    }

    post {
        success {
            echo "✅ Pipeline réussi : image ${IMAGE_TAG} déployée sur ${DEPLOYMENT_NAME}"
        }
        failure {
            echo "❌ Échec du pipeline"
        }
    }
}



