#!/bin/bash
# set -e
# This script shows how to build the Docker image and push it to ECR Public to be ready for use
# by SageMaker.

# The argument to this script is the image name. This will be used as the image on the local
# machine and combined with the account and region to form the repository name for ECR.
# Algorithm Name will be the Repository Name that is passed as a command line parameter.
echo "Inside build_and_push.sh file"
DOCKER_IMAGE_NAME=$1

echo "value of DOCKER_IMAGE_NAME is $DOCKER_IMAGE_NAME"

if [ "$DOCKER_IMAGE_NAME" == "" ]
then
    echo "Usage: $0 <image-name>"
    exit 1
fi
src_dir=$WORKSPACE

# Get the account number associated with the current IAM credentials
account=$(aws sts get-caller-identity --query Account --output text)

if [ $? -ne 0 ]
then
    exit 255
fi

# Set the region for ECR Public to us-east-1
region="us-east-1"
echo "Region value is : $region"

# If the repository doesn't exist in ECR Public, create it.
ecr_repo_name=$DOCKER_IMAGE_NAME"-public-ecr-repo"
echo "value of ecr_repo_name is $ecr_repo_name"

# || means if the first command succeed the second will never be executed
aws ecr-public describe-repositories --repository-names ${ecr_repo_name} --region $region || aws ecr-public create-repository --repository-name ${ecr_repo_name} --region $region

image_name=$DOCKER_IMAGE_NAME

# Get the login command from ECR Public and execute docker login
aws ecr-public get-login-password --region $region | docker login --username AWS --password-stdin public.ecr.aws

fullname="public.ecr.aws/${account}/${ecr_repo_name}:${image_name}"
echo "fullname is $fullname"

# Build the docker image locally with the image name and then push it to ECR Public with the full name.
docker build -t ${image_name} $WORKSPACE
echo "Docker build after"

echo "image_name is $image_name"
echo "Tagging of Docker Image in Progress"
docker tag ${image_name} ${fullname}
echo "Tagging of Docker Image is Done"
docker images

echo "Docker Push in Progress"
docker push ${fullname}
echo "Docker Push is Done"

if [ $? -ne 0 ]
then
    echo "Docker Push Event did not Succeed with Image ${fullname}"
    exit 1
else
    echo "Docker Push Event is Successful with Image ${fullname}"
fi


