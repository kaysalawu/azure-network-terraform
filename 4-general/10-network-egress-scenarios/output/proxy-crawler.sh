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
export SUBSCRIPTION_ID=$(echo $METADATA | jq -r '.compute.subscriptionId')
export RESOURCE_GROUP=$(echo $METADATA | jq -r '.compute.resourceGroupName')

export ETH0_IP=$(hostname -I | awk '{print $1}')
echo -e "* Extracting az token..."
export TOKEN=$(timeout 10 az account get-access-token --query accessToken -o tsv 2>/dev/null)
echo -e "* Downloading service tags JSON..."
if [ ! -f service_tags.json ]; then
  curl -o service_tags.json "https://download.microsoft.com/download/7/1/D/71D86715-5596-4529-9B13-DA13A5DE5B63/ServiceTags_Public_20240318.json" 2>/dev/null
fi

echo -e "\n-------------------------------------"
echo -e "Environment"
echo -e "-------------------------------------"
echo "VM Name:        G10-Proxy"
echo "Resource Group: $RESOURCE_GROUP"
echo "Location:       northeurope"
echo "VNET Name:      G10-hub-vnet"
echo "Subnet Name:    PublicSubnet"
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
  local internet_url="http://ifconfig.me/ip"
  local public_ip=$(timeout 10 curl -s $internet_url)
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
  echo -e "   Subnet --> PublicSubnet"
  service_endpoints=$(timeout 10 az network vnet subnet show -g $RESOURCE_GROUP --vnet-name G10-hub-vnet --name "PublicSubnet" --query "serviceEndpoints[].service" -o tsv 2>/dev/null)
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
  #####################################################
  echo -e "\n3. Check Private Subnet"
  #####################################################
  echo -e "   Subnet --> PublicSubnet"
  default_outbound_access=$(timeout 10 az network vnet subnet list --resource-group $RESOURCE_GROUP --vnet-name G10-hub-vnet --query "[?name=='PublicSubnet'].defaultOutboundAccess" -o tsv 2>/dev/null)
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
  url="https://ifconfig.me"
  echo "   Connecting to $url ..."
  internet_access=$(timeout 10 curl -o /dev/null -s -w "%{http_code}\n" $url)
  if [[ "$internet_access" =~ ^2 ]] || [[ "$internet_access" =~ ^3 ]]; then
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
  #####################################################
  echo -e "\n5. Management (Control Plane)"
  #####################################################
  local host=$(echo https://management.azure.com/subscriptions?api-version=2020-01-01 | awk -F/ '{print $3}')
  echo -e "   url = https://management.azure.com/subscriptions?api-version=2020-01-01"
  echo -e "   host = $host"
  resolve_dns $host 2>/dev/null
  get_azure_service_tag_from_host $host 2>/dev/null

  echo -e "   Testing access to $host"
  management_access=$(timeout 10 curl -o /dev/null -s -w "%{http_code}\n" -H "Authorization : Bearer $TOKEN" https://management.azure.com/subscriptions?api-version=2020-01-01)
  if [[ "$management_access" =~ ^2 ]] || [[ "$management_access" =~ ^3 ]]; then
    echo -e "   Access: Yes ($management_access)"
    MANAGEMENT_ACCESS="Yes"
  else
    echo -e "   Access: No ($management_access)"
    MANAGEMENT_ACCESS="No"
  fi
}

function download_blob() {
  #####################################################
  echo -e "\n6. Blob (Data Plane)"
  #####################################################
  local host=$(echo https://g10hub99a2.blob.core.windows.net/storage/storage.txt | awk -F/ '{print $3}')
  echo -e "   url = https://g10hub99a2.blob.core.windows.net/storage/storage.txt"
  echo -e "   host = $host"
  resolve_dns $host 2>/dev/null
  get_azure_service_tag_from_host $host 2>/dev/null

  echo "   Retrieving blob content ..."
  blob_access=$(timeout 10 az storage blob download --account-name g10hub99a2 -c storage -n storage.txt --query content -o tsv 2>/dev/null)
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
  #####################################################
  echo -e "\n7. KeyVault (Data Plane)"
  #####################################################
  local host=$(echo https://g10-hub-kv99a2.vault.azure.net/secrets/message | awk -F/ '{print $3}')
  echo -e "   url: https://g10-hub-kv99a2.vault.azure.net/secrets/message"
  echo -e "   host: $host"
  resolve_dns $host
  get_azure_service_tag_from_host $host 2>/dev/null

  echo "   Accessing secret ..."
  secret_value=$(timeout 10 az keyvault secret show --vault-name g10-hub-kv99a2 --name message --query value -o tsv 2>/dev/null)
  if [ "$secret_value" = "Hello, World!" ]; then
    echo -e "   message: $secret_value"
    echo -e "   Access: Yes"
    KEYVAULT_ACCESS=Yes
  else
    echo -e "   message: not found!"
    echo -e "   Access: No"
    KEYVAULT_ACCESS=No
  fi
}

check_address_type
check_service_endpoints "PublicSubnet"
check_private_subnet "PublicSubnet"
check_internet_access
check_management_access
download_blob
access_keyvault_secret

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
