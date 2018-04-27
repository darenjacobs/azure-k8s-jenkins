#!/bin/sh

set -euo pipefail

CWD="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
LOCATION=eastus
RESOURCE_GROUP=demo-kube
AKS_CLUSTER=demo-cluster
#ACR_NAME=demoacr$RANDOM
ACR_NAME=demoacr244966
EMAIL=daren.jacobs@fhlbny.com
SERVICE_PRINCIPAL=$(az ad sp create-for-rbac --skip-assignment)

func_create_images(){

  is_images=$(docker images | tail -1 | awk '{print $1}')

  if [ "${is_images}" == "REPOSITORY" ]; then
    echo "Creating Docker images"
    if ! [ -d ~/github/azure-voting-app-redis ]; then
      if ! [ -d ~/github ]; then
        mkdir ~/github
      fi
      cd ~/github/
      git clone git@github.com:darenjacobs/azure-voting-app-redis.git
    fi

    cd ~/github/azure-voting-app-redis
    docker-compose up -d
    docker-compose stop
    docker-compose down
    func_create_images
  fi
  cd $CWD
}
func_create_images


# Create Resource Group
az group create -n $RESOURCE_GROUP -l $LOCATION

# Deploy Azure Container Registry
#az acr create -n $ACR_NAME -g $RESOURCE_GROUP --sku Basic
az acr create -n $ACR_NAME -g $RESOURCE_GROUP --sku Managed_Standard --admin-enabled true

# Container registry login
az acr login -n $ACR_NAME
ACR_ID=$(az acr show -n $ACR_NAME -g $RESOURCE_GROUP --query id -o tsv)
ACR_SERVER=$(az acr list -g $RESOURCE_GROUP --query loginServer -o tsv)
ACR_USERNAME=$(az acr show -n $ACR_NAME -g $RESOURCE_GROUP --query username -o tsv)
ACR_PASSWORD=$(az acr show -n $ACR_NAME -g $RESOURCE_GROUP --query passwords[0].value -o tsv)


# Tag container images
docker tag azure-vote-front ${ACR_SERVER}/azure-vote-front:v1
docker images

# Push images to registry
docker login ${ACR_SERVER} -u ${ACR_USERNAME} -p ${ACR_PASSWORD}
docker push ${ACR_SERVER}/azure-vote-front:v1

# List imags in registry
az acr repository list --name ${ACR_NAME} --output table
az acr repository show-tags --name ${ACR_NAME} --repository azure-vote-front --output table


# Create Kubernetes Cluster
az provider register -n Microsoft.Network
az provider register -n Microsoft.Storage
az provider register -n Microsoft.Compute
az provider register -n Microsoft.ContainerService

# Use the Service Principal
SP_APP_ID=$(echo $SERVICE_PRICIPAL |jq .'appId')
SP_PASSWD=$(echo $SERVICE_PRICIPAL |jq .'password')


az aks create -n $AKS_CLUSTER -g $RESOURCE_GROUP -l $LOCATION --node-count 3 --service-principal $SP_APP_ID --client-secret $SP_PASSWD

# Get Kubernetes credentials
az aks get-credentials -n $AKS_CLUSTER -g $RESOURCE_GROUP

# List cluster nodes
kubectl cluster-info
kubectl config view
kubectl get nodes

#Deploy application
kubectl create secret docker-registry SECRET_NAME --docker-server=$ACR_SERVER --docker-username=$ACR_USERNAME --docker-password="$ACR_PASSWORD" --docker-email=$EMAIL
kubectl create -f azure-vote-all-in-one-redis.yaml

kubectl get service azure-vote-front --watch &
