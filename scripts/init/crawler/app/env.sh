
export LOCATION=northeurope
export RESOURCE_GROUP="G10_NetworkEgress_RG"
export TOKEN=$(az account get-access-token --query accessToken --output tsv)
export STORAGE_ACCOUNT_NAME=$(az storage account list -g $RESOURCE_GROUP --query "[?contains(name, 'hub') && location=='$LOCATION'].name" --output tsv)
export KEY_VAULT_NAME=$(az keyvault list -g $RESOURCE_GROUP --query "[?contains(name, 'hub') && location=='$LOCATION'].name" --output tsv)
export ACCOUNT_KEY=$(az storage account keys list -g $RESOURCE_GROUP --account-name $STORAGE_ACCOUNT_NAME --query '[0].value' --output tsv)
export VNET_NAME=$(az network vnet list -g $RESOURCE_GROUP --query '[0].name' --output tsv)
