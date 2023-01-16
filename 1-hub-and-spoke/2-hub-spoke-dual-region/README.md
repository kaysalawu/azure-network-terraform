# Hub and Spoke - Dual Region

## Overview

This terraform code deploys a multi-region standard hub and spoke topology playground.

`Hub1` has an Azure Route Server (ARS) with BGP session to a Network Virtual Appliance (NVA) using a Cisco-CSR-100V router. The direct spokes `Spoke1` and `Spoke2` have VNET peering to `Hub1`. An isolated `Spoke3` does not have VNET peering to the ``Hub1, but is reachable from the hub via Private Link Service.

`Hub2` has an ARS with BGP session to an NVA using a Cisco-CSR-100V router. The direct spokes `Spoke4` and `Spoke5` have VNET peering to `Hub2`. An isolated `Spoke6` does not have VNET peering to the `Hub2`, but is reachable from the hub via Private Link Service.

The hubs are connected together via IPsec VPN and BGP dynamic routing to allow multi-region network reachability.

`Branch1` and `Branch3`are the on-premises networks which are simulated in VNETs using multi-NIC Cisco-CSR-100V NVA appliances.

![Hub and Spoke (Dual region)](../../images/hub-spoke-dual-region.png)

### Recommended additional reading

1. [DIY vWAN: double Hub VNET and Azure Route Server](https://github.com/cynthiatreger/double-hub-vnet-and-ars) by [Cynthia Treger](https://github.com/cynthiatreger)
2. [Routing through Network Virtual Appliances with Azure Private Link](https://github.com/mddazure/azure-privatelink-routing) by [Marc De Droog](https://github.com/mddazure)

## Prerequisites

1. Ensure that you have setup [Azure Cloud Shell](https://learn.microsoft.com/en-us/azure/cloud-shell/overview) environment.
2. (Optional) If you prefer to run the code on a local terminal, ensure that you have installed and configured [Azure CLI](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli) and [Terraform](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli), and ignore step 3.
3. Launch a `Cloud Shell` terminal to be used for the remaining steps.

## Clone the Lab

Open a Cloud Shell terminal and run the following command:
1. Clone the Git Repository for the Labs
```sh
git clone https://github.com/kaysalawu/azure-network-terraform.git
```

2. Change to the lab directory
```sh
cd ~/azure-network-terraform/1-hub-and-spoke/2-hub-spoke-dual-region
```

## Deploy the Lab

To deploy the lab run the following terraform commands and type **yes** at the prompt:
```sh
terraform init
terraform plan
terraform apply
```

## Cleanup

Delete the resource group to remove all resources installed. Run the following Azure CLI command:

```sh
az group delete --name HubSpokeS2RG --yes --no-wait
```

## [Troubleshooting](../../troubleshooting/)

Go to the [troubleshooting](../../troubleshooting/) section for tips on how to resolve common issues that may occur during the deployment of the lab.
