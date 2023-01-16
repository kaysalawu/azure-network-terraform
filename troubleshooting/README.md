
# Troubleshooting

(Work in Progress)


╷
│ Error: updating Network Security Group Association for Subnet: (Name "HubSpokeS1-hub1-nva" / Virtual Network Name "HubSpokeS1-hub1-vnet" / Resource Group "HubSpokeS1RG"): network.SubnetsClient#CreateOrUpdate: Failure sending request: StatusCode=0 -- Original Error: context deadline exceeded
│ 
│   with module.hub1.azurerm_subnet_network_security_group_association.this["nva"],
│   on ../../modules/base/main.tf line 19, in resource "azurerm_subnet_network_security_group_association" "this":
│   19: resource "azurerm_subnet_network_security_group_association" "this" {
│ 
╵
╷
│ Error: retrieving Subnet: (Name "HubSpokeS1-hub1-main" / Virtual Network Name "HubSpokeS1-hub1-vnet" / Resource Group "HubSpokeS1RG"): network.SubnetsClient#Get: Failure sending request: StatusCode=0 -- Original Error: context deadline exceeded
│ 
│   with module.hub1.azurerm_subnet_network_security_group_association.this["main"],
│   on ../../modules/base/main.tf line 19, in resource "azurerm_subnet_network_security_group_association" "this":
│   19: resource "azurerm_subnet_network_security_group_association" "this" {
│ 
╵
╷
│ Error: retrieving Subnet: (Name "HubSpokeS1-hub1-dns-in" / Virtual Network Name "HubSpokeS1-hub1-vnet" / Resource Group "HubSpokeS1RG"): network.SubnetsClient#Get: Failure sending request: StatusCode=0 -- Original Error: context deadline exceeded
│ 
│   with module.hub1.azurerm_subnet_network_security_group_association.this["dns"],
│   on ../../modules/base/main.tf line 19, in resource "azurerm_subnet_network_security_group_association" "this":
│   19: resource "azurerm_subnet_network_security_group_association" "this" {
│ 


tun terraform apply
