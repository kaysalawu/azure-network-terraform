#!/bin/bash

RG=$1
echo -e "\nResource group: $RG\n"

for firewallid in $(az network firewall list -g $RG --query "[?contains(virtualHub.id, '$vhubname')].id" -o tsv); do
    firewallname=$(echo $firewallid | rev | cut -d'/' -f1 | rev)
    echo "vHub:       $vhubname"
    echo "Firewall:   $firewallname"
    echo "Diagnostic: $AzfwDiagnosticSetting"
    echo "-------------------------------------------------------" && echo
    az network vhub get-effective-routes -g $RG -n $vhubname \
    --resource-type AzureFirewalls \
    --resource-id $firewallid \
    --query "value[].{addressPrefixes:addressPrefixes[0], asPath:asPath, nextHopType:nextHopType}" \
    --output table
    echo
done

#AzfwDiagnosticSetting=$()
