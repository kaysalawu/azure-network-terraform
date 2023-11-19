
# Azure Network Architecture - Terraform Examples <!-- omit from toc -->

## [1. Hub and Spoke](./1-hub-and-spoke)

The terraform codes in this collection cover different hub and spoke network patterns using standard VNET solutions.

### 1.1. Secure Hub and Spoke - Single Region
[Terraform Code](./1-hub-and-spoke/1-hub-spoke-azfw-single-region/)

This terraform code deploys a single-region Secured Virtual Network (Vnet) hub and spoke topology using Azure firewall and User-Defined Routes (UDR) to direct traffic to the firewall.

![Secured Hub and Spoke (Single Region)](./images/scenarios/1-1-hub-spoke-azfw-single-region.png)

### 1.2. Secure Hub and Spoke - Dual Region
[Terraform Code](./1-hub-and-spoke/2-hub-spoke-azfw-dual-region/)

This terraform code deploys a multi-region Secured Virtual Network (Vnet) hub and spoke topology using Azure firewall and User-Defined Routes (UDR) to direct traffic to the firewall.

![Secured Hub and Spoke (Dual Region)](./images/scenarios/1-2-hub-spoke-azfw-dual-region.png)

### 1.3. Hub and Spoke using NVA - Single Region
[Terraform Code](./1-hub-and-spoke/3-hub-spoke-nva-single-region/)

This terraform code deploys a single-region standard Virtual Network (Vnet) hub and spoke topology using Virtual Network Appliances (NVA) in the hub.

![Hub and Spoke using NVA (Single Region)](./images/scenarios/1-3-hub-spoke-nva-single-region.png)

### 1.4. Hub and Spoke using NVA - Dual Region
[Terraform Code](./1-hub-and-spoke/4-hub-spoke-nva-dual-region/)

This terraform code deploys a multi-region Virtual Network (Vnet) hub and spoke topology with dynamic routing using Network Virtual Aplliance (NVA) and Azure Route Server (ARS).

![Hub and Spoke using NVA (Dual Region)](./images/scenarios/1-4-hub-spoke-nva-dual-region.png)


## [2. Virtual WAN](./2-virtual-wan/)

The terraform codes in this collection cover different hub and spoke network patterns using Virtual WAN.

### 2.1. Virtual WAN - Single Region
[Terraform Code](./2-virtual-wan/1-vwan-single-region/)

This terraform code deploys a single-region Virtual WAN (Vwan) testbed to observe traffic routing patterns.

![Virtual WAN (Single Region)](./images/scenarios/2-1-vwan-single-region.png)

### 2.2. Virtual WAN - Dual Region
[Terraform Code](./2-virtual-wan/2-vwan-dual-region/)

This terraform code deploys a multi-hub (multi-region) Virtual WAN (Vwan) testbed to observe traffic routing patterns.

![Virtual WAN (Dual Region)](./images/scenarios/2-2-vwan-dual-region.png)

### 2.3. Secured Virtual WAN - Single Region
[Terraform Code](./2-virtual-wan/3-vwan-sec-single-region/)

This terraform code deploys a single-region Secured Virtual WAN (Vwan) testbed to observe traffic routing patterns. *Routing Intent* feature is enabled to allow traffic inspection on Azure firewalls for traffic between spokes and branches.

![Secured Virtual WAN (Single Region)](./images/scenarios/2-3-vwan-sec-single-region.png)

### 2.4. Secured Virtual WAN - Dual Region
[Terraform Code](./2-virtual-wan/4-vwan-sec-dual-region/)

This terraform code deploys a multi-hub (multi-region) Secured Virtual WAN (Vwan) testbed to observe traffic routing patterns. *Routing Intent* feature is enabled to allow traffic inspection on Azure firewalls for traffic between spokes and branches.

![Secured Virtual WAN (Dual Region)](./images/scenarios/2-4-vwan-sec-dual-region.png)

## [3. Virtual Network Manager](./3-virtual-network-manager/)

### 3.1. Secure Hub and Spoke - Single Region (Virtual Network Manager)
[Terraform Code](./3-network-manager/1-hub-spoke-azfw-single-region/)

This terraform code deploys a single-region Hub and Spoke Secured Virtual Network (Vnet) topology. The [Azure Virtual Network Manager](https://learn.microsoft.com/en-us/azure/virtual-network-manager/concept-connectivity-configuration#hub-and-spoke-topology) (AVNM) service is used to create the hub and spoke topology.

![Secure Hub and Spoke - Single Region (Virtual Network Manager)](./images/scenarios/3-1-hub-spoke-nm-azfw-single-region.png)

### 3.2. Secure Hub and Spoke - Dual Region (Virtual Network Manager)
[Terraform Code](./3-network-manager/2-hub-spoke-azfw-dual-region/)

This terraform code deploys a dual-region Hub and Spoke Secured Virtual Network (Vnet) topology. The [Azure Virtual Network Manager](https://learn.microsoft.com/en-us/azure/virtual-network-manager/concept-connectivity-configuration#hub-and-spoke-topology) (AVNM) service is used to create the hub and spoke topology.

![Secure Hub and Spoke - Dual Region (Virtual Network Manager)](./images/scenarios/3-2-hub-spoke-nm-azfw-dual-region.png)

## [4. General](./4-general/)
(In progress)
