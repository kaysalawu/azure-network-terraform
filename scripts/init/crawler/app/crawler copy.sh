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

echo -e "\n$boldAzure Service Crawler initiating ...$reset\n"

export METADATA=$(curl -s -H Metadata:true "http://169.254.169.254/metadata/instance?api-version=2021-02-01&format=json")
export VM_NAME=$(echo $METADATA | jq -r '.compute.name')
export RESOURCE_GROUP=$(echo $METADATA | jq -r '.compute.resourceGroupName')
export LOCATION=$(echo $METADATA | jq -r '.compute.location')
export SUBNET_NETWORK=$(echo $METADATA | jq -r '.network.interface[].ipv4.subnet[].address')
export SUBNET_MASK=$(echo $METADATA | jq -r '.network.interface[].ipv4.subnet[].prefix')

export SERVICE_TAGS_DOWNLOAD_LINK="https://download.microsoft.com/download/7/1/D/71D86715-5596-4529-9B13-DA13A5DE5B63/ServiceTags_Public_20240318.json"
export ETH0_IP=$(hostname -I | awk '{print $1}')
echo -e "* Extracting az token..."
export TOKEN=$(timeout 10 az account get-access-token --query accessToken -o tsv 2>/dev/null)
echo -e "* Getting storage account key..."
export ACCOUNT_KEY=$(timeout 10 az storage account keys list -g $RESOURCE_GROUP --account-name ${STORAGE_ACCOUNT_NAME} --query '[0].value' -o tsv 2>/dev/null)
echo "* Retrieving VNET name..."
export VNET_NAME=$(timeout 10 az network vnet list -g $RESOURCE_GROUP --query '[0].name' -o tsv 2>/dev/null)
echo "* Extracting subnet name..."
export SUBNET=$(timeout 15 python3 find_subnet.py "$ETH0_IP" 2>/dev/null)
echo -e "* Downloading service tags JSON..."
timeout 10 curl -s $SERVICE_TAGS_DOWNLOAD_LINK > service_tags.json

echo -e "\n-------------------------------------"
echo -e "Environment"
echo -e "-------------------------------------"
echo "VM Name:        $VM_NAME"
echo "Resource Group: $RESOURCE_GROUP"
echo "Location:       $LOCATION"
echo "VNET Name:      $VNET_NAME"
echo "Subnet Name:    $SUBNET"
echo "Subnet Prefix:  $SUBNET_NETWORK/$SUBNET_MASK"
echo "Private IP:     $ETH0_IP"
echo -e "-------------------------------------"

declare -a PUBLIC_ADDRESS_TYPE
declare -a SERVICE_ENDPOINTS
declare -a PRIVATE_SUBNET
declare -a INTERNET_ACCESS
declare -a MANAGEMENT_ACCESS
declare -a BLOB_ACCESS
declare -a KEYVAULT_ACCESS

function check_address_type() {
  #####################################################
  echo -e "\n1. Check Public Address Type"
  #####################################################
  local public_ip=$(timeout 10 curl -s ifconfig.me)
  echo -e "   Local IP:\t$ETH0_IP"
  echo -e "   Public IP:\t$public_ip"

  ips=$(timeout 10 az network public-ip list -g $RESOURCE_GROUP --query "[].{ip:ipAddress, name:name, id:id}" -o tsv 2>/dev/null)
  local found=0
  while IFS= read -r line; do
      ip=$(echo $line | awk '{print $1}')
      name=$(echo $line | awk '{print $2}')
      id=$(echo $line | awk '{print $3}')

      if [[ "$ip" == "$public_ip" ]]; then
          if [[ $name == *"snat-feip-pip"* ]]; then
              echo -e "   Address type: SnatIP"
              PUBLIC_ADDRESS_TYPE=("SnatIP")
          elif [[ $name == *"natgw-pip"* ]]; then
              echo -e "   Address type: NatGw"
              PUBLIC_ADDRESS_TYPE=("NatGw")
          elif [[ $name == *"nic-pip"* ]]; then
              echo -e "   Address type: VmPublicIp"
              PUBLIC_ADDRESS_TYPE=("VmPublicIp")
          else
              echo -e "   Address type: None"
              PUBLIC_ADDRESS_TYPE=("None")
          fi
          found=1
          break
      fi
  done <<< "$ips"

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
  echo -e "   Subnet --> $SUBNET"
  service_endpoints=$(az network vnet subnet show -g $RESOURCE_GROUP --vnet-name $VNET_NAME --name $SUBNET --query "serviceEndpoints[].service" -o tsv 2>/dev/null)
  if [ -z "$service_endpoints" ]; then
    echo -e "   Service EP: False"
    SERVICE_ENDPOINTS=("False")
  else
    echo -e "   Service EP: True"
    echo "$service_endpoints" | tr '\t' '\n' | awk '{print "  - " $0}'
    SERVICE_ENDPOINTS=("True")
  fi
}

function check_private_subnet() {
  subnet=$1
  #####################################################
  echo -e "\n3. Check Private Subnet"
  #####################################################
  echo -e "   Subnet --> $SUBNET"
  default_outbound_access=$(az network vnet subnet list --resource-group $RESOURCE_GROUP --vnet-name $VNET_NAME --query "[?name=='$SUBNET'].defaultOutboundAccess" -o tsv 2>/dev/null)
  if [ -z "$default_outbound_access" ];
    then default_outbound_access="true"
  fi
  echo -e "   DefaultOutbound: $default_outbound_access"

  if [ "$default_outbound_access" == "false" ]; then
    echo -e "   Private Subnet:  True"
    PRIVATE_SUBNET=True
  else
    echo -e "   Private Subnet:  False"
    PRIVATE_SUBNET=False
  fi
}

function check_internet_access() {
  #####################################################
  echo -e "\n4. Check Internet Access"
  #####################################################
  url="http://contoso.com"
  echo "   Connecting to $url ..."
  internet_access=$(timeout 10 python3 service_access.py "$url" "" 2>/dev/null)
  if [ "$internet_access" == "200" ]; then
    echo -e "   Access: Yes ($internet_access)"
    INTERNET_ACCESS="Yes"
  else
    echo -e "   Access: No ($internet_access)"
    INTERNET_ACCESS="No"
  fi
}

function resolve_dns() {
  local host=$1
  dns_result=$(host "$host" 2>/dev/null)
  if echo "$dns_result" | grep -q "has address"; then
    ip_address=$(echo "$dns_result" | awk '/has address/ { print $4 }' | head -n 1)
    echo -e  "   $ip_address <-- $host"
  else
    echo -e  "   $dns_result"
  fi
}

function get_azure_service_tag_from_host() {
  local service=$1
  local ip_address=$(host "$service" | awk '/has address/ { print $4 }' | head -n 1 2>/dev/null)
  python3 service_tags.py "$ip_address" "service_tags.json" 2>/dev/null
}

function check_management_access() {
  local service=$1
  #####################################################
  echo -e "\n5. Management (Control Plane)"
  #####################################################
  resolve_dns $service 2>/dev/null
  get_azure_service_tag_from_host $service
  local url="https://management.azure.com/subscriptions?api-version=2020-01-01"
  echo -e "   Testing access to $service"
  management_access=$(timeout 10 python3 service_access.py $url $TOKEN 2>/dev/null)

  if [ "$management_access" == "200" ]; then
    MANAGEMENT_ACCESS=Yes
    echo -e "   Access: Yes"
  else
    MANAGEMENT_ACCESS=No
    echo -e "   Access: No"
  fi
}

function download_blob() {
  local account_name=$1
  local container_name=$2
  local blob_name=$3
  #####################################################
  echo -e "\n6. Blob (Data Plane)"
  #####################################################
  local blob_url=$(az storage blob url --account-name $account_name --container-name $container_name --name $blob_name --account-key $ACCOUNT_KEY -o tsv 2>/dev/null)
  host=$(echo $blob_url | awk -F/ '{print $3}')
  echo -e "   url = $blob_url"
  echo -e "   host = $host"
  resolve_dns $host 2>/dev/null
  get_azure_service_tag_from_host $host 2>/dev/null

  echo "   Retrieving blob content ..."
  blob_access=$(az storage blob download --account-name $account_name -c $container_name -n $blob_name --account-key $ACCOUNT_KEY --query content -o tsv 2>/dev/null)
  if [ "$blob_access" = "Hello, World!" ]; then
    echo -e  "   Content: $blob_access"
    echo -e  "   Access: Yes"
    BLOB_ACCESS=Yes
  else
    echo -e  "   Blob download: failed!"
    echo -e  "   Access: No"
    BLOB_ACCESS=No
  fi
}

function access_keyvault_secret() {
  local keyvault_name=$1
  local secret_name=$2
  #####################################################
  echo -e "\n7. KeyVault (Data Plane)"
  #####################################################
  local keyvault_secret_url=$(timeout 10 az keyvault secret show --vault-name $keyvault_name --name $secret_name --query id -o tsv 2>/dev/null)
  host=$(echo $keyvault_secret_url | awk -F/ '{print $3}')
  echo -e "   url: https://$host/secrets/$secret_name/<ID>"
  echo -e "   host: $host"
  resolve_dns $host
  get_azure_service_tag_from_host $host 2>/dev/null

  echo "   Accessing secret ..."
  secret_value=$(timeout 10 az keyvault secret show --vault-name $keyvault_name --name $secret_name --query value -o tsv 2>/dev/null)
  if [ "$secret_value" = "Hello, world!" ]; then
    echo -e "   $2: $secret_value"
    echo -e "   Access: Yes"
    KEYVAULT_ACCESS=Yes
  else
    echo -e "   $2: not found!"
    echo -e "   Access: No"
    KEYVAULT_ACCESS=No
  fi
}

check_address_type
check_service_endpoints $SUBNET
check_private_subnet $SUBNET
check_internet_access
check_management_access "management.azure.com"
download_blob "${STORAGE_ACCOUNT_NAME}" "storage" "storage.txt"
access_keyvault_secret "${KEY_VAULT_NAME}" "message"
rm service_tags.json

echo -e "\n-------------------------------------"
echo -e "Results"
echo -e "-------------------------------------"
echo -e "1. NAT_IP_Type: \t$PUBLIC_ADDRESS_TYPE"
echo -e "2. Service_Endpoints: \t$SERVICE_ENDPOINTS"
echo -e "3. Private_Subnet: \t$PRIVATE_SUBNET"
echo -e "4. Internet_Access: \t$INTERNET_ACCESS"
echo -e "5. Management_Access: \t$MANAGEMENT_ACCESS"
echo -e "6. Blob_Access: \t$BLOB_ACCESS"
echo -e "7. KeyVault_Access: \t$KEYVAULT_ACCESS"
echo -e "-------------------------------------\n"
