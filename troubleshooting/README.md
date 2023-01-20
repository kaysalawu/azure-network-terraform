
# Troubleshooting <!-- omit from toc -->

Common error messages
- [Context Deadline Exceeded](#context-deadline-exceeded)


There are scenarios where you might encounter errors after running terraform to deploy any of the labs. This could be as a result of occassional race conditions that come up because some terraform resources are dependent on Azure resources that take a long time to deploy - such as virtual network gateways.

The folowing are some of the common errors and how to resolve them.

## Context Deadline Exceeded

**Examples:**

```sh
Error: updating Network Security Group Association for Subnet: (Name "HubSpokeS1-hub1-nva" / Virtual Network Name "HubSpokeS1-hub1-vnet" / Resource Group "HubSpokeS1RG"): network.SubnetsClient#CreateOrUpdate: Failure sending request: StatusCode=0 -- Original Error: context deadline exceeded

  with module.hub1.azurerm_subnet_network_security_group_association.this["nva"],
  on ../../modules/base/main.tf line 19, in resource "azurerm_subnet_network_security_group_association" "this":
  19: resource "azurerm_subnet_network_security_group_association" "this" {
```
```sh
Error: retrieving Subnet: (Name "HubSpokeS1-hub1-dns-in" / Virtual Network Name "HubSpokeS1-hub1-vnet" / Resource Group "HubSpokeS1RG"): network.SubnetsClient#Get: Failure sending request: StatusCode=0 -- Original Error: context deadline exceeded

  with module.hub1.azurerm_subnet_network_security_group_association.this["dns"],
  on ../../modules/base/main.tf line 19, in resource "azurerm_subnet_network_security_group_association" "this":
  19: resource "azurerm_subnet_network_security_group_association" "this" {
```

**Resolution:**

Apply terraform again.
```sh
terraform plam
terraform apply
```
