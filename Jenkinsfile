pipeline{
    agent any
    tools{
        jdk 'jdk'
        nodejs 'node'
    }
    environment {
        SCANNER_HOME=tool 'sonar-scanner'
    }
    stages {
        stage('clean workspace'){
            steps{
                cleanWs()
            }
        }
        stage('Checkout from Git'){
            steps{
               checkout scm
            }
        }
        stage('Install Dependencies') {
            steps {
                sh "npm install"
            }
        }
        stage("Sonarqube Analysis "){
            steps{
                withSonarQubeEnv('SonarQube') {
                    sh ''' $SCANNER_HOME/bin/sonar-scanner -Dsonar.projectName=Hotstar \
                    -Dsonar.projectKey=Hotstar '''
                }
            }
        }
         
        stage("quality gate"){
           steps {
                script {
                    waitForQualityGate abortPipeline: false, credentialsId: 'Sonar-token' 
                }
            } 
        }
       
        stage('OWASP FS SCAN') {
            steps {
                dependencyCheck additionalArguments: '--scan ./ --disableYarnAudit --disableNodeAudit --nvdApiKey  5130299B-F4BF-F011-8364-0EBF96DE670D', odcInstallation: 'DC'
                dependencyCheckPublisher pattern: '**/dependency-check-report.xml'
           }
        }
            stage('Trivy File System Scan') {
            steps {
                catchError(buildResult: 'SUCCESS', stageResult: 'SUCCESS') {
                    sh "trivy fs . > trivyfs.txt || true"
                }
            }
        }

        stage('Docker Build & Push') {
            steps {
                script {
                    withDockerRegistry(credentialsId: 'docker', toolName: 'docker') {
                        sh "docker build -t hotstar ."
                        sh "docker tag hotstar manushreem/hotstar:latest"
                        sh "docker push manushreem/hotstar:latest"
                    }
                }
            }
        }

        stage("TRIVY Image Scan"){
            steps{
                sh "trivy image manushreem/hotstar:latest > trivyimage.txt" 
            }
        }
       stage('Deploy to Container') {
            steps {
                sh '''
                    docker rm -f hotstar || true
                    docker run -d --name hotstar -p 80:3000 manushreem/hotstar:latest
                '''
            }
        }
 stage('Configure Kubeconfig') {
            steps {
                sh '''
                    echo "Configuring kubeconfig for EKS cluster..."
                    aws eks --region $AWS_DEFAULT_REGION update-kubeconfig --name $CLUSTER_NAME
                    echo "Verifying kubectl connectivity..."
                    kubectl cluster-info
                    kubectl get nodes
                '''
            }
        }
        stage('Deploy to EKS') {
            steps {
                sh '''
                    echo "Applying manifests..."
                    kubectl apply -f K8S/manifest.yml
                '''
            }
        }

    }
    post {
    always {
        script {
            def buildStatus = currentBuild.currentResult
            def buildUser = currentBuild.getBuildCauses('hudson.model.Cause$UserIdCause')[0]?.userId ?: 'Github User'
            
            emailext (
                subject: "Pipeline ${buildStatus}: ${env.JOB_NAME} #${env.BUILD_NUMBER}",
                body: """
                    <p>This is a Jenkins HOTSTAR CICD pipeline status.</p>
                    <p>Project: ${env.JOB_NAME}</p>
                    <p>Build Number: ${env.BUILD_NUMBER}</p>
                    <p>Build Status: ${buildStatus}</p>
                    <p>Started by: ${buildUser}</p>
                    <p>Build URL: <a href="${env.BUILD_URL}">${env.BUILD_URL}</a></p>
                """,
                to: 'manushree.sinchu@gmail.com',
                from: 'manushree.sinchu@gmail.com',
                replyTo: 'manushree.sinchu@gmail.com',
                mimeType: 'text/html',
                attachmentsPattern: 'trivyfs.txt,trivyimage.txt'
            )
           }
       }

    }

}
