
# Prerequisites

## 1. Using Cloudshell Bash (Option 1)

1. Ensure that you have [setup your Azure Cloud Shell](https://learn.microsoft.com/en-us/azure/cloud-shell/overview) environment.

2. Log in to Azure [Cloud Shell](https://shell.azure.com) and select `Bash` terminal.

   > **Cloud Shell Timeout**
   >
   > The machine that provides the Cloud Shell session is temporary, and is recycled after your session > is inactive for 20 minutes. Ensure that your session does not remain inactive for 20 minutes.

If you prefer to run the code on a local bash terminal, then proceed to [Option 2](#using-local-linux-machine-option-2).

## 2. Using Local Linux Machine (Option 2)

To use a local Linux machine, do the following:

1. Ensure that you have installed and configured [Azure CLI](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli)
2. Ensure that you have installed [Terraform](https://learn.hashicorp.com/tutorials/terraform/install-cli)

## 3. Remaining Steps

Run the following commands to ensure that your environment is ready for the lab:

1. Set your Azure subscription

   ```sh
   az account set --subscription <Name or ID of subscription>
   ```

2. Accept the Azure marketplace terms for the images used in this lab:
   ```sh
   az vm image terms accept --urn cisco:cisco-csr-1000v:17_2_1-byol:latest
   az vm image terms accept --urn cisco:cisco-csr-1000v:17_3_4a-byol:latest
   az vm image terms accept --urn thefreebsdfoundation:freebsd-13_1:13_1-release:13.1.0 -o none
   ```

3. Ensure you have the Azure CLI extension for Virtual WAN:
   ```sh
   az extension add --name virtual-wan
   az extension add --name log-analytics
   az extension add --name resource-graph
   ```

4. Ensure that Azure CLI and extensions are up to date:
   ```sh
   az upgrade --yes
   ```

5. Run some additional commands:
   ```sh
   az config set extension.use_dynamic_install=yes_without_prompt
   ```
