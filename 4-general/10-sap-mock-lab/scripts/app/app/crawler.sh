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

token=$(az account get-access-token --query accessToken --output tsv)

function resolve_endpoint_dns() {
  echo -e "\n----------------------------------------"
  echo -e "Resolving endpoint DNS"
  echo -e "----------------------------------------"
  while IFS= read -r line
  do
    dns_result=$(host "$line" 2>&1)
    if echo "$dns_result" | grep -q "has address"; then
      ip_address=$(echo "$dns_result" | awk '/has address/ { print $4 }' | head -n 1)
      echo -e "$color_green $char_pass $ip_address$reset <-- $line"
    else
      echo -e "$color_red$char_fail $dns_result$reset"
    fi
  done < targets-dns.txt
}

check_access_to_management_azure() {
  echo -e "\n----------------------------------------"
  echo -e "Access to management.azure.com"
  echo -e "----------------------------------------"
  management_url="https://management.azure.com/subscriptions?api-version=2020-01-01"
  crawl_management_code=$(curl -s -o /dev/null -w "%{http_code}" -X GET "$management_url" -H "Authorization: Bearer $token")
  if [ "$crawl_management_code" -eq 200 ]; then
    echo -e "$color_green $char_pass $crawl_management_code: management.azure.com$reset"
  else
    echo -e "$color_red $char_fail $crawl_management_code: management.azure.com$reset"
  fi
}

check_data_plane_access_to_services() {
  echo -e "\n----------------------------------------"
  echo -e "Data plane access to services"
  echo -e "----------------------------------------"
  while IFS= read -r line
  do
    service_url="$line"
    crawl_service_code=$(curl -s -o /dev/null -w "%{http_code}" -X GET "$service_url")
    if [ "$crawl_service_code" -eq 200 ]; then
      echo -e "$color_green $char_pass $crawl_service_code: $service_url$reset"
    else
      echo -e "$color_red $char_fail $crawl_service_code: $service_url$reset"
    fi
  done < targets-data.txt
}

resolve_endpoint_dns
check_access_to_management_azure
check_data_plane_access_to_services

