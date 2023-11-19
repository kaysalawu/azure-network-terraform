#!/bin/bash

# Check if a resource group name is provided
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <Resource Group>"
    exit 1
fi

RG=$1
echo && echo "Resource group: $RG" && echo

delete_azfw_diag_settings() {
    # Get all firewalls in the specified resource group
    firewallids=$(az network firewall list -g "$RG" --query "[].id" -o tsv)

    # Iterate over the firewalls and delete the diagnostic settings
    for firewallid in $firewallids; do
        firewallname=$(echo $firewallid | rev | cut -d'/' -f1 | rev)
        azfw_diag_settings=$(az monitor diagnostic-settings list --resource "$firewallid" --query "[].name" -o tsv)
        for azfw_diag_setting in $azfw_diag_settings; do
            echo "Deleting: diag setting [$azfw_diag_setting] for firewall [$firewallname] ..."
            az monitor diagnostic-settings delete --resource "$firewallid" --name "$azfw_diag_setting"
        done
    done
    echo "Deletion complete!" && echo
}

delete_azfw_diag_settings
