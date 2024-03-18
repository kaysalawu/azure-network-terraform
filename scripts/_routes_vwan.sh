#!/bin/bash

rg=$1
echo -e "\nResource group: $rg\n"

usage() {
  echo "Usage: $0 <resource-group>"
  echo "-v, --vwan       Run vwan_routes function"
  echo "-h, --help       Display help"
}

vwan_routes() {
  for vhubname in `az network vhub list -g $rg --query "[].name" -o tsv`; do
    for routetableid in `az network vhub route-table list --vhub-name $vhubname -g $rg --query "[].id" -o tsv`; do
      routetablename=$(echo $routetableid | rev | cut -d'/' -f1 | rev)
      if [ "$routetablename" != "noneRouteTable" ]; then
        echo "vHub:       $vhubname"
        echo "RouteTable: $routetablename"
        echo "-------------------------------------------------------" && echo
        az network vhub get-effective-routes -g $rg -n $vhubname \
        --resource-type RouteTable \
        --resource-id $routetableid \
        --query "value[].{addressPrefixes:addressPrefixes[0], asPath:asPath, nextHopType:nextHopType}" \
        --output table
      fi
      echo
    done
    for firewallid in $(az network firewall list -g $rg --query "[?contains(virtualHub.id, '$vhubname')].id" -o tsv); do
      firewallname=$(echo $firewallid | rev | cut -d'/' -f1 | rev)
      echo "vHub:     $vhubname"
      echo "Firewall: $firewallname"
      echo "-------------------------------------------------------" && echo
      az network vhub get-effective-routes -g $rg -n $vhubname \
      --resource-type AzureFirewalls \
      --resource-id $firewallid \
      --query "value[].{addressPrefixes:addressPrefixes[0], asPath:asPath, nextHopType:nextHopType}" \
      --output table
      echo
    done
  done
}

vwan_routes

if [ -z $rg ]; then
  usage && echo
  return 1
fi


