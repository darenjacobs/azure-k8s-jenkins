#!/bin/sh

set -euo pipefail

CWD="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
LOCATION=eastus
RESOURCE_GROUP=demo-kube
AKS_CLUSTER=demo-cluster
ACR_NAME=democontainer22466
SERVICE_PRINCIPAL_NAME=acr1-service-principal
EMAIL=daren.jacobs@fhlbny.com

# Populate the ACR login server and resource id.
ACR_LOGIN_SERVER=$(az acr show --name $ACR_NAME --query loginServer --output tsv)
ACR_REGISTRY_ID=$(az acr show --name $ACR_NAME --query id --output tsv)

# Create a contributor role assignment with a scope of the ACR resource.
SP_PASSWD=$(az ad sp create-for-rbac --name $SERVICE_PRINCIPAL_NAME --role Reader --scopes $ACR_REGISTRY_ID --query password --output tsv)

# Get the service principle client id.
CLIENT_ID=$(az ad sp show --id http://$SERVICE_PRINCIPAL_NAME --query appId --output tsv)

# Output used when creating Kubernetes secret.
echo "Service principal ID: $CLIENT_ID"
echo "Service principal password: $SP_PASSWD"

kubectl create secret docker-registry acr-auth --docker-server ${ ACR_LOGIN_SERVER} --docker-username ${SERVICE_PRINCIPAL_NAME} --docker-password ${SP_PASSWD} --docker-email ${EMAIL}
