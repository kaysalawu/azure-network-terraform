# Hub and Spoke - Dual Region <!-- omit from toc -->

Table of Contents 
- [Overview](#overview)
- [Prerequisites](#prerequisites)
- [Deploy the Lab](#deploy-the-lab)
- [Troubleshooting](#troubleshooting)
- [Testing](#testing)
- [Cleanup](#cleanup)

## Overview

This terraform code deploys a multi-region standard hub and spoke topology playground.

`Hub1` has an Azure Route Server (ARS) with BGP session to a Network Virtual Appliance (NVA) using a Cisco-CSR-100V router. The direct spokes `Spoke1` and `Spoke2` have VNET peering to `Hub1`. An isolated `Spoke3` does not have VNET peering to the ``Hub1, but is reachable from the hub via Private Link Service.

`Hub2` has an ARS with BGP session to an NVA using a Cisco-CSR-100V router. The direct spokes `Spoke4` and `Spoke5` have VNET peering to `Hub2`. An isolated `Spoke6` does not have VNET peering to the `Hub2`, but is reachable from the hub via Private Link Service.

The hubs are connected together via IPsec VPN and BGP dynamic routing to allow multi-region network reachability.

`Branch1` and `Branch3`are the on-premises networks which are simulated in VNETs using multi-NIC Cisco-CSR-100V NVA appliances.

![Hub and Spoke (Dual region)](../../images/hub-spoke-dual-region.png)

## Prerequisites

Ensure you meet all requirements in the [prerequisites](../../prerequisites/) before proceeding.

## Deploy the Lab

1. Clone the Git Repository for the Labs
```sh
git clone https://github.com/kaysalawu/azure-network-terraform.git
```

2. Navigate to the lab directory
```sh
cd azure-network-terraform/1-hub-and-spoke/2-hub-spoke-dual-region
```

3. Run the following terraform commands and type **yes** at the prompt:
```sh
terraform init
terraform plan
terraform apply
```

## Troubleshooting

See the [troubleshooting](../../troubleshooting/) section for tips on how to resolve common issues that may occur during the deployment of the lab.

## Testing

## Cleanup

1. Navigate to the lab directory
```sh
cd azure-network-terraform/1-hub-and-spoke/2-hub-spoke-dual-region
```

2. Delete the resource group to remove all resources installed.\
Run the following Azure CLI command:

```sh
az group delete -g HubSpokeS2RG --no-wait
```
