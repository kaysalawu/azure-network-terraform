RG=Poc4RG
Vnet=Poc4-hub1-vnet
Subnet=Poc4-hub1-pls
az network vnet subnet update -g $RG -n $Subnet --vnet-name $Vnet --network-security-group null
#az network vnet subnet delete -g $RG -n $Subnet --vnet-name $Vnet
