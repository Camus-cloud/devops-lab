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
        withCredentials([string(credentialsId: 'k8s-kubeconfig-b64', variable: 'KUBECONFIG_B64')]) {
            sh """
                echo "\$KUBECONFIG_B64" | tr -d ' \\n' | base64 -d --ignore-garbage > /tmp/kubeconfig-\$BUILD_NUMBER.yaml
                export KUBECONFIG=/tmp/kubeconfig-\$BUILD_NUMBER.yaml
                kubectl set image deployment/${DEPLOYMENT_NAME} ${DEPLOYMENT_NAME}=${REGISTRY}/${IMAGE_NAME}:${IMAGE_TAG} -n ${KUBE_NAMESPACE}
                kubectl rollout status deployment/${DEPLOYMENT_NAME} -n ${KUBE_NAMESPACE} --timeout=120s
                rm -f /tmp/kubeconfig-\$BUILD_NUMBER.yaml
            """
        }
    }
}
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



