# Network Egress Patterns <!-- omit from toc -->

## Lab: G10 <!-- omit from toc -->

Contents

- [Overview](#overview)
- [Prerequisites](#prerequisites)
- [Deploy the Lab](#deploy-the-lab)
- [Troubleshooting](#troubleshooting)
- [Outputs](#outputs)
- [Setup Test Environment](#setup-test-environment)
- [Egress Test Results](#egress-test-results)
  - [A. No Private Subnet, No Service Endpoints](#a-no-private-subnet-no-service-endpoints)
  - [B. Default Outbound and Service Tag UDR](#b-default-outbound-and-service-tag-udr)
  - [C. Default Outbound, Service Endpoints, and Service Tag UDR](#c-default-outbound-service-endpoints-and-service-tag-udr)
  - [D. Private Subnet and Service Endpoints](#d-private-subnet-and-service-endpoints)
  - [E. Private Subnet and Service Tag UDR](#e-private-subnet-and-service-tag-udr)
  - [F. Private Subnet, Service Endpoints, and Service Tag UDR](#f-private-subnet-service-endpoints-and-service-tag-udr)
  - [G. Mixed - Default Outbound and Private Subnet](#g-mixed---default-outbound-and-private-subnet)
- [Cleanup](#cleanup)

## Overview

This lab deploys a test environment to experiment with network egress patterns in Azure virtual networks. It demonstrates outbound access to Azure services with various combinations of service endpoints, private subnets, and User Defined Routes (UDR) using service tags.

<img src="./images/architecture.png" alt="Architecure" width="650">

## Prerequisites

Ensure you meet all requirements in the [prerequisites](../../prerequisites/README.md) before proceeding.

## Deploy the Lab

1. Clone the Git Repository for the Labs

   ```sh
   git clone https://github.com/kaysalawu/azure-network-terraform.git
   ```

2. Navigate to the lab directory

   ```sh
   cd azure-network-terraform/4-general/10-network-egress-scenarios
   ```

3. Run the following terraform commands and type ***yes*** at the prompt:

   ```sh
   terraform init
   terraform plan
   terraform apply -parallelism=50
   ```

## Troubleshooting

See the [troubleshooting](../../troubleshooting/README.md) section for tips on how to resolve common issues that may occur during the deployment of the lab.

## Outputs

The table below shows the auto-generated output files from the lab. They are located in the `output` directory.

| Item    | Description  | Location |
|--------|--------|--------|
| IP ranges and DNS | IP ranges and DNS hostname values | [output/values.md](./output/values.md) |
| Server1 | Cloud-init configuration | [output/hub-server1-init.yaml](./output/hub-server1-init.yaml) |
| Server2 | Cloud-init configuration | [output/hub-server2-init.yaml](./output/hub-server2-init.yaml) |
| Proxy | Cloud-init configuration | [output/hub-proxy-init.yaml](./output/hub-proxy-init.yaml) |
||||

## Setup Test Environment

Each virtual machine is pre-configured with a shell [script](../../scripts/server.sh) to run various types of network reachability tests. Serial console access has been configured for all virtual machines.

The virtual machines are also pre-configured with test scripts to check network reachability to various Azure services. The scripts are located in the [`/var/lib/azure/crawler/app/`](../../scripts/init/crawler/app) directory. The scripts can simply be run using the alias `crawlz` navigate to the directory and run the scripts.

The virtual machines are configured with system-assigned managed identities that have the **Network Contributor** role scoped to the resource group.

**1.** Login to virtual machine `G10-Proxy` via the [serial console](https://learn.microsoft.com/en-us/troubleshoot/azure/virtual-machines/serial-console-overview#access-serial-console-for-virtual-machines-via-azure-portal):
- Enter the login credentials
  - username = ***azureuser***
  - password = ***Password123***

**2.** Run `az login` to authenticate with the Azure CLI.

```sh
az login --identity
```

<details>

<summary>Sample output</summary>

```json
azureuser@branch1Vm:~$ az login --identity
[
  {
    "environmentName": "AzureCloud",
    "homeTenantId": "aaa-bbb-ccc-ddd-eee",
    "id": "xxx-yyy-1234-1234-1234",
    "isDefault": true,
    "managedByTenants": [
      {
        "tenantId": "your-tenant-id"
      }
    ],
    "name": "some-random-name",
    "state": "Enabled",
    "tenantId": "your-tenant-id",
    "user": {
      "assignedIdentityInfo": "MSI",
      "name": "systemAssignedIdentity",
      "type": "servicePrincipal"
    }
  }
]
```

</details>
<p>

## Egress Test Results

<table>
  <tr>
   <td rowspan="2" ><strong>Scenario</strong></td>
   <td rowspan="2" ><strong>Service Endpoint</strong></td>
   <td rowspan="2" ><strong>Private Subnet</strong></td>
   <td colspan="4" ><strong>Public IP Type</strong></td>
   <td rowspan="2" ><strong>Azure Mgmt Access?</strong></td>
   <td rowspan="2" ><strong>Internet Access?</strong></td>
   <td colspan="2" ><strong>Azure Services Access?</strong></td>
  </tr>
  <tr>
   <td><strong>NAT GW</td>
   <td><strong>LB SNAT</strong></td>
   <td><strong>VM Public IP</strong></td>
   <td><strong>Default</strong></td>
   <td><strong>Storage</strong></td>
   <td><strong>KeyVault</strong></td>
  </tr>
  <tr>
   <td>A</td><td></td><td></td><td></td><td></td><td></td><td>X</td><td>Yes</td><td>Yes<td>Yes<td>Yes</td>
  </tr>
  <tr>
   <td>B</td><td>ON</td><td>OFF</td><td>Y</td><td>Z</td><td>A</td><td>Y</td><td>N</td><td>NA<td>NA<td>NA</td>
  </tr>
  <tr>
   <td>C</td><td>ON</td><td>OFF</td><td>Y</td><td>Z</td><td>A</td><td>Y</td><td>N</td><td>NA<td>NA<td>NA</td>
  </tr>
  <tr>
   <td>D</td><td>ON</td><td>OFF</td><td>Y</td><td>Z</td><td>A</td><td>Y</td><td>N</td><td>NA<td>NA<td>NA</td>
  </tr>
  <tr>
   <td>E</td><td>ON</td><td>OFF</td><td>Y</td><td>Z</td><td>A</td><td>Y</td><td>N</td><td>NA<td>NA<td>NA</td>
  </tr>
  <tr>
   <td>F</td><td>ON</td><td>OFF</td><td>Y</td><td>Z</td><td>A</td><td>Y</td><td>N</td><td>NA<td>NA<td>NA</td>
  </tr>
  <tr>
   <td>G</td><td>ON</td><td>OFF</td><td>Y</td><td>Z</td><td>A</td><td>Y</td><td>N</td><td>NA<td>NA<td>NA</td>
  </tr>
</table>

### A. No Private Subnet, No Service Endpoints

Test details:
* Test machine: `G10-Proxy`
* Subnet: `PublicSubnet`
* Result: Using the default outbound, the `G10-Proxy` can access the internet, Azure services, and management services. In this scenario access to all services and Internet is sourced from the default outbound public IP address.

```sh
----------------------------------------
Results
----------------------------------------
1. NAT_IP_Type:         No Explicit Outbound
2. Service_Endpoints:   False
3. Private_Subnet:      False
4. Internet_Access:     Yes
5. Management_Access:   Yes
6. Blob_Access:         Yes
7. KeyVault_Access:     Yes
```

<details>

<summary>Detailed Result</summary>

```sh
azureuser@Proxy:~$ crawlz

0. Preparing environment ...
   Environment setup completed!

1. Check Public Address Type
   VM Name:     G10-Proxy
   Location:    northeurope
   Local IP:    10.0.2.4
   Public IP:   13.74.249.251
   NAT_IP type: No Explicit Outbound

2. Check Service Endpoints
   Subnet --> PublicSubnet
   Service EP: False

3. Check Private Subnet
   Subnet --> PublicSubnet
   DefaultOutbound: true
   Private Subnet:  False

4. Check Internet Access
   Connecting to http://contoso.com ...
   Access: Yes (200)

5. Check Management Access
   52.146.134.240 <-- management.azure.com
   Searching for service tags matching 52.146.135.86
   - 52.146.134.0/23 <-- AzureResourceManager ()
   - 52.146.134.0/23 <-- AzureResourceManager.NorthEurope (northeurope)
   - 52.146.128.0/17 <-- AzureCloud.northeurope (northeurope)
   - 52.146.128.0/17 <-- AzureCloud ()
   Testing access to management.azure.com
   Access: Yes

6. Check Blob Access (Data Plane)
   url = https://g10hub123d.blob.core.windows.net/storage/storage.txt
   host = g10hub123d.blob.core.windows.net
   20.150.84.164 <-- g10hub123d.blob.core.windows.net
   Searching for service tags matching 20.150.84.164
   - 20.150.0.0/17 <-- Storage ()
   - 20.150.84.0/24 <-- Storage.NorthEurope (northeurope)
   - 20.150.84.0/24 <-- AzureCloud.northeurope (northeurope)
   - 20.150.84.0/24 <-- AzureCloud ()
   Retrieving blob content ...
   Content: Hello, World!
   Access: Yes

7. Check KeyVault Access (Data Plane)
   url: https://g10-hub-kv123d.vault.azure.net/secrets/message/<ID>
   host: g10-hub-kv123d.vault.azure.net
   52.146.137.169 <-- g10-hub-kv123d.vault.azure.net
   Searching for service tags matching 52.146.137.169
   - 52.146.137.168/29 <-- AzureKeyVault ()
   - 52.146.137.168/29 <-- AzureKeyVault.NorthEurope (northeurope)
   - 52.146.128.0/17 <-- AzureCloud.northeurope (northeurope)
   - 52.146.128.0/17 <-- AzureCloud ()
   Accessing secret ...
   message: Hello, world!
   Access: Yes

----------------------------------------
Results
----------------------------------------
1. NAT_IP_Type:         No Explicit Outbound
2. Service_Endpoints:   False
3. Private_Subnet:      False
4. Internet_Access:     Yes
5. Management_Access:   Yes
6. Blob_Access:         Yes
7. KeyVault_Access:     Yes
```

</details>
<p>

<img src="./images/egress-scenario-a.png" alt="Scenario A" width="800">

### B. Default Outbound and Service Tag UDR

<img src="./images/egress-scenario-b.png" alt="Scenario B" width="700">

<table>
  <tr>
   <td rowspan="2" ><strong>Subnet</strong></td>
   <td rowspan="2" ><strong>Service Endpoint</strong></td>
   <td rowspan="2" ><strong>Private Subnet</strong></td>
   <td rowspan="2" ><strong>Service Tag UDR</strong></td>
   <td colspan="4" ><strong>Public IP Type</strong></td>
   <td rowspan="2" ><strong>Azure Mgmt Access?</strong></td>
   <td rowspan="2" ><strong>Internet Access?</strong></td>
   <td colspan="2" ><strong>Access to Azure Services?</strong></td>
  </tr>
  <tr>
   <td><strong>NAT GW</td>
   <td><strong>LB SNAT</strong></td>
   <td><strong>Public IP</strong></td>
   <td><strong>Default</strong></td>
   <td><strong>Storage</strong></td>
   <td><strong>KeyVault</strong></td>
  </tr>
  <tr>
   <td>Production</td><td>ON</td><td>OFF</td><td>X</td><td>Y</td><td>Z</td><td>A</td><td>Y</td><td>N</td><td>NA<td>NA<td>NA</td>
  </tr>
  <tr>
   <td>Public</td><td>ON</td><td>OFF</td><td>X</td><td>Y</td><td>Z</td><td>A</td><td>Y</td><td>N</td><td>NA<td>NA<td>NA</td>
  </tr>
  <tr>
   <td>Gateway</td><td>ON</td><td>OFF</td><td>X</td><td>Y</td><td>Z</td><td>A</td><td>Y</td><td>N</td><td>NA<td>NA<td>NA</td>
  </tr>
  <tr>
   <td>App Gateway</td><td>ON</td><td>OFF</td><td>X</td><td>Y</td><td>Z</td><td>A</td><td>Y</td><td>N</td><td>NA<td>NA<td>NA</td>
  </tr>
</table>

### C. Default Outbound, Service Endpoints, and Service Tag UDR

<img src="./images/egress-scenario-c.png" alt="Scenario C" width="700">


### D. Private Subnet and Service Endpoints

<img src="./images/egress-scenario-d.png" alt="Scenario D" width="700">



### E. Private Subnet and Service Tag UDR

<img src="./images/egress-scenario-e.png" alt="Scenario E" width="700">



### F. Private Subnet, Service Endpoints, and Service Tag UDR

<img src="./images/egress-scenario-f.png" alt="Scenario F" width="700">



### G. Mixed - Default Outbound and Private Subnet



## Cleanup

1\. (Optional) Navigate back to the lab directory (if you are not already there)

```sh
cd azure-network-terraform/4-general/10-network-egress-scenarios
```

2\. (Optional) This is not required if `enable_diagnostics = false` in the [`main.tf`](./02-main.tf). If you deployed the lab with `enable_diagnostics = true`, in order to avoid terraform errors when re-deploying this lab, run a cleanup script to remove diagnostic settings that are not removed after the resource group is deleted.

```sh
bash ../../scripts/_cleanup.sh G10_SapNetworking_RG
```

<details>

<summary>Sample output</summary>

```sh
3-hub-spoke-nva-single-region$    bash ../../scripts/_cleanup.sh G10_SapNetworking_RG

Resource group: G10RG

⏳ Checking for diagnostic settings on resources in G10_SapNetworking_RG ...
➜  Checking firewall ...
➜  Checking vnet gateway ...
    ❌ Deleting: diag setting [G10-ecs-vpngw-diag] for vnet gateway [G10-ecs-vpngw] ...
➜  Checking vpn gateway ...
➜  Checking er gateway ...
➜  Checking app gateway ...
⏳ Checking for azure policies in G10RG ...
Done!
```

</details>
<p>

3\. Delete the resource group to remove all resources installed.

```sh
az group delete -g G10_SapNetworking_RG --no-wait
```

4\. Delete terraform state files and other generated files.

```sh
rm -rf .terraform*
rm terraform.tfstate*
```
