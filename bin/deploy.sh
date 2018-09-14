#!/bin/bash
#
# Usage: ./deploy.sh
#
# Example: ./deploy
#
# needs docker command (v1.3 or later) in order to work.
#


# Defaults #
SHORT_GIT_HASH=$(echo $CIRCLE_SHA1 | cut -c -7)
TAG=$SHORT_GIT_HASH
IMAGE_TAG=$CIRCLE_PROJECT_REPONAME:$TAG
IMAGE_NAME="$ECR_REPO/$IMAGE_TAG"
REPO=$ECR_REPO
AWS_REGION="us-east-2"

aws configure set default.region $AWS_REGION


usage() {
    echo "Usage deploy.sh [-a|--action] [-c|--cluster] [-s|--service]"
}

build-docker(){
    # Builds the docker image and Push to ECR
    # No Args needed

    docker build -t $CIRCLE_PROJECT_REPONAME .
    docker tag $CIRCLE_PROJECT_REPONAME:latest $REPO/$IMAGE_TAG
    docker tag $CIRCLE_PROJECT_REPONAME:latest $REPO/$CIRCLE_PROJECT_REPONAME:latest

    $(aws ecr get-login --region $AWS_REGION)

    docker push $REPO/$IMAGE_TAG
    docker push $REPO/$CIRCLE_PROJECT_REPONAME:latest
}

ecs-deploy() {
    # Deploys a new revison to ECS cluster
    # Arg1 - ECS Cluster Name
    # Arg2 - ECS Service Name
    CLUSTER_NAME=$1
    SERVICE_NAME=$2
    TASK_FAMILY=$CIRCLE_PROJECT_REPONAME
    TASK_FILE="impressBot-${BUILD_NUMBER}.json"

    sed -e "s;%IMAGE_TAG%;${TAG};g" ecs-tasks.json > ${TASK_FILE}
    aws ecs register-task-definition --family $TASK_FAMILY --cli-input-json file://${TASK_FILE}
    TASK_REVISION=`aws ecs describe-task-definition --task-definition ${TASK_FAMILY} | egrep "revision" | tr "/" " " | awk '{print $2}' | sed 's/"$//'`
    aws ecs update-service --cluster ${CLUSTER_NAME} --service ${SERVICE_NAME} --task-definition ${TASK_FAMILY}:${TASK_REVISION}

}

rollback() {
    # Rollback to a previous task revision
    #
    echo "Pass"
}


# Parse Parameters #
for ARG in $*; do
  case $ARG in
    -c=*|--cluster=*)
      cluster=${ARG#*=}
      ;;

    -s=*|--service=*)
      service=${ARG#*=}
      ;;

    -a=*|--action=*)
      action=${ARG#*=}
      ;;
    *)
      echo "Unknown Argument $ARG";usage ;;
  esac
done



if [ $action == "build" ];then
    #Build and Push the docker container
    build-docker

elif [ $action == "deploy" ];then
    #Deploy revision to ECS
    ecs-deploy $cluster $service

elif [ $action == "rollback" ];then
    #Deploy revision to ECS
    rollback $cluster $service
fi
