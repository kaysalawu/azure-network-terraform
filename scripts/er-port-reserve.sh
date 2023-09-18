#! bin/bash

erState=[]
region=westeurope
peeringLocation=$2
rg=$1

let count=0
while [[ $erState == [] ]];
do
    erState=$(az network express-route port location show --location $peeringLocation | jq -r '.availableBandwidths')
    echo -e "$count: availableBandwidths = $erState" || true
    ((count++))
    sleep 5
done

: '
az network express-route port create \
--name $name \
--resource-group $rg \
--bandwidth 100 \
--encapsulation Dot1Q \
--location westeurope \
--peering-location $2
'