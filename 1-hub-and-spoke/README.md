
# Hub and Spoke <!-- omit from toc -->

Contents
<!-- TOC -->
- [1.1. Secured Hub and Spoke - Single Region](#11-secured-hub-and-spoke---single-region)
- [1.2. Secured Hub and Spoke - Dual Region](#12-secured-hub-and-spoke---dual-region)
- [1.3. Hub and Spoke - Single Region (NVA)](#13-hub-and-spoke---single-region-nva)
- [1.4. Hub and Spoke - Dual Region (NVA)](#14-hub-and-spoke---dual-region-nva)
<!-- /TOC -->

Terraform codes in this collection cover different hub and spoke network patterns using standard VNET solutions.

## 1.1. Secured Hub and Spoke - Single Region

⚙️ [**Deploy Terraform Code**](./1-hub-spoke-azfw-single-region/)

This lab deploys a single-region Hub and Spoke Secured Virtual Network (Vnet) topology using Azure Firewall for traffic inspection. The lab demonstrates traffic routing patterns, [hybrid DNS](https://learn.microsoft.com/en-us/azure/dns/private-resolver-hybrid-dns) resolution, firewall security policies, and [PrivateLink Services](https://learn.microsoft.com/en-us/azure/private-link/private-link-service-overview) access to IaaS, [PrivateLink](https://learn.microsoft.com/en-us/azure/private-link/private-link-overview) access to PaaS services.

<img src="../images/scenarios/1-1-hub-spoke-azfw-single-region.png" alt="Secured Hub and Spoke (Single region)" width="570">

## 1.2. Secured Hub and Spoke - Dual Region

⚙️ [**Deploy Terraform Code**](./2-hub-spoke-azfw-dual-region/)

This lab deploys a dual-region Secured Hub and Spoke Vnet topology using Azure Firewalls for traffic inspection. The lab demonstrates multi-region traffic routing patterns, [hybrid DNS](https://learn.microsoft.com/en-us/azure/dns/private-resolver-hybrid-dns) resolution, firewall security policies, and [PrivateLink Services](https://learn.microsoft.com/en-us/azure/private-link/private-link-service-overview) access to IaaS, [PrivateLink](https://learn.microsoft.com/en-us/azure/private-link/private-link-overview) access to PaaS services.

<img src="../images/scenarios/1-2-hub-spoke-azfw-dual-region.png" alt="Secured Hub and Spoke (Dual region)" width="1000">
<p>

## 1.3. Hub and Spoke - Single Region (NVA)

⚙️ [**Deploy Terraform Code**](./3-hub-spoke-nva-single-region/)

This lab deploys a single-region Hub and Spoke Vnet topology using Virtual Network Appliances (NVA) for traffic inspection. The lab demonstrates traffic routing patterns, [hybrid DNS](https://learn.microsoft.com/en-us/azure/dns/private-resolver-hybrid-dns) resolution, NVA deployment, and [PrivateLink Services](https://learn.microsoft.com/en-us/azure/private-link/private-link-service-overview) access to IaaS, [PrivateLink](https://learn.microsoft.com/en-us/azure/private-link/private-link-overview) access to PaaS services.

<img src="../images/scenarios/1-3-hub-spoke-nva-single-region.png" alt="Hub and Spoke (Single region)" width="570">

## 1.4. Hub and Spoke - Dual Region (NVA)

⚙️ [**Deploy Terraform Code**](./4-hub-spoke-nva-dual-region/)

This lab deploys a dual-region Hub and Spoke Vnet topology using Virtual Network Appliances (NVA) for traffic inspection. The lab demonstrates multi-region traffic routing patterns, [hybrid DNS](https://learn.microsoft.com/en-us/azure/dns/private-resolver-hybrid-dns) resolution, NVA deployment, and [PrivateLink Services](https://learn.microsoft.com/en-us/azure/private-link/private-link-service-overview) access to IaaS, [PrivateLink](https://learn.microsoft.com/en-us/azure/private-link/private-link-overview) access to PaaS services.

<img src="../images/scenarios/1-4-hub-spoke-nva-dual-region.png" alt="Hub and Spoke (Dual region)" width="1000">
<p>
