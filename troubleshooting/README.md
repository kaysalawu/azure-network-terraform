
# Troubleshooting <!-- omit from toc -->

Error Messages

- [1. Diagnostic Setting - "Already Exists"](#1-diagnostic-setting---already-exists)
- [2. Azure Policy Assignment - "Already Exists"](#2-azure-policy-assignment---already-exists)
- [3. Waiting for Virtual Network Peering"](#3-waiting-for-virtual-network-peering)
- [4. Backend Address Pool - "Error Updating"](#4-backend-address-pool---error-updating)
- [5. Resource - "Context Deadline Exceeded"](#5-resource---context-deadline-exceeded)
- [6. Network Security Group - "Already Exists"](#6-network-security-group---already-exists)
- [7. Subnet - "Already Exists"](#7-subnet---already-exists)
- [8. Virtual Machine Extension - "Already Exists"](#8-virtual-machine-extension---already-exists)
- [9. Virtual Machine - "Already Exists"](#9-virtual-machine---already-exists)

Terraform serializes some resource creation which creates situations where some resources wait for a long time for dependent resources to be created. There are scenarios where you might encounter errors after running terraform to deploy any of the labs. This could be as a result of occasional race conditions that come up because some terraform resources are dependent on Azure resources that take a long time to deploy - such as virtual network gateways.

The following are some of the common errors and how to resolve them.


## 1. Diagnostic Setting - "Already Exists"

This error occurs when terraform is trying to create a diagnostic setting that already exists. This is because the lab had been previously deployed. Diagnostic settings for resources are part of subscriptions and not resource groups. This means that if you have a resource group with a resource that has a diagnostic setting, and you delete the resource group, the diagnostic setting will still exist. When you re-create the same resource group and same resources, you will get this error.

**Example:**

```sh
│ Error: A resource with the ID "/subscriptions/b120edde-2b3e-1234-fake-55d2918f337f/resourceGroups/Vwan24RG/providers/Microsoft.Network/azureFirewalls/Vwan24-vhub2-azfw|Vwan24-vhub2-azfw-diag" already exists - to be managed via Terraform this resource needs to be imported into the State. Please see the resource documentation for "azurerm_monitor_diagnostic_setting" for more information.
│
│   with module.vhub2.azurerm_monitor_diagnostic_setting.this[0],
│   on ../../modules/virtual-hub/main.tf line 74, in resource "azurerm_monitor_diagnostic_setting" "this":
│   74: resource "azurerm_monitor_diagnostic_setting" "this" {
```

**Solution (Option 1):**

1. Navigate to the **Cleanup** section of the current lab and run the [_cleanup.sh script](../scripts/_cleanup.sh) to delete all diagnostic settings for the resource group.

 See an example for [Secured Hub and Spoke - Dual Region](../1-hub-and-spoke/2-hub-spoke-azfw-dual-region/README.md#cleanup) below which deletes Azure firewall and vnet gateway diagnostic settings.

 Sample output

 ```sh
 2-hub-spoke-azfw-dual-region$    bash ../../scripts/_cleanup.sh Hs12

 Resource group: Hs12RG

 ⏳ Checking for diagnostic settings on resources in Hs12RG ...
 ➜  Checking firewall ...
      ❌ Deleting: diag setting [Hs12-hub1-azfw-diag] for firewall [Hs12-hub1-azfw] ...
      ❌ Deleting: diag setting [Hs12-hub2-azfw-diag] for firewall [Hs12-hub2-azfw] ...
 ➜  Checking vnet gateway ...
      ❌ Deleting: diag setting [Hs12-hub1-vpngw-diag] for vnet gateway [Hs12-hub1-vpngw] ...
      ❌ Deleting: diag setting [Hs12-hub2-vpngw-diag] for vnet gateway [Hs12-hub2-vpngw] ...
 ➜  Checking vpn gateway ...
 ➜  Checking er gateway ...
 ➜  Checking app gateway ...
 ⏳ Checking for azure policies in Vwan24RG ...
 Done!
 ```

2. Re-apply terraform to create the diagnostic settings and deploy the remaining lab resources.
```sh
terraform plan
terraform apply
```

**Solution (Option 2):**

 1. Identify the terraform resource that is causing the error. In the example above, the resource is `azurerm_monitor_diagnostic_setting.this[0]`
 2. Identify the resource ID in the error message. In the example above, the resource ID is `/subscriptions/b120edde-2b3e-1234-fake-55d2918f337f/resourceGroups/Vwan24RG/providers/Microsoft.Network/azureFirewalls/Vwan24-vhub2-azfw|Vwan24-vhub2-azfw-diag`
 3. Import the resource into the terraform state. Substitute the resource ID in the command below with the resource ID from the error message above.

```sh
import <Resource_Name> "<Resource_ID>"
```
In this example, the command will be:

 ```sh
terraform import module.vhub2.azurerm_monitor_diagnostic_setting.this[0] "/subscriptions/b120edde-2b3e-1234-fake-55d2918f337f/resourceGroups/Vwan24RG/providers/Microsoft.Network/azureFirewalls/Vwan24-vhub2-azfw|Vwan24-vhub2-azfw-diag"
```
4. Re-apply terraform
```sh
terraform plan
terraform apply
```

## 2. Azure Policy Assignment - "Already Exists"

This error occurs when terraform is trying to create an Azure policy assignment that already exists. This is because the lab had been previously deployed. Azure policy assignments are part of subscriptions and not resource groups. This means that if you have a resource group with a resource that has an Azure policy assignment, and you delete the resource group, the Azure policy assignment will still exist. When you re-create the same resource group and same resources, you will get this error.

**Example:**

```sh
Error: A resource with the ID "/subscriptions/b120edde-2b3e-1234-fake-55d2918f337f/providers/Microsoft.Authorization/policyAssignments/Ne31-ng-spokes-prod-region1" already exists - to be managed via Terraform this resource needs to be imported into the State. Please see the resource documentation for "azurerm_subscription_policy_assignment" for more information.
│
│   with azurerm_subscription_policy_assignment.ng_spokes_prod_region1,
│   on svc-nm-common.tf line 57, in resource "azurerm_subscription_policy_assignment" "ng_spokes_prod_region1":
│   57: resource "azurerm_subscription_policy_assignment" "ng_spokes_prod_region1" {
```

**Solution:**

1. Navigate to the **Cleanup** section of the current lab and run the [_cleanup.sh script](../scripts/_cleanup.sh) to delete all Azure policy assignments for the resource group. The script also deletes diagnostic settings for the resource group.

See an example for [Secured Hub and Spoke - Dual Region (Virtual Network Manager](../3-network-manager/2-hub-spoke-azfw-dual-region/README.md#cleanup) below which deletes Azure policy assignments.

Sample output

```sh
2-hub-spoke-azfw-dual-region$    bash ../../scripts/_cleanup.sh Ne32

Resource group: Ne32RG

⏳ Checking for diagnostic settings on resources in Ne32RG ...
➜  Checking firewall ...
    ❌ Deleting: diag setting [Ne32-hub1-azfw-diag] for firewall [Ne32-hub1-azfw] ...
    ❌ Deleting: diag setting [Ne32-hub2-azfw-diag] for firewall [Ne32-hub2-azfw] ...
➜  Checking vnet gateway ...
    ❌ Deleting: diag setting [Ne32-hub1-vpngw-diag] for vnet gateway [Ne32-hub1-vpngw] ...
    ❌ Deleting: diag setting [Ne32-hub2-vpngw-diag] for vnet gateway [Ne32-hub2-vpngw] ...
➜  Checking vpn gateway ...
➜  Checking er gateway ...
➜  Checking app gateway ...
⏳ Checking for azure policies in Ne32RG ...
    ❌ Deleting: policy assignment [Ne32-ng-spokes-prod-region1] ...
    ❌ Deleting: policy definition [Ne32-ng-spokes-prod-region1] ...
    ❌ Deleting: policy assignment [Ne32-ng-spokes-prod-region2] ...
    ❌ Deleting: policy definition [Ne32-ng-spokes-prod-region2] ...
Done!
```

1. Re-apply terraform to create the Azure policy assignments and deploy the remaining lab resources.
```sh
terraform plan
terraform apply
```

  ## 3. Waiting for Virtual Network Peering"

  This error could occur due to simultaneous Vnet peering creation operations.

  **Example:**

```sh
Error: waiting for Virtual Network Peering: (Name "Vwan22-hub2-to-spoke5-peering" / Virtual Network Name "Vwan22-hub2-vnet" / Resource Group "Vwan22RG") to be created: network.VirtualNetworkPeeringsClient#CreateOrUpdate: Failure sending request: StatusCode=400 -- Original Error: Code="ReferencedResourceNotProvisioned" Message="Cannot proceed with operation because resource /subscriptions/b120edde-2b3e-1234-fake-55d2918f337f/resourceGroups/Vwan22RG/providers/Microsoft.Network/virtualNetworks/Vwan22-hub2-vnet used by resource /subscriptions/b120edde-2b3e-1234-fake-55d2918f337f/resourceGroups/Vwan22RG/providers/Microsoft.Network/virtualNetworks/Vwan22-hub2-vnet/virtualNetworkPeerings/Vwan22-hub2-to-spoke5-peering is not in Succeeded state. Resource is in Updating state and the last operation that updated/is updating the resource is PutSubnetOperation." Details=[]
│
│   with azurerm_virtual_network_peering.hub2_to_spoke5_peering,
│   on 08-conn-hub2.tf line 23, in resource "azurerm_virtual_network_peering" "hub2_to_spoke5_peering":
│   23: resource "azurerm_virtual_network_peering" "hub2_to_spoke5_peering" {
```

 **Solution:**

 Re-apply terraform to create the virtual network peering and deploy the remaining lab resources.
 ```sh
 terraform plan
 terraform apply
 ```

## 4. Backend Address Pool - "Error Updating"

This error could occur when terraform is trying to update the backend address pool of a load balancer. This could be as a result of the load balancer being in a state of updating from a previous terraform run, or as a result of race condition encountered when deploying multiple terraform resources at the same time.

**Example:**

```sh
│ Error: updating Backend Address Pool Address: (Address Name "Vwan23-hub1-nva-beap-addr" / Backend Address Pool Name "Vwan23-hub1-nva-beap" / Load Balancer Name "Vwan23-hub1-nva-lb" / Resource Group "Vwan23RG"): network.LoadBalancerBackendAddressPoolsClient#CreateOrUpdate: Failure sending request: StatusCode=409 -- Original Error: Code="AnotherOperationInProgress" Message="Another operation on this or dependent resource is in progress. To retrieve status of the operation use uri: https://management.azure.com/subscriptions/b120edde-2b3e-1234-fake-55d2918f337f/providers/Microsoft.Network/locations/westeurope/operations/5d66a0e0-e08b-4ecf-aee5-0ff5a461962b?api-version=2022-07-01." Details=[]
│
│   with azurerm_lb_backend_address_pool_address.hub1_nva,
│   on 08-conn-hub1.tf line 208, in resource "azurerm_lb_backend_address_pool_address" "hub1_nva":
│  208: resource "azurerm_lb_backend_address_pool_address" "hub1_nva" {
│
│ updating Backend Address Pool Address: (Address Name "Vwan23-hub1-nva-beap-addr" / Backend Address Pool Name "Vwan23-hub1-nva-beap" / Load Balancer Name "Vwan23-hub1-nva-lb" / Resource Group "Vwan23RG"):
│ network.LoadBalancerBackendAddressPoolsClient#CreateOrUpdate: Failure sending request: StatusCode=409 -- Original Error: Code="AnotherOperationInProgress" Message="Another operation on this or dependent resource is in
│ progress. To retrieve status of the operation use uri:
│ https://management.azure.com/subscriptions/b120edde-2b3e-1234-fake-55d2918f337f/providers/Microsoft.Network/locations/westeurope/operations/5d66a0e0-e08b-4ecf-aee5-0ff5a461962b?api-version=2022-07-01." Details=[]
 ```

 **Solution:**

Re-apply terraform
```sh
terraform plan
terraform apply
```

Repeat the above steps for all similar errors.


## 5. Resource - "Context Deadline Exceeded"

This occurs when terraform occasionally times out while waiting to create a resource.

**Example:**

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

**Solution:**

Apply terraform again.
```sh
terraform plam
terraform apply
```

## 6. Network Security Group - "Already Exists"

This occurs when terraform is trying to apply an NSG rule to a subnet which already has the NSG associated with the subnet from the previous terraform run.

**Example:**

```sh
╷
│ Error: A resource with the ID "/subscriptions/ec265026-bc67-44f6-92bc-9849685d921d/resourceGroups/VwanS4RG/providers/Microsoft.Network/virtualNetworks/VwanS4-hub2-vnet/subnets/VwanS4-hub2-main" already exists - to be managed via Terraform this resource needs to be imported into the State. Please see the resource documentation for "azurerm_subnet_network_security_group_association" for more information.
│
│   with module.hub2.azurerm_subnet_network_security_group_association.this["main"],
│   on ../../modules/base/main.tf line 19, in resource "azurerm_subnet_network_security_group_association" "this":
│   19: resource "azurerm_subnet_network_security_group_association" "this" {
```

**Solution:**

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

Repeat the above steps for all similar errors.

## 7. Subnet - "Already Exists"

This occurs when terraform is attempting to create a subnet which already exists from a previous terraform run.

**Example:**

```sh
│ Error: A resource with the ID "/subscriptions/ec265026-bc67-44f6-92bc-9849685d921d/resourceGroups/HubSpokeS1RG/providers/Microsoft.Network/virtualNetworks/HubSpokeS1-hub1-vnet/subnets/HubSpokeS1-hub1-dns-out" already exists - to be managed via Terraform this resource needs to be imported into the State. Please see the resource documentation for "azurerm_subnet" for more information.
│
│   with module.hub1.azurerm_subnet.this["HubSpokeS1-hub1-dns-out"],
│   on ../../modules/base/main.tf line 62, in resource "azurerm_subnet" "this":
│   62: resource "azurerm_subnet" "this" {
```

**Solution:**

1. Delete the subnet
2. Re-apply terraform
```sh
terraform plan
terraform apply
```

Repeat the above steps for all similar errors.

## 8. Virtual Machine Extension - "Already Exists"

This error could occur when terraform is trying to create a virtual machine extension. This could be as a result of the virtual machine extension already existing from a previous terraform run, or as a result of race condition encountered when deploying multiple terraform resources at the same time.

**Example:**

```sh
│ Error: A resource with the ID "/subscriptions/b120edde-2b3e-1234-fake-55d2918f337f/resourceGroups/Hs14RG/providers/Microsoft.Compute/virtualMachines/Hs14-branch1-dns/extensions/Hs14-branch1-dns" already exists - to be managed via Terraform this resource needs to be imported into the State. Please see the resource documentation for "azurerm_virtual_machine_extension" for more information.
│
│   with module.branch1.module.vm["dns"].azurerm_virtual_machine_extension.this[0],
│   on ../../modules/linux/main.tf line 93, in resource "azurerm_virtual_machine_extension" "this":
│   93: resource "azurerm_virtual_machine_extension" "this" {
```

 **Solution:**

 Delete the virtual machine extension from the Azure portal and re-apply terraform.

 1. Select the virtual machine from the Azure portal.
 2. Select Extensions + applications*
 3. Click on the extension to be deleted - in this scenario, the extension is *Hs14-branch1-dns*
 4. Click on *Uninstall*

![tshoot-5-vm-extension](../images/troubleshooting/tshoot-6-vm-extension.png)

  5. Re-apply terraform
  ```sh
  terraform plan
  terraform apply
  ```

  Repeat the above steps for all similar errors.

## 9. Virtual Machine - "Already Exists"

This occurs when terraform is attempting to create a subnet which already exists from a previous terraform run.

**Example:**

```sh
│ Error: A resource with the ID "/subscriptions/b120edde-2b3e-1234-fake-55d2918f337f/resourceGroups/Hs11RG/providers/Microsoft.Compute/virtualMachines/Hs11-hub1Vm" already exists - to be managed via Terraform this resource needs to be imported into the State. Please see the resource documentation for "azurerm_linux_virtual_machine" for more information.
│
│   with module.hub1_vm.azurerm_linux_virtual_machine.this,
│   on ../../modules/virtual-machine-linux/main.tf line 68, in resource "azurerm_linux_virtual_machine" "this":
│   68: resource "azurerm_linux_virtual_machine" "this" {
```

**Solution (Option 1):**

1. Delete the virtual machine from the portal or CLI
2. Re-apply terraform
```sh
terraform plan
terraform apply
```

**Solution (Option 2):**

 1. Identify the terraform resource that is causing the error. In the example above, the resource is `module.hub1_vm.azurerm_linux_virtual_machine.this`
 2. Identify the resource ID in the error message. In the example above, the resource ID is `"/subscriptions/b120edde-2b3e-1234-fake-55d2918f337f/resourceGroups/Hs11RG/providers/Microsoft.Compute/virtualMachines/Hs11-hub1Vm"`
 3. Import the resource into the terraform state. Substitute the resource ID in the command below with the resource ID from the error message above.

```sh
import <Resource_Name> "<Resource_ID>"
```
In this example, the command will be:

 ```sh
terraform import module.hub1_vm.azurerm_linux_virtual_machine.this "/subscriptions/b120edde-2b3e-1234-fake-55d2918f337f/resourceGroups/Hs11RG/providers/Microsoft.Compute/virtualMachines/Hs11-hub1Vm"
```
4. Re-apply terraform
```sh
terraform plan
terraform apply
```
