#!/bin/bash

token=$(az account get-access-token --query accessToken --output tsv)
crawl_management_code=$(curl -s -o /dev/null -w "%%{http_code}" -X GET "https://management.azure.com/subscriptions?api-version=2020-01-01" -H "Authorization: Bearer $token")
echo "$crawl_management_code: management.azure.com"

function dig_endpoints() {
  while IFS= read -r line
  do
    ip_address=$(host "$line" | awk '/has address/ { print $4 }' | head -n 1)
    echo "$ip_address: $line"
  done < targets.txt
}

dig_endpoints

