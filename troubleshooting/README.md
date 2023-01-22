
# Troubleshooting <!-- omit from toc -->

Errors
- [1. Network Security Group - Context Deadline Exceeded](#1-network-security-group---context-deadline-exceeded)
- [2. Network Security Group - Already Exists](#2-network-security-group---already-exists)
- [3. Subnet - Already Exists](#3-subnet---already-exists)

Terraform seializes some resource creation which creates situations where some resources wait for a long time for dependent resources to be created. There are scenarios where you might encounter errors after running terraform to deploy any of the labs. This could be as a result of occassional race conditions that come up because some terraform resources are dependent on Azure resources that take a long time to deploy - such as virtual network gateways.

The folowing are some of the common errors and how to resolve them.

## 1. Network Security Group - Context Deadline Exceeded

This occurs when terraform times out on associating the NSG to a subnet.

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

## 2. Network Security Group - Already Exists

This occurs when terraform is trying to apply an NSG rule to a subnet which already has the NSG associated with the subnet from the previous terraform run.

**Examples:**

```sh
╷
│ Error: A resource with the ID "/subscriptions/ec265026-bc67-44f6-92bc-9849685d921d/resourceGroups/VwanS4RG/providers/Microsoft.Network/virtualNetworks/VwanS4-hub2-vnet/subnets/VwanS4-hub2-main" already exists - to be managed via Terraform this resource needs to be imported into the State. Please see the resource documentation for "azurerm_subnet_network_security_group_association" for more information.
│ 
│   with module.hub2.azurerm_subnet_network_security_group_association.this["main"],
│   on ../../modules/base/main.tf line 19, in resource "azurerm_subnet_network_security_group_association" "this":
│   19: resource "azurerm_subnet_network_security_group_association" "this" {
│ 
╵
 Error encountered!!!
```

**Resolution:**

Remove the NSG associated with the subnet. Subtitute the values of your resource group, subnet name and virtual network name below and run the CLI command:
```sh
RG=<Resource Group>
Subnet=<Subnet name>
Vnet=<VNET name>
az network vnet subnet update -g $RG -n $Subnet --vnet-name $Vnet --network-security-group null
```

Re-apply terraform
```sh
terraform plan
terraform apply
```
## 3. Subnet - Already Exists

This occurs when terraform is attempting to create a subnet which already exists from a previous terraform run.

**Examples:**

```sh
│ Error: A resource with the ID "/subscriptions/ec265026-bc67-44f6-92bc-9849685d921d/resourceGroups/HubSpokeS1RG/providers/Microsoft.Network/virtualNetworks/HubSpokeS1-hub1-vnet/subnets/HubSpokeS1-hub1-dns-out" already exists - to be managed via Terraform this resource needs to be imported into the State. Please see the resource documentation for "azurerm_subnet" for more information.
│ 
│   with module.hub1.azurerm_subnet.this["HubSpokeS1-hub1-dns-out"],
│   on ../../modules/base/main.tf line 62, in resource "azurerm_subnet" "this":
│   62: resource "azurerm_subnet" "this" {
```

**Resolution:**

Delete the subnet

```sh

```

Re-apply terraform
```sh
terraform plan
terraform apply
```
