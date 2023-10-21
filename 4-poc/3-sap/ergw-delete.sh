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

delete_ergw1az(){
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

if [[ $ERGW_SKU == "ErGw1AZ" ]]; then
    delete_er_conn
    delete_ergw1az
else
   echo ""
   echo "ERGW SKU is not ErGw1AZ. Skipping ERGW deletion..."
fi

# Calculate total execution time
END_TOTAL=$(date +%s)
TOTAL_ELAPSED=$((END_TOTAL - START_TOTAL))
echo ""
echo "Total time = $(($TOTAL_ELAPSED/60))m $(($TOTAL_ELAPSED%60))s" >> $logs_path
