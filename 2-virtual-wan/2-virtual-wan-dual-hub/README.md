
# Virtual WAN - Dual Hub <!-- omit from toc -->

Table of Contents
- [Overview](#overview)
- [Prerequisites](#prerequisites)
- [Deploy the Lab](#deploy-the-lab)
- [Troubleshooting](#troubleshooting)
- [Testing](#testing)
- [Cleanup](#cleanup)

## Overview

This terraform code deploys a multi-hub (multi-region) virtual WAN architecture playground to observe dynamic routing patterns.

In this architecture, we integrate standard hubs (`hub1` and `hub2`) to the virtual WAN hubs (`vHub1` and `vHub2`) via a virtual WAN connections. Direct spokes (`Spoke1` and `Spoke4`) are connected to their respective virtual WAN hubs via VNET connections. `Spoke2` and `Spoke5` are indirect spokes from a virtual WAN perspective; are connected via standard VNET peering to `Hub1` and `Hub2` respectively. 

The isolated spokes (`Spoke3` and `Spoke6`) do not have VNET peering to their respective hubs (`Hub1` and `Hub2`), but are reachable via Private Link Service through a private endpoint in each hub.

`Branch1` and `Branch3`are the on-premises networks which are simulated in VNETs using multi-NIC Cisco-CSR-100V NVA appliances.

![Virtual WAN - Dual Hub](../../images/vwan-dual-hub.png)

## Prerequisites

Ensure you meet all requirements in the [prerequisites](../../prerequisites/) before proceeding.

## Deploy the Lab

1. Clone the Git Repository for the Labs
```sh
git clone https://github.com/kaysalawu/azure-network-terraform.git
```

2. Navigate to the lab directory
```sh
cd azure-network-terraform/2-virtual-wan/2-virtual-wan-dual-hub
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
cd azure-network-terraform/2-virtual-wan/2-virtual-wan-dual-hub
```

2. Delete the resource group to remove all resources installed.\
Run the following Azure CLI command:

```sh
az group delete -g VwanS2RG --no-wait
```
