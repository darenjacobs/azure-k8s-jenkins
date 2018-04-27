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
