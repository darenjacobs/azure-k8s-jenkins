#!/bin/sh

LOCATION=eastus
RG_NAME=demo-kube
ACS_NAME=demo-cluster
ACR_NAME=democontainer$RANDOM
EMAIL=daren.jacobs@fhlbny.com


if ! [ -f azr-creds.sh ]; then
  echo "azr-creds.sh file not found"
  echo "Exiting program!"
  exit 1
fi

# Create Resource Group
az group create -n $RG_NAME -l $LOCATION

# Create Kubernetes Cluster
az aks create -n $ACS_NAME -g $RG_NAME -l $LOCATION --ssh-key-value $HOME/.ssh/id_rsa.pub --node-count 3

# Get Kubernetes credentials
az aks get-credentials -n $ACS_NAME -g $RG_NAME

az acr create -n $ACR_NAME -g $RG_NAME --sku Basic

az acr login -n $ACR_NAME

# List cluster nodes
kubectl cluster-info
kubectl config view
kubectl get nodes

CLIENT_ID=$(az aks show -n $ACS_NAME -g $RG_NAME --query "servicePrincipalProfile.clientId" --output tsv)

ACR_ID=$(az acr show -n $ACR_NAME -g $RG_NAME --query "id" --output tsv)

MASTER0=$(az aks show -g $RG_NAME -n $ACS_NAME --query masterProfile.fqdn -o tsv)

ssh azureuser@$MASTER0

# Delete when it's done
# az group delete --name $RG_NAME --yes --no-wait
