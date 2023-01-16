
# Virtual WAN - Single Hub (Mixed)

## Overview

This terraform code deploys a virtual WAN architecture playground to observe dynamic routing patterns. 

In this architecture, we integrate a standard hub (`hub1`) to the virtual WAN hub (`vHub1`) via a virtual WAN connection. `vHub1` has a direct spoke (`Spoke1`) connected using a virtual WAN connection. `Spoke2` is an indirect spoke from a virtual WAN perspective; and is connected via standard VNET peering to `Hub1`. 

The isolated spoke (`Spoke3`) does not have VNET peering to the `Hub1`, but is reachable via Private Link Service through a private endpoint in `Hub1`.

`Branch1` is the on-premises network which is simulated in a VNET using a multi-NIC Cisco-CSR-100V NVA appliance.

![Virtual WAN (Single Hub)](../../images/vwan-single-hub.png)

## Lab Prerequisites

Ensure you meet all requirements in the [prerequisites](../../prerequisites/) before proceeding.

## Clone the Lab

Open a Cloud Shell terminal and run the following command:
1. Clone the Git Repository for the Labs
```sh
git clone https://github.com/kaysalawu/azure-network-terraform.git
```

2. Change to the lab directory
```sh
cd azure-network-terraform/2-virtual-wan/1-virtual-wan-single-hub
```

## Deploy the Lab

To deploy the lab run the following terraform commands and type **yes** at the prompt:
```sh
terraform init
terraform plan
terraform apply
```

## Troubleshooting

See the [troubleshooting](../../troubleshooting/) section for tips on how to resolve common issues that may occur during the deployment of the lab.

## Cleanup

1. Change to the lab directory
```sh
cd azure-network-terraform/2-virtual-wan/1-virtual-wan-single-hub
```

2. Delete the resource group to remove all resources installed.\
Run the following Azure CLI command:

```sh
az group delete -g VwanS1RG --no-wait
```
