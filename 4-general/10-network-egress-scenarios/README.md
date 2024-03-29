# Network Egress Patterns <!-- omit from toc -->

## Lab: G10 <!-- omit from toc -->

Contents

- [Overview](#overview)
- [Prerequisites](#prerequisites)
- [Deploy the Lab](#deploy-the-lab)
- [Troubleshooting](#troubleshooting)
- [Outputs](#outputs)
- [Accessing the Test Servers](#accessing-the-test-servers)
- [Test Results](#test-results)
  - [A. Default Outbound, Private-Subnet = Off, Service-Endpoint = Off](#a-default-outbound-private-subnet--off-service-endpoint--off)
  - [B. NAT-Gateway, Private-Subnet = On, Service-Endpoint = Off](#b-nat-gateway-private-subnet--on-service-endpoint--off)
  - [C. NAT-Gateway, Private-Subnet = On, Service-Endpoint = On](#c-nat-gateway-private-subnet--on-service-endpoint--on)
  - [D. No Public IP, Private-Subnet = On, Service-Endpoint = On](#d-no-public-ip-private-subnet--on-service-endpoint--on)
  - [E. Outbound Access via Proxy](#e-outbound-access-via-proxy)
  - [F. No Explicit Public IP, Private-Subnet = Off, Service-Endpoint = Off](#f-no-explicit-public-ip-private-subnet--off-service-endpoint--off)
- [Cleanup](#cleanup)

## Overview

This lab deploys a test environment to experiment with network egress patterns in Azure virtual networks. It demonstrates outbound access to Azure services with various combinations of service endpoints, private subnets, and User Defined Routes (UDR) using service tags.

<img src="./images/architecture.png" alt="Architecure" width="650">

## Prerequisites

Ensure you meet all requirements in the [prerequisites](../../prerequisites/README.md) before proceeding.

## Deploy the Lab

 ```sh
 git clone https://github.com/kaysalawu/azure-network-terraform.git
 cd azure-network-terraform/4-general/10-network-egress-scenarios
 terraform init
 terraform plan
 terraform apply -parallelism=50
 ```

## Troubleshooting

See the [troubleshooting](../../troubleshooting/README.md) section for tips on how to resolve common issues that may occur during the deployment of the lab.

## Outputs

The table below shows the generated output files from the lab. They are located in the `output` directory.

| Item    | Description  | Location |
|--------|--------|--------|
| Server1 | Service test scripts | [output/server1-crawler.sh](./output/server1-crawler.sh) |
| Server2 | Service test scripts | [output/server2-crawler.sh](./output/server2-crawler.sh) |
| Proxy | Service test scripts | [output/proxy-crawler.sh](./output/proxy-crawler.sh) |
||||

## Accessing the Test Servers

<details>

<summary>Accessing the Test Servers</summary>

The virtual machines are pre-configured with test scripts to check network reachability to various Azure services. The scripts are located in the [`/var/lib/azure/crawler/app/`](../../scripts/init/crawler/app) directory. The scripts can simply be run using the alias `crawlz` navigate to the directory and run the scripts.

The test VMs are configured with system-assigned managed identities that have the **Network Contributor** role scoped to the resource group. Serial console access has been configured for all VMs.

**1.** Login to any virtual machine via the [serial console](https://learn.microsoft.com/en-us/troubleshoot/azure/virtual-machines/serial-console-overview#access-serial-console-for-virtual-machines-via-azure-portal):
- Enter the login credentials
  - username = ***azureuser***
  - password = ***Password123***

**2.** Run `az login` to authenticate with the Azure CLI.

```sh
az login --identity
```

From here, you can run the `crawlz` command to test service reachability to various Azure services as shown in the following sections. The lab is designed to be run sequentially to achieve the results described in the following sections.
   <td rowspan="2" ><strong>Azure Mgmt Access?</strong></td>
   <td rowspan="2" ><strong>Internet Access?</strong></td>
   <td colspan="2" ><strong>Data Plane Access?</strong></td>
</details>
<p>

## Test Results

<table>
  <tr>
   <td rowspan="2" ><strong></strong></td>
   <td colspan="2" ><strong>Test Server</strong></td>
   <td colspan="3" ><strong>Configuration Setting</strong></td>
   <td rowspan="2" ><strong>Internet Access?</strong></td>
   <td rowspan="2" ><strong>Mgmt Access?</strong></td>
   <td colspan="3" ><strong>Data Plane Access?</strong></td>
  </tr>
  <tr>
   <td><strong>Name</strong></td>
   <td><strong>Subnet</strong></td>
   <td><strong>Service Endpoint</strong></td>
   <td><strong>Private Subnet</strong></td>
   <td><strong>Explicit Public IP</strong></td>
   <td><strong>Storage</strong></td>
   <td><strong>Key Vault</strong></td>
  </tr>
  <tr>
   <td>A</td><td>Proxy</td><td>Public</td><td></td><td></td><td></td><td>Yes</td><td>Yes</td><td>Yes</td><td>Yes</td>
  </tr>
  <tr>
   <td>B</td><td>Server1</td><td>Production</td><td>✔️</td><td>✔️</td><td>✔️</td><td>Yes</td><td>Yes</td><td>Yes</td><td>Yes</td>
  </tr>
  <tr>
   <td>C</td><td>Server1</td><td>Production</td><td>✔️</td><td>✔️</td><td>✔️</td><td>Yes</td><td>Yes</td><td>Yes</td><td>Yes</td>
  </tr>
  <tr>
   <td>D</td><td>Server1</td><td>Production</td><td>✔️</td><td>✔️</td><td></td><td>No</td><td>No</td><td>Yes</td><td>Yes</td>
  </tr>
  <tr>
   <td>E</td><td>Proxy</td><td>Public<td></td></td><td></td><td></td><td>No</td><td>No</td><td>No</td><td>No</td>
  </tr>
</table>

### A. Default Outbound, Private-Subnet = Off, Service-Endpoint = Off

The [default outbound access](https://learn.microsoft.com/en-us/azure/virtual-network/ip-services/default-outbound-access#how-is-default-outbound-access-provided) is used in this scenario because there is no explicit outbound method deployed (NAT gateway, load balancer SNAT, or VM public IP). Default outbound access is [not recommended for security reasons](https://learn.microsoft.com/en-us/azure/virtual-network/ip-services/default-outbound-access#why-is-disabling-default-outbound-access-recommended).

Access patterns for `G10-Proxy`:
- Default outbound is used for internet access
- Default outbound is used for Azure management operations (management.azure.com)
- Default outbound is used for data plane access to blob.core.windows.net and vault.azure.net.

<p>
<img src="./images/egress-scenario-a.png" alt="Scenario A" width="650">
<p>

**Summary:**

```sh
-------------------------------------
Environment
-------------------------------------
VM Name:        G10-Proxy
Resource Group: G10_NetworkEgress_RG
Location:       northeurope
VNET Name:      G10-hub-vnet
Subnet Name:    PublicSubnet
Private IP:     10.0.2.4
-------------------------------------
Results
-------------------------------------
1. NAT IP Type:         None
2. Service Endpoints:   Disabled
3. Private Subnet:      Disabled
4. Internet Access:     Pass
5. Management Access:   Pass
6. Blob Dataplane:      Pass
7. KeyVault Dataplane:  Pass
-------------------------------------
```

<p>
<details>

<summary>Test instructions</summary>

Private subnet is already enabled on `ProductionSubnet`. The subnet is also already associated with a NAT gateway.

1\. Login to `G10-Proxy` VM as described in the [Test Servers](#accessing-the-test-servers) section.

2\. Run the command `crawlz` to test network reachability.

</details>
<p>

</details>
<p>

<details>

<summary>Detailed Result</summary>

```sh
azureuser@Proxy:~$ crawlz

Extracting az token...
Downloading service tags JSON...

-------------------------------------
Environment
-------------------------------------
VM Name:        G10-Proxy
Resource Group: G10_NetworkEgress_RG
Location:       northeurope
VNET Name:      G10-hub-vnet
Subnet Name:    PublicSubnet
Private IP:     10.0.2.4
-------------------------------------

1. Check Public Address Type
   Local IP:    10.0.2.4
   Public IP:   13.79.170.14
   NAT_IP type: None

2. Check Service Endpoints
   Subnet --> PublicSubnet
   Service Endpoint: Disabled

3. Check Private Subnet
   Subnet --> PublicSubnet
   DefaultOutbound: true
   Private Subnet:  Disabled

4. Check Internet Access
   curl https://ifconfig.me
   Internet Access: Pass (200)

5. Management (Control Plane)
   url = https://management.azure.com/subscriptions?api-version=2020-01-01
   host = management.azure.com
   52.146.135.86 <-- management.azure.com
   Searching for service tags matching IP (52.146.135.86)
   - 52.146.134.0/23 <-- AzureResourceManager ()
   - 52.146.134.0/23 <-- AzureResourceManager.NorthEurope (northeurope)
   - 52.146.128.0/17 <-- AzureCloud.northeurope (northeurope)
   - 52.146.128.0/17 <-- AzureCloud ()
   curl -H Authorization : Bearer TOKEN https://management.azure.com/subscriptions?api-version=2020-01-01
   Management Access: Pass (200)

6. Blob (Data Plane)
   url = https://g10hube9c6.blob.core.windows.net/storage/storage.txt
   host = g10hube9c6.blob.core.windows.net
   20.60.205.164 <-- g10hube9c6.blob.core.windows.net
   Searching for service tags matching IP (20.60.205.164)
   - 20.60.0.0/16 <-- Storage ()
   - 20.60.204.0/23 <-- Storage.NorthEurope (northeurope)
   - 20.60.204.0/23 <-- AzureCloud.northeurope (northeurope)
   - 20.60.204.0/23 <-- AzureCloud ()
   az storage account keys list -g G10_NetworkEgress_RG --account-name g10hube9c6
   az storage blob download --account-name g10hube9c6 -c storage -n storage.txt --account-key <KEY>
   Content: Hello, World!
   Blob Dataplane: Pass

7. KeyVault (Data Plane)
   url: https://g10-hub-kve9c6.vault.azure.net/secrets/message
   host: g10-hub-kve9c6.vault.azure.net
   52.146.137.168 <-- g10-hub-kve9c6.vault.azure.net
   Searching for service tags matching IP (52.146.137.168)
   - 52.146.137.168/29 <-- AzureKeyVault ()
   - 52.146.137.168/29 <-- AzureKeyVault.NorthEurope (northeurope)
   - 52.146.128.0/17 <-- AzureCloud.northeurope (northeurope)
   - 52.146.128.0/17 <-- AzureCloud ()
   az keyvault secret show --vault-name g10-hub-kve9c6 --name message
   message: Hello, World!
   Vault Dataplane: Pass

-------------------------------------
Results
-------------------------------------
1. NAT IP Type:         None
2. Service Endpoints:   Disabled
3. Private Subnet:      Disabled
4. Internet Access:     Pass
5. Management Access:   Pass
6. Blob Dataplane:      Pass
7. KeyVault Dataplane:  Pass
-------------------------------------
```

</details>
<p>

### B. NAT-Gateway, Private-Subnet = On, Service-Endpoint = Off

In this scenario, private subnet is enabled on `ProductionSubnet` which is associated with a NAT gateway.

Access patterns for `G10-Server1`:
- NAT gateway Public IP is used for internet access
- NAT gateway Public IP is used for Azure management operations (management.azure.com)
- NAT gateway Public IP is used for data plane access to blob.core.windows.net and vault.azure.net.

<p>
<img src="./images/egress-scenario-b.png" alt="Scenario B" width="650">
<p>

**Summary:**

```sh
-------------------------------------
Environment
-------------------------------------
VM Name:        G10-Server1
Resource Group: G10_NetworkEgress_RG
Location:       northeurope
VNET Name:      G10-hub-vnet
Subnet Name:    ProductionSubnet
Private IP:     10.0.3.4
-------------------------------------
Results
-------------------------------------
1. NAT IP Type:         NatGw
2. Service Endpoints:   Disabled
3. Private Subnet:      Enabled
4. Internet Access:     Pass
5. Management Access:   Pass
6. Blob Dataplane:      Pass
7. KeyVault Dataplane:  Pass
-------------------------------------
```

<p>
<details>

<summary>Test instructions</summary>

Private subnet is already enabled on `ProductionSubnet`. The subnet is also already associated with a NAT gateway.

1\. Login to `G10-Server1` VM as described in the [Test Servers](#accessing-the-test-servers) section.

2\. Run the command `crawlz` to test network reachability.

</details>
<p>

<details>

<summary>Detailed Result</summary>

```sh
azureuser@Server1:~$ crawlz

Extracting az token...
Downloading service tags JSON...

-------------------------------------
Environment
-------------------------------------
VM Name:        G10-Server1
Resource Group: G10_NetworkEgress_RG
Location:       northeurope
VNET Name:      G10-hub-vnet
Subnet Name:    ProductionSubnet
Private IP:     10.0.3.4
-------------------------------------

1. Check Public Address Type
   Local IP:    10.0.3.4
   Public IP:   40.69.44.72
   Address type: NatGw

2. Check Service Endpoints
   Subnet --> ProductionSubnet
   Service Endpoint: Disabled

3. Check Private Subnet
   Subnet --> ProductionSubnet
   DefaultOutbound: false
   Private Subnet:  Enabled

4. Check Internet Access
   curl https://ifconfig.me
   Internet Access: Pass (200)

5. Management (Control Plane)
   url = https://management.azure.com/subscriptions?api-version=2020-01-01
   host = management.azure.com
   52.146.135.86 <-- management.azure.com
   Searching for service tags matching IP (52.146.135.86)
   - 52.146.134.0/23 <-- AzureResourceManager ()
   - 52.146.134.0/23 <-- AzureResourceManager.NorthEurope (northeurope)
   - 52.146.128.0/17 <-- AzureCloud.northeurope (northeurope)
   - 52.146.128.0/17 <-- AzureCloud ()
   curl -H Authorization : Bearer TOKEN https://management.azure.com/subscriptions?api-version=2020-01-01
   Management Access: Pass (200)

6. Blob (Data Plane)
   url = https://g10hube9c6.blob.core.windows.net/storage/storage.txt
   host = g10hube9c6.blob.core.windows.net
   20.60.205.164 <-- g10hube9c6.blob.core.windows.net
   Searching for service tags matching IP (20.60.205.164)
   - 20.60.0.0/16 <-- Storage ()
   - 20.60.204.0/23 <-- Storage.NorthEurope (northeurope)
   - 20.60.204.0/23 <-- AzureCloud.northeurope (northeurope)
   - 20.60.204.0/23 <-- AzureCloud ()
   az storage account keys list -g G10_NetworkEgress_RG --account-name g10hube9c6
   az storage blob download --account-name g10hube9c6 -c storage -n storage.txt --account-key <KEY>
   Content: Hello, World!
   Blob Dataplane: Pass

7. KeyVault (Data Plane)
   url: https://g10-hub-kve9c6.vault.azure.net/secrets/message
   host: g10-hub-kve9c6.vault.azure.net
   52.146.137.168 <-- g10-hub-kve9c6.vault.azure.net
   Searching for service tags matching IP (52.146.137.168)
   - 52.146.137.168/29 <-- AzureKeyVault ()
   - 52.146.137.168/29 <-- AzureKeyVault.NorthEurope (northeurope)
   - 52.146.128.0/17 <-- AzureCloud.northeurope (northeurope)
   - 52.146.128.0/17 <-- AzureCloud ()
   az keyvault secret show --vault-name g10-hub-kve9c6 --name message
   message: Hello, World!
   Vault Dataplane: Pass

-------------------------------------
Results
-------------------------------------
1. NAT IP Type:         NatGw
2. Service Endpoints:   Disabled
3. Private Subnet:      Enabled
4. Internet Access:     Pass
5. Management Access:   Pass
6. Blob Dataplane:      Pass
7. KeyVault Dataplane:  Pass
-------------------------------------
```

</details>
<p>

### C. NAT-Gateway, Private-Subnet = On, Service-Endpoint = On

In this scenario, private subnet is enabled on `ProductionSubnet` which is associated with a NAT gateway. Service endpoints for storage and key vault are also enabled.

Access patterns for `G10-Server1`:
- NAT gateway Public IP is used for internet access
- NAT gateway Public IP is used for Azure management operations (management.azure.com)
- Service endpoints are used for data plane access to blob.core.windows.net and vault.azure.net.

<p>
<img src="./images/egress-scenario-c.png" alt="Scenario C" width="650">
<p>

**Summary:**

```sh
-------------------------------------
Environment
-------------------------------------
VM Name:        G10-Server1
Resource Group: G10_NetworkEgress_RG
Location:       northeurope
VNET Name:      G10-hub-vnet
Subnet Name:    ProductionSubnet
Private IP:     10.0.3.4
-------------------------------------
Results
-------------------------------------
1. NAT IP Type:         NatGw
2. Service Endpoints:   Enabled
3. Private Subnet:      Enabled
4. Internet Access:     Pass
5. Management Access:   Pass
6. Blob Dataplane:      Pass
7. KeyVault Dataplane:  Pass
-------------------------------------
```

<details>

<summary>Test instructions</summary>

1\. Enable service endpoints on `ProductionSubnet`

```sh
az network vnet subnet update \
-g G10_NetworkEgress_RG \
--vnet-name G10-hub-vnet \
--name ProductionSubnet \
--service-endpoints Microsoft.Storage Microsoft.KeyVault Microsoft.AzureActiveDirectory
```

2\. Run the command `crawlz` on `G10-Server1` terminal.

</details>
<p>

<details>

<summary>Detailed Result</summary>

```sh
azureuser@Server1:~$ crawlz

Extracting az token...
Downloading service tags JSON...

-------------------------------------
Environment
-------------------------------------
VM Name:        G10-Server1
Resource Group: G10_NetworkEgress_RG
Location:       northeurope
VNET Name:      G10-hub-vnet
Subnet Name:    ProductionSubnet
Private IP:     10.0.3.4
-------------------------------------

1. Check Public Address Type
   Local IP:    10.0.3.4
   Public IP:   40.69.44.72
   Address type: NatGw

2. Check Service Endpoints
   Subnet --> ProductionSubnet
   Service Endpoint: Enabled
   - Microsoft.Storage
   - Microsoft.KeyVault
   - Microsoft.AzureActiveDirectory

3. Check Private Subnet
   Subnet --> ProductionSubnet
   DefaultOutbound: false
   Private Subnet:  Enabled

4. Check Internet Access
   curl https://ifconfig.me
   Internet Access: Pass (200)

5. Management (Control Plane)
   url = https://management.azure.com/subscriptions?api-version=2020-01-01
   host = management.azure.com
   52.146.135.86 <-- management.azure.com
   Searching for service tags matching IP (52.146.135.86)
   - 52.146.134.0/23 <-- AzureResourceManager ()
   - 52.146.134.0/23 <-- AzureResourceManager.NorthEurope (northeurope)
   - 52.146.128.0/17 <-- AzureCloud.northeurope (northeurope)
   - 52.146.128.0/17 <-- AzureCloud ()
   curl -H Authorization : Bearer TOKEN https://management.azure.com/subscriptions?api-version=2020-01-01
   Management Access: Pass (200)

6. Blob (Data Plane)
   url = https://g10hube9c6.blob.core.windows.net/storage/storage.txt
   host = g10hube9c6.blob.core.windows.net
   20.60.205.164 <-- g10hube9c6.blob.core.windows.net
   Searching for service tags matching IP (20.60.205.164)
   - 20.60.0.0/16 <-- Storage ()
   - 20.60.204.0/23 <-- Storage.NorthEurope (northeurope)
   - 20.60.204.0/23 <-- AzureCloud.northeurope (northeurope)
   - 20.60.204.0/23 <-- AzureCloud ()
   az storage account keys list -g G10_NetworkEgress_RG --account-name g10hube9c6
   az storage blob download --account-name g10hube9c6 -c storage -n storage.txt --account-key <KEY>
   Content: Hello, World!
   Blob Dataplane: Pass

7. KeyVault (Data Plane)
   url: https://g10-hub-kve9c6.vault.azure.net/secrets/message
   host: g10-hub-kve9c6.vault.azure.net
   52.146.137.168 <-- g10-hub-kve9c6.vault.azure.net
   Searching for service tags matching IP (52.146.137.168)
   - 52.146.137.168/29 <-- AzureKeyVault ()
   - 52.146.137.168/29 <-- AzureKeyVault.NorthEurope (northeurope)
   - 52.146.128.0/17 <-- AzureCloud.northeurope (northeurope)
   - 52.146.128.0/17 <-- AzureCloud ()
   az keyvault secret show --vault-name g10-hub-kve9c6 --name message
   message: Hello, World!
   Vault Dataplane: Pass

-------------------------------------
Results
-------------------------------------
1. NAT IP Type:         NatGw
2. Service Endpoints:   Enabled
3. Private Subnet:      Enabled
4. Internet Access:     Pass
5. Management Access:   Pass
6. Blob Dataplane:      Pass
7. KeyVault Dataplane:  Pass
-------------------------------------
```

</details>
<p>

### D. No Public IP, Private-Subnet = On, Service-Endpoint = On

In this scenario, we will dissociate `ProductionSubnet` from the NAT gateway. As a result, the server `G10-Server1` will not have a public IP address. Service endpoints for storage and key vault will remain enabled.

Access patterns for `G10-Server1`:
- No access to internet access which requires a public IP
- No access to Azure management operations (management.azure.com) which requires a public IP
- Service endpoints are used for data plane access to blob.core.windows.net and vault.azure.net.

<p>
<img src="./images/egress-scenario-d.png" alt="Scenario D" width="700">
<p>

**Summary:**

```sh
-------------------------------------
Environment
-------------------------------------
VM Name:        G10-Server1
Resource Group: G10_NetworkEgress_RG
Location:       northeurope
VNET Name:      G10-hub-vnet
Subnet Name:    ProductionSubnet
Private IP:     10.0.3.4
-------------------------------------
Results
-------------------------------------
1. NAT IP Type:         None
2. Service Endpoints:   Timed out!
3. Private Subnet:      Timed out!
4. Internet Access:     Timed out!
5. Management Access:   Timed out!
6. Blob Dataplane:      Pass
7. KeyVault Dataplane:  Pass
-------------------------------------
```

<details>

<summary>Test instructions</summary>

**Test instructions:**

1\. Disable NAT gateway for `ProductionSubnet`

```sh
az network vnet subnet update \
-g G10_NetworkEgress_RG \
--vnet-name G10-hub-vnet \
--name ProductionSubnet \
--remove natGateway
```

2\. Re-apply terraform to remove the subnet association with the NAT gateway.

3\. Login to `G10-Server1` VM as described in the [Test Servers](#test-servers) section.

4\. Run the command `crawlz` to test network reachability.

</details>
<p>

<details>

<summary>Detailed Result</summary>

```sh
azureuser@Server1:~$ crawlz

Extracting az token...
Downloading service tags JSON...

-------------------------------------
Environment
-------------------------------------
VM Name:        G10-Server1
Resource Group: G10_NetworkEgress_RG
Location:       northeurope
VNET Name:      G10-hub-vnet
Subnet Name:    ProductionSubnet
Private IP:     10.0.3.4
-------------------------------------

1. Check Public Address Type
   Local IP:    10.0.3.4
   Public IP:
   Address type: None

2. Check Service Endpoints
   Subnet --> ProductionSubnet
   Service Endpoint: Timed out!

3. Check Private Subnet
   Subnet --> ProductionSubnet
   DefaultOutbound: Timed out!
   Private Subnet:  Timed out!

4. Check Internet Access
   curl https://ifconfig.me
   Internet Access: Timed out!

5. Management (Control Plane)
   url = https://management.azure.com/subscriptions?api-version=2020-01-01
   host = management.azure.com
   52.146.134.240 <-- management.azure.com
   Searching for service tags matching IP (52.146.134.240)
   - 52.146.134.0/23 <-- AzureResourceManager ()
   - 52.146.134.0/23 <-- AzureResourceManager.NorthEurope (northeurope)
   - 52.146.128.0/17 <-- AzureCloud.northeurope (northeurope)
   - 52.146.128.0/17 <-- AzureCloud ()
   curl -H Authorization : Bearer TOKEN https://management.azure.com/subscriptions?api-version=2020-01-01
   Management Access: Timed out!

6. Blob (Data Plane)
   url = https://g10hube9c6.blob.core.windows.net/storage/storage.txt
   host = g10hube9c6.blob.core.windows.net
   20.60.205.164 <-- g10hube9c6.blob.core.windows.net
   Searching for service tags matching IP (20.60.205.164)
   - 20.60.0.0/16 <-- Storage ()
   - 20.60.204.0/23 <-- Storage.NorthEurope (northeurope)
   - 20.60.204.0/23 <-- AzureCloud.northeurope (northeurope)
   - 20.60.204.0/23 <-- AzureCloud ()
   az storage account keys list -g G10_NetworkEgress_RG --account-name g10hube9c6
   Storage account key: timed out!
   Fallback: Get access token for storage.azure.com via metadata ...
   curl https://g10hube9c6.blob.core.windows.net/storage/storage.txt ...
   Content: Hello, World!
   Blob Dataplane: Pass

7. KeyVault (Data Plane)
   url: https://g10-hub-kve9c6.vault.azure.net/secrets/message
   host: g10-hub-kve9c6.vault.azure.net
   52.146.137.168 <-- g10-hub-kve9c6.vault.azure.net
   Searching for service tags matching IP (52.146.137.168)
   - 52.146.137.168/29 <-- AzureKeyVault ()
   - 52.146.137.168/29 <-- AzureKeyVault.NorthEurope (northeurope)
   - 52.146.128.0/17 <-- AzureCloud.northeurope (northeurope)
   - 52.146.128.0/17 <-- AzureCloud ()
   az keyvault secret show --vault-name g10-hub-kve9c6 --name message
   message: Hello, World!
   Vault Dataplane: Pass

-------------------------------------
Results
-------------------------------------
1. NAT IP Type:         None
2. Service Endpoints:   Timed out!
3. Private Subnet:      Timed out!
4. Internet Access:     Timed out!
5. Management Access:   Timed out!
6. Blob Dataplane:      Pass
7. KeyVault Dataplane:  Pass
-------------------------------------
```

</details>
<p>

### E. Outbound Access via Proxy

When private subnet is enabled on `ProductionSubnet` and there is no explicit outbound method deployed (NAT gateway, load balancer SNAT, or VM public IP), the VM `G10-Server1` cannot access public endpoints. But with [service endpoints](https://learn.microsoft.com/en-us/azure/virtual-network/virtual-network-service-endpoints-overview) enabled on `ProductionSubnet`, `G10-Server1` can access Azure services that are associated with the service endpoints - in this case, Azure Storage and Azure Key Vault. Service endpoints are accessed via management.azure.com for management operations on resources - listing, creating, updating, and deleting resources.

<img src="./images/egress-scenario-e.png" alt="Scenario E" width="700">

**Test instructions:**

1\. Enable service endpoints in the appropriate line in [02-main.tf](./02-main.tf#L9) file.

```sh
enable_service_endpoints = true
```

2\. Re-apply terraform to remove the subnet association with the NAT gateway.

3\. Login to `G10-Server1` VM as described in the [Test Servers](#test-servers) section.

4\. Run the command `crawlz` to test network reachability.

**Summary:**

```sh

```

**Detailed Result:**

<details>

<summary>Detailed Result</summary>

```sh

```

</details>
<p>

<img src="./images/egress-scenario-d.png" alt="Scenario D" width="700">


### F. No Explicit Public IP, Private-Subnet = Off, Service-Endpoint = Off

TBC

<img src="./images/egress-scenario-f.png" alt="Scenario F" width="700">

**Test instructions:**

1\. Enable service endpoints in the appropriate line in [02-main.tf](./02-main.tf#L9) file.

```sh
enable_service_endpoints = true
```

2\. Re-apply terraform to remove the subnet association with the NAT gateway.

3\. Login to `G10-Server1` VM as described in the [Test Servers](#test-servers) section.

4\. Run the command `crawlz` to test network reachability.

**Summary:**

```sh

```

**Detailed Result:**

<details>

<summary>Detailed Result</summary>

```sh

```

</details>
<p>

<img src="./images/egress-scenario-d.png" alt="Scenario D" width="700">

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
