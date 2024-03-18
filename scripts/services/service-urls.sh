#!/bin/bash

# Run Azure CLI command with --debug flag and capture URLs in real time
az group list --debug 2>&1 | grep --line-buffered -oP 'msrest.http_logger : Request URL: \K(https?://[^\s]+)' | uniq

endpoint=$(az storage blob url --account-name <StorageAccountName> --container-name <ContainerName> --name <BlobName> --output tsv)
sas_token=$(az storage blob generate-sas --account-name <StorageAccountName> --container-name <ContainerName> --name <BlobName> --permissions r --expiry <ExpiryDate> --output tsv)
curl "${endpoint}?${sas_token}"
