#!bin/bash

logs_path=logs.txt
echo "" >> $logs_path
echo "****************************************************" >> $logs_path
echo $(date) >> $logs_path
echo "" >> $logs_path
START_TOTAL=$(date +%s)

export RG=Poc3RG
export LOC=westeurope
export PEERING_LOC="Telehouse North"
export ER_CCT=Poc3-hub1-er-circuit
export ERGW_NAME=Poc3-hub1-ergw
export CONN=Poc3-hub1--azure-vcx-hub1-er
export ERGW_PIP=Poc3-hub1-ergw-pip0
export VNET_NAME=Poc3-hub1-vnet

export ER_CCT_ID=$(az network express-route show --name "$ER_CCT" -g "$RG" --query id -o tsv)
export ERGW_ID=$(az network vnet-gateway show --name "$ERGW_NAME" -g "$RG" --query id -o tsv)
export ERGW_SKU=$(az network vnet-gateway show --name "$ERGW_NAME" -g "$RG" --query 'sku.name' --output tsv)

delete_er_conn(){
    START=$(date +%s)
    message="Step 1: Delete ER Gateway Connection ($CONN)"
    echo ""
    echo $message

    CONN_EXISTS=$(az network vpn-connection show --name "$CONN" -g "$RG" --query id -o tsv)
    if [[ -z $CONN_EXISTS ]]; then
        echo "ER-GW connection $CONN does not exist. Skipping..."
        exit 11
    fi
    echo "Deleting ER-GW connection $CONN ..."
    az network vpn-connection delete --name "$CONN" -g "$RG"

    END=$(date +%s)
    ELAPSED=$((END - START))
    echo "$message [ $(($ELAPSED/60))m $(($ELAPSED%60))s ]" >> $logs_path
}

delete_ergw_standard(){
    START=$(date +%s)
    message="Step 2: Delete ER Gateway ($ERGW_NAME)"
    echo $message

    ERGW_EXISTS=$(az network vnet-gateway show --name "$ERGW_NAME" -g "$RG" --query id -o tsv)
    if [[ -z $ERGW_EXISTS ]]; then
        echo "ER-GW $ERGW_NAME does not exist. Skipping..."
        exit 22
    fi
    echo "Deleting ER-GW $ERGW_NAME ..."
    az network vnet-gateway delete --name "$ERGW_NAME" -g "$RG"

    END=$(date +%s)
    ELAPSED=$((END - START))
    echo "$message [ $(($ELAPSED/60))m $(($ELAPSED%60))s ]" >> $logs_path
}

create_ergw_ergw1az(){
    START=$(date +%s)
    message="Step 3: Create ER Gateway with SKU ErGw1AZ"
    echo ""
    echo $message

    ERGW_EXISTS=$(az network vnet-gateway show --name "$ERGW_NAME" -g "$RG" --query id -o tsv)
    if [[ ! -z $ERGW_EXISTS ]]; then
        echo "ER-GW $ERGW_NAME already exists. Skipping..."
        exit 33
    fi
    az network vnet-gateway create \
    --name "$ERGW_NAME" \
    --resource-group "$RG" \
    --gateway-type ExpressRoute \
    --sku ErGw1AZ \
    --location "$LOC" \
    --vnet $VNET_NAME \
    --public-ip-addresses $ERGW_PIP \
    --no-wait
    prState=''
    TIME=0
    while [[ $prState != 'Succeeded' ]];
    do
        prState=$(az network vnet-gateway show --name "$ERGW_NAME" -g "$RG" --query provisioningState -o tsv)
        echo "Creating ER-GW $ERGW_NAME: $prState [$(($TIME/60))m $(($TIME%60))s]"
        sleep 20
        TIME=$((TIME+20))
    done

    END=$(date +%s)
    ELAPSED=$((END - START))
    echo "$message [ $(($ELAPSED/60))m $(($ELAPSED%60))s ]" >> $logs_path
}

get_er_auth(){
    START=$(date +%s)
    message="Step 4: Get ER Circuit auth key"
    echo ""
    echo $message

    export ER_CCT_AUTH_KEY=$(az network express-route auth list --circuit-name $ER_CCT -g $RG --query "[0].authorizationKey" -o tsv)
    echo "ER_CCT_AUTH_KEY: $ER_CCT_AUTH_KEY"

    END=$(date +%s)
    ELAPSED=$((END - START))
    echo "$message [ $(($ELAPSED/60))m $(($ELAPSED%60))s ]" >> $logs_path
}

create_er_conn(){
    START=$(date +%s)
    message="Step 5: Create ER Connection ($CONN)"
    echo ""
    echo $message

    CONN_EXISTS=$(az network vpn-connection show --name "$CONN" -g "$RG" --query id -o tsv)
    if [[ ! -z $CONN_EXISTS ]]; then
        echo "ER-GW connection $CONN already exists. Skipping..."
        exit 55
    fi
    echo "Creating ER-GW connection $CONN ..."
    az network vpn-connection create \
    --name $CONN \
    --resource-group $RG \
    --location $LOC \
    --vnet-gateway1 $ERGW_NAME \
    --express-route-circuit2 $ER_CCT_ID

    END=$(date +%s)
    ELAPSED=$((END - START))
    echo "$message [ $(($ELAPSED/60))m $(($ELAPSED%60))s ]" >> $logs_path
}

if [[ $ERGW_SKU == "Standard" ]]; then
    delete_er_conn
    delete_ergw_standard
    create_ergw_ergw1az
    get_er_auth
    create_er_conn
else
   echo ""
   echo "ERGW SKU is not Standard. Skipping ERGW migration..."
fi

# Calculate total execution time
END_TOTAL=$(date +%s)
TOTAL_ELAPSED=$((END_TOTAL - START_TOTAL))
echo ""
echo "Total time = $(($TOTAL_ELAPSED/60))m $(($TOTAL_ELAPSED%60))s" >> $logs_path
