
# Create a VNet flow log

az network watcher flow-log create \
--resource-group Ne31RG \
--location eastus \
--name Ne31-hub1-vnet \
--vnet Ne31-hub1-vnet \
--storage-account ne31region18a1a
