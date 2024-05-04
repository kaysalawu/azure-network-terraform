#!bin/bash

function show_help {
    echo "Usage: $0 -g RESOURCE_GROUP -c CIRCUIT_NAME -a ACTION"
    echo ""
    echo "This script requires options and arguments:"
    echo "  -g, --resource-group   The name of the resource group."
    echo "  -c, --circuit-name     The name of the circuit."
    echo "  -a, --action           The action to perform (list, start, shutdown)."
    echo ""
    echo "Options:"
    echo "  -h, --helper           Display this help message and exit."
    echo ""
    echo "Examples:"
    echo "  $0 -g myResourceGroup -c myCircuitName -a shutdown-bgp-connection"
    echo "  $0 -g myResourceGroup -c myCircuitName -a start-bgp-connection"
}

while [[ "$#" -gt 0 ]]; do
    case $1 in
        -h|--helper)
            show_help
            exit 0
            ;;
        -g|--resource-group)
            RESOURCE_GROUP=$2
            shift 2
            ;;
        -c|--circuit-name)
            CIRCUIT_NAME=$2
            shift 2
            ;;
        -a|--action)
            ACTION=$2
            shift 2
            ;;
        *)
            echo "Unknown option: $1"
            show_help
            exit 1
            ;;
    esac
done

if [[ -z $RESOURCE_GROUP || -z $CIRCUIT_NAME ]]; then
    echo "Error: Missing required arguments."
    show_help
    exit 1
fi

echo "Resource Group: $RESOURCE_GROUP"
echo "Circuit Name: $CIRCUIT_NAME"

function run_init() {
    baseUrl=https://api.megaport.com
    authUrl=https://auth-m2m.megaport.com/oauth2/token
    AUTH=$(echo -n "$TF_VAR_megaport_access_key:$TF_VAR_megaport_secret_key" | base64 -w 0)

    ACCESS_TOKEN=$(curl -s --location --request POST "https://auth-m2m.megaport.com/oauth2/token" \
    --header "Authorization: Basic $AUTH" \
    --header "Content-Type: application/x-www-form-urlencoded" \
    --data-urlencode "grant_type=client_credentials" | jq -r '.access_token')

    if [[ -z $ACCESS_TOKEN ]]; then
        echo "MegaportAuth: Failed!"
        exit 1
    else
        echo "MegaportAuth: Success!"
    fi
}

function get_service_key_data() {
    SERVICE_KEY=$(az network express-route show --resource-group $RESOURCE_GROUP --name ${CIRCUIT_NAME} --query "serviceKey" -o tsv)
    if [[ -z $SERVICE_KEY ]]; then
        echo "ServiceKey: Extracion failed!"
        exit 1
    else
        echo "ServiceKey: Extraction successful!"
    fi
    SERVICE_KEY_DATA=$(curl -s --location -g --request GET "$baseUrl/v2/secure/azure/${SERVICE_KEY}" \
    --header "Content-Type: application/json" \
    --header "Authorization: Bearer $ACCESS_TOKEN")
}

function get_vxc_data() {
    local product_uid=$1
    VXC_DATA=$(curl -s --location --request GET "$baseUrl/v2/product/$product_uid" \
    --header "Content-Type: application/json" \
    --header "Authorization: Bearer $ACCESS_TOKEN")
    echo $VXC_DATA
}

run_init
# create_express_route_circuit
get_service_key_data
productUid=$(echo $SERVICE_KEY_DATA | jq -r '.data.megaports[0].productUid')
echo "productUid: $productUid"
get_vxc_data $productUid




