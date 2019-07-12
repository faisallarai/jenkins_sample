#!groovy​
pipeline {
    agent any
    environment{
        MAJOR_VERSION = 1
    	AWS_ID = credentials("AWS_ID")
        AWS_ACCESS_KEY_ID = "${env.AWS_ACCESS_KEY_ID}"
        AWS_SECRET_ACCESS_KEY = "${env.AWS_SECRET_ACCESS_KEY}"
        WORKSPACE = "${env.WORKSPACE}"
        ANSIBLE_PLAYBOOK = "../ansible/apps/playbook.yml"
        PACKER_POSTPROCESS = ".././get_ami.sh"
        AMI_SCRIPT = "../get_ami.sh"
    }

    parameters {
        booleanParam(name: 'TF_CLEANUP', defaultValue: true, 
            description: 'Cleanup the AWS resources  (TF destroy) when we are done') 
        booleanParam(name: 'AMI_CLEANUP', defaultValue: true, 
            description: 'Cleanup the AWS AMI custom images when we are done') 
        booleanParam(name: 'TF_ASG', defaultValue: false, 
            description: 'Option to setup multiple web servers in ASG/ELB')
        string(name: 'TF_CLEANUP_SLEEP', defaultValue: '300', 
            description: 'Seconds to sleep before TF destroy of all infra (if selected)')
    }

    options {
        buildDiscarder(logRotator(numToKeepStr:'5', artifactNumToKeepStr: '3'))
    }
    stages{
        
         stage('Check-Update Terraform Binary'){
            agent any
            environment {
               JENKINS_PATH = sh(script: 'pwd', , returnStdout: true).trim()
            }
            steps{
                script{
                    sh "printenv | sort"
                    def tfout = sh returnStdout: true, script: 'terraform --version'
                    echo "tf output: ${tfout}"
                }
            }
        }

        stage('Init Terraform - Single Web Server (No ASG)'){
            agent any
            when {
                expression { params.TF_ASG != true }
            }
            steps{
                dir('terraform/apps'){
                    sh "terraform init -input=false -var 'aws_access_key=${AWS_ACCESS_KEY_ID}' -var 'aws_secret_key=${AWS_SECRET_ACCESS_KEY}'"
                }
            }
        }

        stage('Prepare App Server AWS AMI'){
            agent any
            environment {
               MAIN_PATH = sh(script: 'pwd', , returnStdout: true).trim()
            }
	    steps{
                echo "Publishing application to the build folder"
                dir("${MAIN_PATH}"){
                  sh "dotnet publish -o build -c Release"
                  sh "cp -r build $WORKSPACE"
                }
            }
        }

	stage('Create App Server AWS AMI'){
            agent any
            steps{
                echo "Create AWS AMI using Packer"
                dir('packer'){
                    sh "chmod +x ${AMI_SCRIPT}"
                    sh 'if [ -f manifest.json ]; then rm manifest.json; fi'
                    sh "packer build -var 'workspace=${WORKSPACE}/build/' -var 'tag_name=${BUILD_TAG}' -var 'postscript=${PACKER_POSTPROCESS}' -var 'playbook=${ANSIBLE_PLAYBOOK}' -var 'access_key=${AWS_ACCESS_KEY_ID}' -var 'secret_key=${AWS_SECRET_ACCESS_KEY}' apps.json"
                }
            }
        }
        
        stage('Deploy App Server AWS Instance'){
            agent any
            when {
                expression { params.TF_ASG != true }
            }
            steps{
                echo "Creating AWS Instance using terraform"
                dir('terraform/apps'){
                    sh "terraform plan -var 'aws_access_key=${AWS_ACCESS_KEY_ID}' -var 'aws_secret_key=${AWS_SECRET_ACCESS_KEY}' -var 'job_name=${JOB_BASE_NAME}' -var 'tag_name=${BUILD_TAG}'"
                    sh "terraform apply -auto-approve -var 'aws_access_key=${AWS_ACCESS_KEY_ID}' -var 'aws_secret_key=${AWS_SECRET_ACCESS_KEY}' -var 'job_name=${JOB_BASE_NAME}' -var 'tag_name=${BUILD_TAG}'"
                }
            }
        }
   }
}
