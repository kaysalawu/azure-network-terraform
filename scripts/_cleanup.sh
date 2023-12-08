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
    echo "Checking for diagnostic settings on vnet gateway ..."
    for vnetgwid in $vnetgwids; do
        vnetgwname=$(echo $vnetgwid | rev | cut -d'/' -f1 | rev)
        vnetgw_diag_settings=$(az monitor diagnostic-settings list --resource "$vnetgwid" --query "[].name" -o tsv)
        for vnetgw_diag_setting in $vnetgw_diag_settings; do
            echo "Deleting: diag setting [$vnetgw_diag_setting] for vnetgw [$vnetgwname] ..."
            az monitor diagnostic-settings delete --resource "$vnetgwid" --name "$vnetgw_diag_setting"
        done
    done
}

delete_vpn_gateway_diag_settings(){
    # Get all vpn gateway in the specified resource group
    vpngatewayids=$(az network vpn-gateway list -g "$RG" --query "[].id" -o tsv)

    # Iterate over the vpn gateway and delete the diagnostic settings
    echo "Checking for diagnostic settings on vpn gateway ..."
    for vpngatewayid in $vpngatewayids; do
        vpngatewayname=$(echo $vpngatewayid | rev | cut -d'/' -f1 | rev)
        vpngateway_diag_settings=$(az monitor diagnostic-settings list --resource "$vpngatewayid" --query "[].name" -o tsv)
        for vpngateway_diag_setting in $vpngateway_diag_settings; do
            echo "Deleting: diag setting [$vpngateway_diag_setting] for vpn gateway [$vpngatewayname] ..."
            az monitor diagnostic-settings delete --resource "$vpngatewayid" --name "$vpngateway_diag_setting"
        done
    done
}

delete_er_gateway_diag_settings(){
    # Get all er gateway in the specified resource group
    ergatewayids=$(az network express-route gateway list -g "$RG" --query "[].id" -o tsv)

    # Iterate over the er gateway and delete the diagnostic settings
    echo "Checking for diagnostic settings on er gateway ..."
    for ergatewayid in $ergatewayids; do
        ergatewayname=$(echo $ergatewayid | rev | cut -d'/' -f1 | rev)
        ergateway_diag_settings=$(az monitor diagnostic-settings list --resource "$ergatewayid" --query "[].name" -o tsv)
        for ergateway_diag_setting in $ergateway_diag_settings; do
            echo "Deleting: diag setting [$ergateway_diag_setting] for er gateway [$ergatewayname] ..."
            az monitor diagnostic-settings delete --resource "$ergatewayid" --name "$ergateway_diag_setting"
        done
    done
}

delete_azfw_diag_settings
delete_vnetgw_diag_settings
delete_vpn_gateway_diag_settings
delete_er_gateway_diag_settings
echo "Done!"

