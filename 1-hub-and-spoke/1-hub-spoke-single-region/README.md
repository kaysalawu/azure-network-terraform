# Hub and Spoke - Single Region <!-- omit from toc -->

Table of Contents 
- [Overview](#overview)
- [Prerequisites](#prerequisites)
- [Deploy the Lab](#deploy-the-lab)
- [Troubleshooting](#troubleshooting)
- [Testing](#testing)
- [Cleanup](#cleanup)

## Overview

This terraform code deploys a hub and spoke topology playground to observe dynamic routing with Azure Route Server (ARS) and a Network Virtual Appiance (NVA).

`Hub1` ARS with BGP session to a Network Virtual Appliance (NVA) using a Cisco-CSR-100V router. The direct spokes `Spoke1` and `Spoke2` have VNET peering to `Hub1`. An isolated `Spoke3` does not have VNET peering to the hub, but is reachable from `Hub1` via Private Link Service.
 
`Branch1` is the on-premises network which is simulated in a VNET using a multi-NIC Cisco-CSR-100V NVA appliance. 

![Hub and Spoke (Single region)](../../images/hub-spoke-single-region.png)

## Prerequisites

Ensure you meet all requirements in the [prerequisites](../../prerequisites/) before proceeding.

## Deploy the Lab

1. Clone the Git Repository for the Labs
```sh
git clone https://github.com/kaysalawu/azure-network-terraform.git
```

2. Navigate to the lab directory
```sh
cd azure-network-terraform/1-hub-and-spoke/1-hub-spoke-single-region
```

3. Run the following terraform commands and type **yes** at the prompt:
```hcl
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
cd azure-network-terraform/1-hub-and-spoke/1-hub-spoke-single-region
```

2. Delete the resource group to remove all resources installed.\
Run the following Azure CLI command:

```sh
az group delete -g HubSpokeS1RG --no-wait
```
