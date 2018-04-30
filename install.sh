#!/bin/sh

set -euo pipefail

CWD="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
LOCATION=eastus
RESOURCE_GROUP=demo-kube
AKS_CLUSTER=demo-cluster
ACR_NAME=demoacr$RANDOM
EMAIL=daren.jacobs@fhlbny.com

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
az acr create -n $ACR_NAME -g $RESOURCE_GROUP --sku Basic

# Container registry login
az acr login -n $ACR_NAME

# Tag container images
docker images

export ACR_SERVER=$(az acr list -g $RESOURCE_GROUP --query "[].{acrLoginServer:loginServer}" --output tsv)

docker tag azure-vote-front ${ACR_SERVER}/azure-vote-front:v1
docker images

# Push images to registry
docker push ${ACR_SERVER}/azure-vote-front:v1

# List imags in registry
az acr repository list --name ${ACR_NAME} --output table
az acr repository show-tags --name ${ACR_NAME} --repository azure-vote-front --output table




# Create Kubernetes Cluster
az provider register -n Microsoft.Network
az provider register -n Microsoft.Storage
az provider register -n Microsoft.Compute
az provider register -n Microsoft.ContainerService
az aks create -n $AKS_CLUSTER -g $RESOURCE_GROUP -l $LOCATION --node-count 3 --ssh-key-value $HOME/.ssh/id_rsa.pub

# Get Kubernetes credentials
az aks get-credentials -n $AKS_CLUSTER -g $RESOURCE_GROUP

# List cluster nodes
kubectl cluster-info
kubectl config view
kubectl get nodes

CLIENT_ID=$(az aks show -n $AKS_CLUSTER -g $RESOURCE_GROUP --query "servicePrincipalProfile.clientId" --output tsv)

ACR_ID=$(az acr show -n $ACR_NAME -g $RESOURCE_GROUP --query "id" --output tsv)

# Create role assignment Gives an error
az role assignment create --assignee $CLIENT_ID --role Reader --scope $ACR_ID


#Deploy application
kubectl create -f azure-vote-all-in-one-redis.yaml

kubectl get service azure-vote-front --watch &
