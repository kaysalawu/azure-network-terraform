#!/bin/bash

char_pass="\u2714"
char_fail="\u274c"
char_question="\u2753"
char_notfound="\u26D4"
char_exclamation="\u2757"
char_celebrate="\u2B50"
char_executing="\u23F3"

bold=$(tput bold)
color_green=$(tput setaf 2)
color_red=$(tput setaf 1)
reset=$(tput sgr0)

echo -e "\nExtracting az token..."
export TOKEN=$(timeout 10 az account get-access-token --query accessToken -o tsv 2>/dev/null)

echo -e "Extracting metadata information ..."
metadata=$(curl -s -H Metadata:true --noproxy "*" "http://169.254.169.254/metadata/instance?api-version=2021-02-01")

# metadata
RESOURCE_GROUP=$(echo $metadata | jq -r '.compute.resourceGroupName')
LOCATION=$(echo $metadata | jq -r '.compute.location')
VM_NAME=$(echo $metadata | jq -r '.compute.name')
SUBNET_CIDR=$(echo $metadata | jq -r '.network.interface[0].ipv4.subnet[0] | "\(.address)/\(.prefix)"')
VM_ADRR=$(echo $metadata | jq -r '.network.interface[0].ipv4.ipAddress[0].privateIpAddress')

# custom metadata
SUBNET_NAME=$(echo $metadata | jq -r '.compute.tagsList[] | select(.name == "SUBNET_NAME") | .value')
VNET_NAME=$(echo $metadata | jq -r '.compute.tagsList[] | select(.name == "VNET_NAME") | .value')
MANAGEMENT_URL=$(echo $metadata | jq -r '.compute.tagsList[] | select(.name == "MANAGEMENT_URL") | .value')
STORAGE_ACCOUNT_NAME=$(echo $metadata | jq -r '.compute.tagsList[] | select(.name == "STORAGE_ACCOUNT_NAME") | .value')
STORAGE_CONTAINER_NAME=$(echo $metadata | jq -r '.compute.tagsList[] | select(.name == "STORAGE_CONTAINER_NAME") | .value')
STORAGE_BLOB_URL=$(echo $metadata | jq -r '.compute.tagsList[] | select(.name == "STORAGE_BLOB_URL") | .value')
STORAGE_BLOB_NAME=$(echo $metadata | jq -r '.compute.tagsList[] | select(.name == "STORAGE_BLOB_NAME") | .value')
STORAGE_BLOB_CONTENT=$(echo $metadata | jq -r '.compute.tagsList[] | select(.name == "STORAGE_BLOB_CONTENT") | .value')
KEY_VAULT_NAME=$(echo $metadata | jq -r '.compute.tagsList[] | select(.name == "KEY_VAULT_NAME") | .value')
KEY_VAULT_SECRET_NAME=$(echo $metadata | jq -r '.compute.tagsList[] | select(.name == "KEY_VAULT_SECRET_NAME") | .value')
KEY_VAULT_SECRET_URL=$(echo $metadata | jq -r '.compute.tagsList[] | select(.name == "KEY_VAULT_SECRET_URL") | .value')
KEY_VAULT_SECRET_VALUE=$(echo $metadata | jq -r '.compute.tagsList[] | select(.name == "KEY_VAULT_SECRET_VALUE") | .value')

download_json_file() {
  local url="https://www.microsoft.com/en-us/download/details.aspx?id=56519"
  echo "Downloading Service tags JSON file from $url ..."
  local json_url=$(curl -s "$url" | grep -oP '(?<=href=")[^"]*\.json' | head -n 1)
  if [ -n "$json_url" ]; then
    if [[ ! "$json_url" =~ ^http ]]; then
      json_url="https://www.microsoft.com$json_url"
    fi
    curl -s -o service_tags.json "$json_url"
    echo "JSON file downloaded as service_tags.json"
  else
    echo "JSON file not found on the page."
  fi
}

if [ ! -f service_tags.json ]; then
  download_json_file
else
  echo "service_tags.json already exists."
fi

echo -e "\n-------------------------------------------"
echo -e "Environment"
echo -e "-------------------------------------------"
echo "VM Name:        $VM_NAME"
echo "Subnet Name:    $SUBNET_NAME"
echo "Subnet CIDR:    $SUBNET_CIDR"
echo "Private IP:     $VM_ADRR"
echo "VNET Name:      $VNET_NAME"
echo "Location:       $LOCATION"
echo -e "-------------------------------------------"

declare -a PUBLIC_ADDRESS_TYPE
declare -a PUBLIC_ADDRESS
declare -a SERVICE_ENDPOINT_STATUS
declare -a SERVICE_ENDPOINTS
declare -a PRIVATE_SUBNET
declare -a INTERNET_ACCESS
declare -a MANAGEMENT_ACCESS
declare -a BLOB_ACCESS
declare -a KEYVAULT_ACCESS

function resolve_dns() {
  local host=$1
  dns_result=$(host "$host" 2>/dev/null)
  if echo "$dns_result" | grep -q "has address"; then
    ip_address=$(echo "$dns_result" | awk '/has address/ { print $4 }' | head -n 1)
    echo -e "   $ip_address <-- $host"
  else
    echo -e "   $dns_result"
  fi
}

function get_azure_service_tag_from_host() {
  local host=$1
  local ip_address=$(host "$host" | awk '/has address/ { print $4 }' | head -n 1 2>/dev/null)
  echo -e "   Searching for service tags matching IP ($ip_address)"
  python3 service_tags.py "$ip_address" "service_tags.json" 2>/dev/null
}

function check_address_type() {
  #####################################################
  echo -e "\n1. Check Public Address Type"
  #####################################################
  local internet_url="http://ifconfig.me/ip"
  local public_ip=$(timeout 10 curl -s $internet_url)
  echo -e "   Local IP:\t$VM_ADRR"
  echo -e "   Public IP:\t$public_ip"

  ips=$(timeout 10 az network public-ip list -g $RESOURCE_GROUP --query "[].{ip:ipAddress, name:name, id:id}" -o tsv)
  local found=0
  while IFS= read -r line; do
    ip=$(echo $line | awk '{print $1}')
    name=$(echo $line | awk '{print $2}')
    id=$(echo $line | awk '{print $3}')

    if [[ "$ip" == "$public_ip" ]]; then
      PUBLIC_ADDRESS="$name"
      found=1
      break
    fi
  done <<<"$ips"

  if [[ $found -eq 0 ]]; then
    PUBLIC_ADDRESS_TYPE=("None")
    echo -e "   NAT_IP type:\tNone"
  fi
}

function check_service_endpoints() {
  subnet=$1
  #####################################################
  echo -e "\n2. Check Service Endpoints"
  #####################################################
  echo -e "   Subnet --> $SUBNET_NAME"
  if ! service_endpoints=$(timeout 10 az network vnet subnet show -g $RESOURCE_GROUP --vnet-name $VNET_NAME --name "$SUBNET_NAME" --query "serviceEndpoints[].service" -o tsv 2>/dev/null); then
    echo -e "   Service Endpoint: Timed out!"
    SERVICE_ENDPOINT_STATUS=("Timed out!")
  elif [ -z "$service_endpoints" ]; then
    echo -e "   Service Endpoint: Disabled"
    SERVICE_ENDPOINT_STATUS=("Disabled")
  else
    endpoints=$(echo "$service_endpoints" | tr '\t' ', ')
    echo -e "   Service Endpoint: Enabled ($endpoints)"
    SERVICE_ENDPOINT_STATUS=("Enabled")
    SERVICE_ENDPOINTS=($service_endpoints)
  fi
}

function check_private_subnet() {
  #####################################################
  echo -e "\n3. Check Private Subnet"
  #####################################################
  echo -e "   Subnet --> $SUBNET_NAME"
  if ! default_outbound_access=$(timeout 10 az network vnet subnet list --resource-group $RESOURCE_GROUP --vnet-name $VNET_NAME --query "[?name=='$SUBNET_NAME'].defaultOutboundAccess" -o tsv 2>/dev/null); then
    echo -e "   DefaultOutbound: Timed out!"
    default_outbound_access="Timed out!"
  fi
  if [ "$default_outbound_access" == "Timed out!" ]; then
    echo -e "   Private Subnet:  Timed out!"
    PRIVATE_SUBNET="Timed out!"
  elif [ "$default_outbound_access" == "true" ]; then
    echo -e "   Private Subnet:  Disabled"
    PRIVATE_SUBNET=Disabled
  elif [ "$default_outbound_access" == "false" ]; then
    echo -e "   Private Subnet:  Enabled"
    PRIVATE_SUBNET=Enabled
  else
    echo -e "   Private Subnet:  "
    PRIVATE_SUBNET=
  fi
}

function check_internet_access() {
  #####################################################
  echo -e "\n4. Check Internet Access"
  #####################################################
  url="https://ifconfig.me"
  echo "   curl $url"
  if ! internet_access_code=$(timeout 10 curl -o /dev/null -s -w "%%{http_code}\n" $url); then
    echo -e "   Internet Access: Timed out!"
    INTERNET_ACCESS="Timed out!"
  elif [[ "$internet_access_code" =~ ^2 ]] || [[ "$internet_access_code" =~ ^3 ]]; then
    echo -e "   Internet Access: Pass ($internet_access_code)"
    INTERNET_ACCESS="Pass"
  else
    echo -e "   Internet Access: Fail ($internet_access_code)"
    INTERNET_ACCESS="Fail"
  fi
}

function check_management_access() {
  #####################################################
  echo -e "\n5. Management (Control Plane)"
  #####################################################
  local host=$(echo $MANAGEMENT_URL | awk -F/ '{print $3}')
  echo -e "   url = $MANAGEMENT_URL"
  echo -e "   host = $host"
  resolve_dns $host 2>/dev/null
  get_azure_service_tag_from_host $host 2>/dev/null

  echo -e "   curl -H "Authorization : Bearer TOKEN" $MANAGEMENT_URL"
  if ! management_access_code=$(timeout 10 curl -o /dev/null -s -w "%%{http_code}\n" -H "Authorization : Bearer $TOKEN" $MANAGEMENT_URL); then
    echo -e "   Management Access: Timed out!"
    MANAGEMENT_ACCESS="Timed out!"
  elif [[ "$management_access_code" =~ ^2 ]] || [[ "$management_access_code" =~ ^3 ]]; then
    echo -e "   Management Access: Pass ($management_access_code)"
    MANAGEMENT_ACCESS="Pass"
  else
    echo -e "   Management Access: Fail ($management_access_code)"
    MANAGEMENT_ACCESS="Fail"
  fi
}

function download_blob() {
  #####################################################
  echo -e "\n6. Blob (Data Plane)"
  #####################################################
  local host=$(echo $STORAGE_BLOB_URL | awk -F/ '{print $3}')
  echo -e "   url = $STORAGE_BLOB_URL"
  echo -e "   host = $host"
  resolve_dns $host 2>/dev/null
  get_azure_service_tag_from_host $host 2>/dev/null
  storage_account_key=""
  storage_access_token=""
  blob_access=""
  echo -e "   az storage account keys list -g $RESOURCE_GROUP --account-name $STORAGE_ACCOUNT_NAME"
  if storage_account_key=$(timeout 10 az storage account keys list -g $RESOURCE_GROUP --account-name $STORAGE_ACCOUNT_NAME --query "[0].value" -o tsv 2>/dev/null); then
    echo "   az storage blob download --account-name $STORAGE_ACCOUNT_NAME -c $STORAGE_CONTAINER_NAME -n $STORAGE_BLOB_NAME --account-key <KEY>"
    blob_access=$(timeout 10 az storage blob download --account-name $STORAGE_ACCOUNT_NAME -c $STORAGE_CONTAINER_NAME -n $STORAGE_BLOB_NAME --account-key $storage_account_key --query content -o tsv 2>/dev/null)
  else
    echo -e "   Storage account key: timed out!"
    echo -e "   Fallback: Get access token for storage.azure.com via metadata ..."
    if ! storage_access_token=$(timeout 10 curl -H Metadata:true "http://169.254.169.254:80/metadata/identity/oauth2/token?resource=https%3A%2F%2Fstorage.azure.com&api-version=2018-02-01" -s | jq -r .access_token); then
      echo -e "   Storage access token: timed out!"
    else
      echo "   curl https://$STORAGE_ACCOUNT_NAME.blob.core.windows.net/$STORAGE_CONTAINER_NAME/$STORAGE_BLOB_NAME ..."
      blob_access=$(timeout 10 curl -s -H "Cache-Control: no-cache" -H "Pragma: no-cache" -H "x-ms-version: 2019-02-02" -H "Authorization: Bearer $storage_access_token" "https://$STORAGE_ACCOUNT_NAME.blob.core.windows.net/$STORAGE_CONTAINER_NAME/$STORAGE_BLOB_NAME")
    fi
  fi

  if [ "$blob_access" = "$STORAGE_BLOB_CONTENT" ]; then
    echo -e "   Content: $blob_access"
    echo -e "   Blob Dataplane: Pass"
    BLOB_ACCESS=Pass
  else
    echo -e "   Blob Dataplane: Fail"
    BLOB_ACCESS=Fail
  fi
}

function access_keyvault_secret() {
  #####################################################
  echo -e "\n7. KeyVault (Data Plane)"
  #####################################################
  local host=$(echo $KEY_VAULT_SECRET_URL | awk -F/ '{print $3}')
  echo -e "   url: $KEY_VAULT_SECRET_URL"
  echo -e "   host: $host"
  resolve_dns $host
  get_azure_service_tag_from_host $host 2>/dev/null
  secret_value=""
  vault_access_token=""
  echo "   az keyvault secret show --vault-name $KEY_VAULT_NAME --name $KEY_VAULT_SECRET_NAME"
  if ! secret_value=$(timeout 10 az keyvault secret show --vault-name $KEY_VAULT_NAME --name $KEY_VAULT_SECRET_NAME --query value -o tsv 2>/dev/null); then
    echo -e "   $KEY_VAULT_SECRET_NAME: timed out!"
    echo -e "   Fallback: Get access token for vault.azure.net via metadata ..."
    if ! vault_access_token=$(timeout 10 curl -H Metadata:true "http://169.254.169.254/metadata/identity/oauth2/token?resource=https%3A%2F%2Fvault.azure.net&api-version=2018-02-01" -s | jq -r .access_token); then
      echo -e "   Vault token: timed out!"
    else
      echo "curl https://$KEY_VAULT_NAME.vault.azure.net/secrets/message?api-version=7.2"
      secret_value=$(timeout 10 curl -H "Cache-Control: no-cache" -H "Pragma: no-cache" -H "Authorization : Bearer $vault_access_token" "https://$KEY_VAULT_NAME.vault.azure.net/secrets/message?api-version=7.2" -o secret.txt 2>/dev/null)
    fi
  fi

  if [ "$secret_value" = "$KEY_VAULT_SECRET_VALUE" ]; then
    echo -e "   $KEY_VAULT_SECRET_NAME: $secret_value"
    echo -e "   Vault Dataplane: Pass"
    KEYVAULT_ACCESS=Pass
  else
    echo -e "   $KEY_VAULT_SECRET_NAME: not found!"
    echo -e "   Vault Dataplane: Fail"
    KEYVAULT_ACCESS=Fail
  fi
}

check_address_type
check_service_endpoints "$SUBNET_NAME"
check_private_subnet "$SUBNET_NAME"
check_internet_access
check_management_access
download_blob
access_keyvault_secret

echo -e "\n-------------------------------------------"
echo -e "Results"
echo -e "-------------------------------------------"
echo -e "1. Public IP: \t$PUBLIC_ADDRESS"
echo -e "2. Service Endpoints: \t$SERVICE_ENDPOINT_STATUS ($SERVICE_ENDPOINTS)"
echo -e "3. Private Subnet: \t$PRIVATE_SUBNET"
echo -e "4. Internet Access: \t$INTERNET_ACCESS"
echo -e "5. Management Access: \t$MANAGEMENT_ACCESS"
echo -e "6. Blob Dataplane: \t$BLOB_ACCESS"
echo -e "7. KeyVault Dataplane: \t$KEYVAULT_ACCESS"
echo -e "-------------------------------------------\n"
