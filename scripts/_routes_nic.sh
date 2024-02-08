#!/bin/bash

rg=$1
echo -e "\nResource group: $rg\n"

usage() {
  echo "Usage: $0 <resource-group>"
  echo "-v, --vwan       Run vwan_routes function"
  echo "-h, --help       Display help"
}

if [ -z $rg ]; then
  usage && echo
  return 1
fi

nic_effective_routes() {
  mapfile -t nics < <(az network nic list -g "$rg" --query '[].name' -o tsv)
  echo "Available NICs:"
  for i in "${!nics[@]}"; do
    echo "$((i+1)). ${nics[i]}"
  done
  echo -e "\nSelect NIC to view effective routes (enter the number)\n"
  read -rp "Selection: " selection
  selected_nic=${nics[$((selection-1))]}
  echo -e "\nEffective routes for $selected_nic\n"
  az network nic show-effective-route-table -g "$rg" -n "$selected_nic" --query 'value[?nextHopType!=`None`].{Source:source, Prefix:addressPrefix[0], State:state, NextHopType:nextHopType, NextHopIP:nextHopIpAddress[0]}' -o table
  echo -e "\n"
}

nic_effective_routes
