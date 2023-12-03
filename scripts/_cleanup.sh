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
    echo "Checking for diagnostic settings on firewalls ..."
    for firewallid in $firewallids; do
        firewallname=$(echo $firewallid | rev | cut -d'/' -f1 | rev)
        azfw_diag_settings=$(az monitor diagnostic-settings list --resource "$firewallid" --query "[].name" -o tsv)
        for azfw_diag_setting in $azfw_diag_settings; do
            echo "Deleting: diag setting [$azfw_diag_setting] for firewall [$firewallname] ..."
            az monitor diagnostic-settings delete --resource "$firewallid" --name "$azfw_diag_setting"
        done
    done
}

delete_vnetgw_diag_settings(){
    # Get all vnetgw in the specified resource group
    vnetgwids=$(az network vnet-gateway list -g "$RG" --query "[].id" -o tsv)

    # Iterate over the vnetgw and delete the diagnostic settings
    echo "Checking for diagnostic settings on vnetgw ..."
    for vnetgwid in $vnetgwids; do
        vnetgwname=$(echo $vnetgwid | rev | cut -d'/' -f1 | rev)
        vnetgw_diag_settings=$(az monitor diagnostic-settings list --resource "$vnetgwid" --query "[].name" -o tsv)
        for vnetgw_diag_setting in $vnetgw_diag_settings; do
            echo "Deleting: diag setting [$vnetgw_diag_setting] for vnetgw [$vnetgwname] ..."
            az monitor diagnostic-settings delete --resource "$vnetgwid" --name "$vnetgw_diag_setting"
        done
    done
}

delete_azfw_diag_settings
delete_vnetgw_diag_settings
echo "Done!"

