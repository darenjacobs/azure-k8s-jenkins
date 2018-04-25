#!/bin/sh

CWD="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
LOCATION=eastus
RESOURCE_GROUP=demo-kube
AKS_CLUSTER=demo-cluster
ACR_NAME=democontainer22466
export ACR_SERVER=democontainer22466.azurecr.io
EMAIL=daren.jacobs@fhlbny.com
