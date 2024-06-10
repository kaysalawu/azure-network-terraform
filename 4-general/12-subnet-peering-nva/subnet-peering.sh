
# az network vnet peering create -g PG11_HubSpoke_1Region_RG \
# -n spoke1-to-hub1 \
# --vnet-name PG11-spoke1-vnet \
# --remote-vnet PG11-hub1-vnet \
# --allow-vnet-access \
# --peer-complete-vnet 0

access_token=$(az account get-access-token --query accessToken -o tsv)
sub_id=$(az account show --query id -o tsv)

function create_subnet_peering() {
local rg=$1
local local_vnet=$2
local remote_vnet=$3
curl -s -X PUT "https://management.azure.com/subscriptions/${sub_id}/resourceGroups/${rg}/providers/Microsoft.Network/virtualNetworks/${local_vnet}/virtualNetworkPeerings/sub--${local_vnet}--${remote_vnet}?syncRemoteAddressSpace=true&api-version=2023-11-01" \
     -H "Authorization: Bearer $access_token" \
     -H "Content-Type: application/json" \
     -d '{
        "properties": {
            "localSubnetNames": ["UntrustSubnet"],
            "remoteSubnetNames": ["UntrustSubnet"],
            "peerCompleteVnets": false,
            "enableOnlyIpv6Peering": false,
            "useRemoteGateways": false,
            "allowVirtualNetworkAccess": true,
            "allowForwardedTraffic": true,
            "remoteVirtualNetwork": {
                "id": "/subscriptions/'${sub_id}'/resourceGroups/'${rg}'/providers/Microsoft.Network/virtualNetworks/'${remote_vnet}'"
            }
        }
    }' | jq
}

delete_subnet_peering() {
local rg=$1
local local_vnet=$2
local remote_vnet=$3
echo "Delete: ${local_vnet}--${remote_vnet}"
curl -s -X DELETE "https://management.azure.com/subscriptions/${sub_id}/resourceGroups/${rg}/providers/Microsoft.Network/virtualNetworks/${local_vnet}/virtualNetworkPeerings/sub--${local_vnet}--${remote_vnet}?api-version=2023-11-01" \
     -H "Authorization: Bearer $access_token" | jq
}

