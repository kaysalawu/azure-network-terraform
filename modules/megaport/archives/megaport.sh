#!bin/bash

function run_init() {
    baseUrl=https://api.megaport.com
    authUrl=https://auth-m2m.megaport.com/oauth2/token

    USERNAME=$TF_VAR_megaport_access_key
    PASSWORD=$TF_VAR_megaport_secret_key
    AUTH=$(echo -n "${USERNAME}:${PASSWORD}" | base64 -w 0)

    ACCESS_TOKEN=$(curl -s --location --request POST "https://auth-m2m.megaport.com/oauth2/token" \
    --header "Authorization: Basic ${AUTH}" \
    --header "Content-Type: application/x-www-form-urlencoded" \
    --header "Cookie: XSRF-TOKEN=db81db11-0f52-42b4-91dc-8d367f63c6fa" \
    --data-urlencode "grant_type=client_credentials" | jq -r '.access_token')
}

function create_express_route_circuit() {
    echo -e "\nCreate: Express Route Circuit [$CIRCUIT_NAME]"
    az network express-route create -g $RESOURCE_GROUP \
    --name $CIRCUIT_NAME \
    --peering-location "Dublin" \
    --provider "Megaport" \
    --sku-tier "Standard" \
    --sku-family "MeteredData" \
    --allow-global-reach false \
    --bandwidth 50
}

function get_service_key_data() {
    SERVICE_KEY=$(az network express-route show --resource-group $RESOURCE_GROUP --name $CIRCUIT_NAME --query "serviceKey" -o tsv)
    SERVICE_KEY_DATA=$(curl -s --location -g --request GET "${baseUrl}/v2/secure/azure/${SERVICE_KEY}" \
    --header "Content-Type: application/json" \
    --header "Authorization: Bearer ${ACCESS_TOKEN}")
    echo $SERVICE_KEY_DATA | jq
}

function create_megaport_mcr() {
    echo -e "\nCreate: Megaport MCR"
    curl --location "https://api.megaport.com/v3/networkdesign/buy" \
    --header "Content-Type: application/json" \
    --header "Authorization: Bearer ${ACCESS_TOKEN}" \
    --data '[
        {
            "locationId":60,
            "term": 12,
            "productName":"Test MCR",
            "productType":"MCR2",
            "config": {
                "diversityZone": "red"
            },
            "portSpeed":2500,
            "config": {
            "mcrAsn": 133937
            }
        }
    ]'


RESOURCE_GROUP="Lab07_HubSpoke_Nva_1Region_RG"
CIRCUIT_NAME="Lab07-er1"

# run_init
# create_express_route_circuit
# get_service_key_data

echo $SERVICE_KEY_DATA | jq


