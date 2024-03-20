#!/bin/bash

char_pass="\u2714"
char_fail="\u274c"
char_question="\u2753"
char_notfound="\u26D4"
char_exclamation="\u2757"
char_celebrate="\u2B50"
char_executing="\u23F3"

color_green=$(tput setaf 2)
color_red=$(tput setaf 1)
reset=$(tput sgr0)

export TOKEN=$(az account get-access-token --query accessToken --output tsv)
export ACCOUNT_KEY=$(az storage account keys list -g G10_SapNetworking_RG --account-name g10ecssa4237 --query '[0].value' --output tsv)
export SUBSCRIPTION_ID=$(az account show --query id --output tsv)

function resolve_dns() {
  local host=$1
  dns_result=$(host "$host" 2>&1)
  if echo "$dns_result" | grep -q "has address"; then
    ip_address=$(echo "$dns_result" | awk '/has address/ { print $4 }' | head -n 1)
    echo -e  "  $ip_address <-- $host"
  else
    echo -e  "  $dns_result"
  fi
}

function get_azure_service_tag_from_host() {
  local service=$1
  local ip_address=$(host "$service" | awk '/has address/ { print $4 }' | head -n 1)
  python3 service_tags.py $ip_address westeurope
}

function check_access_to_service() {
  local service=$1
  echo -e "\n----------------------------------------"
  echo -e "Access to $service"
  echo -e "----------------------------------------"
  resolve_dns $service
  get_azure_service_tag_from_host $service
  management_url="https://management.azure.com/subscriptions?api-version=2020-01-01"
  echo -e "* Testing access to $service"
  python3 service_access.py $management_url $TOKEN
}

function download_blob() {
  local account_name=$1
  local container_name=$2
  local blob_name=$3
  echo -e "\n----------------------------------------"
  echo -e "Blob (data plane)"
  echo -e "----------------------------------------"
  local blob_url=$(az storage blob url --account-name $account_name --container-name $container_name --name $blob_name --account-key $ACCOUNT_KEY --output tsv)
  host=$(echo $blob_url | awk -F/ '{print $3}')
  echo -e "  url: $blob_url"
  echo -e "  host: $host"
  resolve_dns $host
  get_azure_service_tag_from_host $host

  echo "* az storage blob download --account-name $account_name --container-name $container_name --name $blob_name --file './storage.txt'"
  az storage blob download --account-name $account_name --container-name $container_name --name $blob_name --account-key $ACCOUNT_KEY --file "./storage.txt" > /dev/null 2>&1
  if [ -s "./storage.txt" ]; then
    echo -e  "  $char_pass Content: $(cat storage.txt)"
    rm ./storage.txt
  else
    echo -e  "  $char_fail Blob download: failed!"
  fi
}

function access_keyvault_secret() {
  local keyvault_name=$1
  local secret_name=$2
  echo -e "\n----------------------------------------"
  echo -e "Key Vault (data plane)"
  echo -e "----------------------------------------"
  local keyvault_secret_url=$(az keyvault secret show --vault-name $keyvault_name --name $secret_name --query id --output tsv)
  host=$(echo $keyvault_secret_url | awk -F/ '{print $3}')
  echo -e "  url: https://$host/secrets/$secret_name/<ID>"
  echo -e "  host: $host"
  resolve_dns $host
  get_azure_service_tag_from_host $host

  echo "* az keyvault secret show --vault-name $keyvault_name --name $secret_name --query value --output tsv"
  secret_value=$(az keyvault secret show --vault-name $keyvault_name --name $secret_name --query value --output tsv)
  if [ -n "$secret_value" ]; then
    echo -e "  $char_pass $2: $secret_value"
  else
    echo -e "  $char_fail $2: not found!"
  fi
}

check_access_to_service "management.azure.com"
download_blob "g10ecssa4237" "storage" "storage.txt"
access_keyvault_secret G10-ecs-kv4237 message
