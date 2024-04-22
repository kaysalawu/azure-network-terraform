#!/bin/bash

# Define services and their corresponding Azure CLI commands to check access
services=(
    "Microsoft.Storage:az storage account list"
    "Microsoft.Sql:az sql server list"
    "Microsoft.KeyVault:az keyvault list"
    "Microsoft.ServiceBus:az servicebus namespace list"
    "Microsoft.EventHub:az eventhubs namespace list"
    "Microsoft.AzureActiveDirectory:az ad app list"
    "Microsoft.Web:az webapp list"
    "Microsoft.CognitiveServices:az cognitiveservices account list"
    "Microsoft.ContainerRegistry:az acr repository list"
)

# Loop through each service and execute the command
for service in "${services[@]}"; do
    IFS=":" read -r serviceName command <<< "$service"
    if $command --query [].name -o tsv > /dev/null 2>&1; then
        echo "200: $serviceName"
    else
        echo "Error accessing $serviceName"
    fi
done

# ApiManagement.WestEurope
# AppService.WestEurope
# AzureCloud.westeurope
# AzureConnectors.WestEurope
# AzureContainerRegistry.WestEurope
# AzureCosmosDB.WestEurope
# AzureKeyVault.WestEurope
# BatchNodeManagement.WestEurope
# DataFactory.WestEurope
# EventHub.WestEurope
# HDInsight.WestEurope
# MicrosoftContainerRegistry.WestEurope
# PowerPlatformInfra.WestEurope
# PowerPlatformPlex.WestEurope
# ServiceBus.WestEurope
# Sql.WestEurope
