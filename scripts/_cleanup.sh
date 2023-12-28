#!/bin/bash

char_pass="\u2714"
char_delete="\u274c"
char_question="\u2753"
char_notfound="\u26D4"
char_exclamation="\u2757"
char_celebrate="\u2B50"
char_executing="\u23F3"
char_arrow="\u279C"

# Check if a resource group name is provided
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <Resource Group>"
    exit 1
fi

LAB_ID=$1
RG="${LAB_ID}RG"
echo && echo "Resource group: $RG" && echo

delete_diag_settings() {
    local resource_type=$1
    local list_command=$2

    # Get all resources of the specified type in the resource group
    local resource_ids=$($list_command -g "$RG" --query "[].id" -o tsv)

    # Iterate over the resources and delete the diagnostic settings
    echo -e "$char_arrow  Checking $resource_type ..."
    for resource_id in $resource_ids; do
        local resource_name=$(echo $resource_id | rev | cut -d'/' -f1 | rev)
        local diag_settings=$(az monitor diagnostic-settings list --resource "$resource_id" --query "[?contains(name, '$LAB_ID')].name" -o tsv)
        for diag_setting in $diag_settings; do
            echo -e "    $char_delete Deleting: diag setting [$diag_setting] for $resource_type [$resource_name] ..."
            az monitor diagnostic-settings delete --resource "$resource_id" --name "$diag_setting"
        done
    done
}

delete_azure_policies() {
    local policy_definitions=$(az policy definition list --query "[?contains(name, '$LAB_ID')].name" -o tsv)
    for policy_definition in $policy_definitions; do
        # delete all policy assignments for the policy definition
        local policy_assignments=$(az policy assignment list --query "[?name=='$policy_definition'].name" -o tsv)
        for policy_assignment in $policy_assignments; do
            echo -e "    $char_delete Deleting: policy assignment [$policy_assignment] ..."
            az policy assignment delete --name "$policy_assignment"
        done
        echo -e "    $char_delete Deleting: policy definition [$policy_definition] ..."
        az policy definition delete --name "$policy_definition"
    done
}

delete_azfw_diag_settings() {
    delete_diag_settings "firewall" "az network firewall list"
}

delete_vnetgw_diag_settings() {
    delete_diag_settings "vnet gateway" "az network vnet-gateway list"
}

delete_vpn_gateway_diag_settings() {
    delete_diag_settings "vpn gateway" "az network vpn-gateway list"
}

delete_express_route_gateway_diag_settings() {
    delete_diag_settings "er gateway" "az network express-route gateway list"
}

delete_app_gateway_diag_settings() {
    delete_diag_settings "app gateway" "az network application-gateway list"
}

echo -e "$char_executing Checking for diagnostic settings on resources in $RG ..."
delete_azfw_diag_settings
delete_vnetgw_diag_settings
delete_vpn_gateway_diag_settings
delete_express_route_gateway_diag_settings
delete_app_gateway_diag_settings

echo -e "$char_executing Checking for azure policies in $RG ..."
delete_azure_policies

echo "Done!"
