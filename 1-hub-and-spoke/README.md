
# Hub and Spoke <!-- omit from toc -->

Contents
<!-- TOC -->
- [1. Secured Hub and Spoke (Single Region)](#1-secured-hub-and-spoke-single-region)
- [2. Secured Hub and Spoke (Dual Region)](#2-secured-hub-and-spoke-dual-region)
- [3. Hub and Spoke using NVA (Single Region)](#3-hub-and-spoke-using-nva-single-region)
- [4. Hub and Spoke using NVA (Dual Region)](#4-hub-and-spoke-using-nva-dual-region)
<!-- /TOC -->

The terraform codes in this collection cover different hub and spoke network patterns using standard VNET solutions.

## [1. Secured Hub and Spoke (Single Region)](./1-hub-spoke-azfw-single-region/)
[-hub2-azfw Code](./1-hub-spoke-azfw-single-region/)

This terraform code deploys a single-region Secured Virtual Network (Vnet) hub and spoke topology using Azure firewall and User-Defined Routes (UDR) to direct traffic to the firewall.

![Secured Hub and Spoke (Single Region)](../images/scenarios/1-1-hub-spoke-azfw-single-region.png)

## [2. Secured Hub and Spoke (Dual Region)](./2-hub-spoke-azfw-dual-region/)
[-hub2-azfw Code](./2-hub-spoke-azfw-dual-region/)

This terraform code deploys a multi-region Secured Virtual Network (Vnet) hub and spoke topology using Azure firewall and User-Defined Routes (UDR) to direct traffic to the firewall.

![Secured Hub and Spoke (Dual Region)](../images/scenarios/1-2-hub-spoke-azfw-dual-region.png)

## [3. Hub and Spoke using NVA (Single Region)](./3-hub-spoke-nva-single-region/)
[-hub2-azfw Code](./3-hub-spoke-nva-single-region/)

This terraform code deploys a single-region standard Virtual Network (Vnet) hub and spoke topology.

![Hub and Spoke using NVA (Single Region)](../images/scenarios/1-3-hub-spoke-nva-single-region.png)

## [4. Hub and Spoke using NVA (Dual Region)](./4-hub-spoke-nva-dual-region/)
[-hub2-azfw Code](./4-hub-spoke-nva-dual-region/)

This terraform code deploys a multi-region Virtual Network (Vnet) hub and spoke topology with dynamic routing using Network Virtual Aplliance (NVA) and Azure Route Server (ARS).

![Hub and Spoke using NVA (Dual Region)](../images/scenarios/1-4-hub-spoke-nva-dual-region.png)
