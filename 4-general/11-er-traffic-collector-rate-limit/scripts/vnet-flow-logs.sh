#! /bin/bash

az provider register --namespace Microsoft.Insights

# Create a VNet flow log.

az network watcher flow-log create \
--location ${LOCATION} \
--resource-group ${RESOURCE_GROUP} \
--name ${NAME} \
--vnet ${VNET_NAME} \
--storage-account ${STORAGE_ACCOUNT_NAME}
--workspace ${WORKSPACE_ID} \
--interval 10 \
--traffic-analytics true
