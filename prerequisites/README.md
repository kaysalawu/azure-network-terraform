
# Prerequisites

1. Ensure that you have [setup your Azure Cloud Shell](https://learn.microsoft.com/en-us/azure/cloud-shell/overview) environment.
2. (Optional) If you prefer to run the code on a local bash terminal, ensure that you have installed and configured [Azure CLI](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli) and [-hub2-azfw](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli); and ignore step 3.
3. Log in to Azure [Cloud Shell](https://shell.azure.com) and select `Bash` terminal.
> **Cloud Shell Timeout**
>
> The machine that provides the Cloud Shell session is temporary, and is recycled after your session is inactive for 20 minutes. Ensure that your session does not remain inactive for 20 minutes.
4. Set your Azure subscription
```sh
az account set --subscription <Name or ID of subscription>
```
5. Accept the Azure marketplace terms for the images used in this lab:
```sh
az vm image terms accept --urn cisco:cisco-csr-1000v:17_2_1-byol:latest
az vm image terms accept --urn cisco:cisco-csr-1000v:17_3_4a-byol:latest
az vm image terms accept --urn thefreebsdfoundation:freebsd-13_1:13_1-release:13.1.0 -o none
```
6. Ensure you have the Azure CLI extension for Virtual WAN:
```sh
az extension add --name virtual-wan
az extension add --name log-analytics
```
7. Ensure that Azure CLI and extensions are up to date:
```sh
az upgrade --yes
```
