# Virtual WAN - Dual Region <!-- omit from toc -->

## Lab: Vwan22 <!-- omit from toc -->

Contents

- [Overview](#overview)
- [Prerequisites](#prerequisites)
- [Deploy the Lab](#deploy-the-lab)
- [Troubleshooting](#troubleshooting)
- [Outputs](#outputs)
- [Dashboards (Optional)](#dashboards-optional)
- [Testing](#testing)
  - [1. Ping IP](#1-ping-ip)
  - [2. Ping DNS](#2-ping-dns)
  - [3. Curl DNS](#3-curl-dns)
  - [4. Private Link Service](#4-private-link-service)
  - [5. Private Link Access to Storage Account](#5-private-link-access-to-storage-account)
  - [6. Private Link Access to Storage Account from On-premises](#6-private-link-access-to-storage-account-from-on-premises)
  - [7. Virtual WAN Routes](#7-virtual-wan-routes)
  - [8. On-premises Routes](#8-on-premises-routes)
- [Cleanup](#cleanup)

## Overview

This lab deploys a dual-region Virtual WAN (Vwan) topology. The lab demonstrates multi-region traffic routing patterns, [hybrid DNS](https://learn.microsoft.com/en-us/azure/dns/private-resolver-hybrid-dns) resolution, [connecting NVA](https://learn.microsoft.com/en-us/azure/virtual-wan/scenario-bgp-peering-hub) into the virtual hubs, and [PrivateLink Services](https://learn.microsoft.com/en-us/azure/private-link/private-link-service-overview) access to IaaS, [PrivateLink](https://learn.microsoft.com/en-us/azure/private-link/private-link-overview) access to PaaS services.

<img src="../../images/scenarios/2-2-vwan-dual-region.png" alt="Virtual WAN - Dual Region" width="880">
<p>

Standard Virtual Network (Vnet) hubs (***hub1*** and ***hub2***) connect to Vwan hubs (***vHub1*** and ***vHub2*** respectively). ***Spoke1*** and ***spoke4*** are connected directly to the Vwan hubs. ***Spoke2*** and ***spoke5*** are indirect spokes from a Vwan perspective; and are connected to the standard Vnet hubs. ***Spoke2*** and ***spoke5*** use the Network Virtual Appliance (NVA) in the Vnet hubs as the next hop to all destinations.

***Spoke3*** and ***spoke6*** do not have Vnet peering to the Vnet hubs, but are reachable via [Private Link Service](https://learn.microsoft.com/en-us/azure/private-link/private-link-service-overview) endpoints in the hubs.

***Branch1*** and ***branch3*** are on-premises networks simulated using Vnets. Multi-NIC Linux NVA appliances connect to the hubs using IPsec VPN connections with dynamic (BGP) routing. The branches connect to each other via the Virtual WAN network.

## Prerequisites

Ensure you meet all requirements in the [prerequisites](../../prerequisites/README.md) before proceeding.

## Deploy the Lab

1. Clone the Git Repository for the Labs

   ```sh
   git clone https://github.com/kaysalawu/azure-network-terraform.git
   ```

2. Navigate to the lab directory

   ```sh
   cd azure-network-terraform/2-virtual-wan/2-vwan-dual-region
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
| Branch1 DNS | Authoritative DNS and forwarding | [output/branch1Dns.sh](./output/branch1Dns.sh) |
| Branch3 DNS | Authoritative DNS and forwarding | [output/branch3Dns.sh](./output/branch3Dns.sh) |
| Branch1 NVA | Linux Strongswan + FRR configuration | [output/branch1Nva.sh](./output/branch1Nva.sh) |
| Branch3 NVA | Linux Strongswan + FRR configuration | [output/branch3Nva.sh](./output/branch3Nva.sh) |
| Hub1 NVA | Linux NVA configuration | [output/hub1-linux-nva.sh](./output/hub1-linux-nva.sh) |
| Hub2 NVA | Linux NVA configuration | [output/hub2-linux-nva.sh](./output/hub2-linux-nva.sh) |
| Web server | Python Flask web server, test scripts | [output/server.sh](./output/server.sh) |
||||

## Dashboards (Optional)

This lab contains a number of pre-configured dashboards for monitoring gateways, VPN gateways, and Azure Firewall. To deploy the dashboards, set `enable_diagnostics = true` in the [`main.tf`](./02-main.tf) file. Then run `terraform apply` to update the deployment.

<details>

<summary>Sample Dashboards</summary>

To view the dashboards, follow the steps below:

1. From the Azure portal menu, select **Dashboard hub**.

2. Under **Browse**, select **Shared dashboards**.

3. Select the dashboard you want to view.

   <img src="../../images/demos/virtual-wan/vwan22-shared-dashboards.png" alt="Shared dashboards" width="900">

4. Click on a dashboard under **Go to dashboard** column.

   Sample dashboard for VPN gateway in ***hub1***.

    <img src="../../images/demos/virtual-wan/vwan22-vhub1-vpngw-db.png" alt="Go to dashboard" width="900">

</details>
<p>

## Testing

Each virtual machine is pre-configured with a shell [script](../../scripts/server.sh) to run various types of network reachability tests. Serial console access has been configured for all virtual machines.

Login to virtual machine `Vwan22-spoke1Vm` via the [serial console](https://learn.microsoft.com/en-us/troubleshoot/azure/virtual-machines/serial-console-overview#access-serial-console-for-virtual-machines-via-azure-portal):

- On Azure portal select *Virtual machines*
- Select the virtual machine `Vwan22-spoke1Vm`
- Under ***Help*** section, select ***Serial console*** and wait for a login prompt
- Enter the login credentials
  - username = ***azureuser***
  - password = ***Password123***
- You should now be in a shell session `azureuser@spoke1Vm:~$`

Run the following tests from inside the serial console session.

### 1. Ping IP

This script pings the IP addresses of some test virtual machines and reports reachability and round trip time.

**1.1.** Run the IP ping test

```sh
ping-ip
```

<details>

<summary>Sample output</summary>

```sh
azureuser@spoke1Vm:~$ ping-ip

 ping ip ...

branch1 - 10.10.0.5 -OK 2.253 ms
hub1    - 10.11.0.5 -OK 4.311 ms
spoke1  - 10.1.0.5 -OK 0.030 ms
spoke2  - 10.2.0.5 -OK 3.570 ms
branch3 - 10.30.0.5 -OK 69.542 ms
hub2    - 10.22.0.5 -OK 71.696 ms
spoke4  - 10.4.0.5 -OK 73.550 ms
spoke5  - 10.5.0.5 -OK 73.045 ms
internet - icanhazip.com -NA
```

</details>
<p>

### 2. Ping DNS

This script pings the DNS name of some test virtual machines and reports reachability and round trip time. This tests hybrid DNS resolution between on-premises and Azure.

**2.1.** Run the DNS ping test

```sh
ping-dns
```

<details>

<summary>Sample output</summary>

```sh
azureuser@spoke1Vm:~$ ping-dns

 ping dns ...

branch1vm.corp - 10.10.0.5 -OK 2.916 ms
hub1vm.eu.az.corp - 10.11.0.5 -OK 3.517 ms
spoke1vm.eu.az.corp - 10.1.0.5 -OK 0.039 ms
spoke2vm.eu.az.corp - 10.2.0.5 -OK 5.388 ms
branch3vm.corp - 10.30.0.5 -OK 71.095 ms
hub2vm.us.az.corp - 10.22.0.5 -OK 71.864 ms
spoke4vm.us.az.corp - 10.4.0.5 -OK 69.222 ms
spoke5vm.us.az.corp - 10.5.0.5 -OK 72.669 ms
icanhazip.com - 104.16.184.241 -NA
```

</details>
<p>

### 3. Curl DNS

This script uses curl to check reachability of web server (python Flask) on the test virtual machines. It reports HTTP response message, round trip time and IP address.

**3.1.** Run the DNS curl test

```sh
curl-dns
```

<details>

<summary>Sample output</summary>

```sh
azureuser@spoke1Vm:~$ curl-dns

 curl dns ...

200 (0.030074s) - 10.10.0.5 - branch1vm.corp
200 (0.029540s) - 10.11.0.5 - hub1vm.eu.az.corp
200 (0.021450s) - 10.11.7.88 - spoke3pls.eu.az.corp
200 (0.010347s) - 10.1.0.5 - spoke1vm.eu.az.corp
200 (0.033476s) - 10.2.0.5 - spoke2vm.eu.az.corp
200 (0.185174s) - 10.30.0.5 - branch3vm.corp
200 (0.169610s) - 10.22.0.5 - hub2vm.us.az.corp
200 (0.174251s) - 10.22.7.88 - spoke6pls.us.az.corp
200 (0.166897s) - 10.4.0.5 - spoke4vm.us.az.corp
200 (0.168337s) - 10.5.0.5 - spoke5vm.us.az.corp
200 (0.022974s) - 104.16.185.241 - icanhazip.com
200 (0.039597s) - 10.11.7.99 - https://vwan22spoke3sa8897.blob.core.windows.net/spoke3/spoke3.txt
200 (0.310487s) - 10.22.7.99 - https://vwan22spoke6sa8897.blob.core.windows.net/spoke6/spoke6.txt
```

</details>
<p>

### 4. Private Link Service

**4.1.** Test access to ***spoke3*** web application using the private endpoint in ***hub1***.

```sh
curl spoke3pls.eu.az.corp
```

<details>

<summary>Sample output</summary>

```json
azureuser@spoke1Vm:~$ curl spoke3pls.eu.az.corp
{
  "Headers": {
    "Accept": "*/*",
    "Host": "spoke3pls.eu.az.corp",
    "User-Agent": "curl/7.68.0"
  },
  "Hostname": "spoke3Vm",
  "Local-IP": "10.3.0.5",
  "Remote-IP": "10.3.6.4"
}
```

</details>
<p>

**4.2.** Test access to ***spoke6*** web application using the private endpoint in ***hub2***.

```sh
curl spoke6pls.us.az.corp
```

<details>

<summary>Sample output</summary>

```sh
azureuser@spoke1Vm:~$ curl spoke6pls.us.az.corp
{
  "Headers": {
    "Accept": "*/*",
    "Host": "spoke6pls.us.az.corp",
    "User-Agent": "curl/7.68.0"
  },
  "Hostname": "spoke6Vm",
  "Local-IP": "10.6.0.5",
  "Remote-IP": "10.6.6.4"
}
```

</details>
<p>

The `Hostname` and `Local-IP` fields identifies the actual web servers - in this case ***spoke3*** and ***spoke6*** virtual machines. The `Remote-IP` fields (as seen by the web servers) are IP addresses in the Private Link Service NAT subnets in ***spoke3*** and ***spoke6*** respectively.

### 5. Private Link Access to Storage Account

Storage accounts with container blobs are deployed and accessible via private endpoints in ***hub1*** and ***hub2*** respectively. The storage accounts have the following naming convention:

* vwan22spoke3sa\<AAAA\>.blob.core.windows.net
* vwan22spoke6sa\<BBBB\>.blob.core.windows.net

Where ***\<AAAA\>*** and ***\<BBBB\>*** are randomly generated two-byte strings.

**5.1.** On your Cloudshell (or local machine), get the storage account hostname and blob URL.

```sh
spoke3_storage_account=$(az storage account list -g Vwan22_Vwan_2Region_RG --query "[?contains(name, 'vwan22spoke3sa')].name" -o tsv)

spoke3_sgtacct_host="$spoke3_storage_account.blob.core.windows.net"
spoke3_blob_url="https://$spoke3_sgtacct_host/spoke3/spoke3.txt"

echo -e "\n$spoke3_sgtacct_host\n" && echo
```

<details>

<summary>Sample output</summary>

```sh
vwan22spoke3sa8897.blob.core.windows.net
```

</details>
<p>

**5.2.** Resolve the hostname

```sh
nslookup $spoke3_sgtacct_host
```

<details>

<summary>Sample output</summary>

```sh
2-vwan-dual-region$ nslookup $spoke3_sgtacct_host
Server:         8.8.8.8
Address:        8.8.8.8#53

Non-authoritative answer:
vwan22spoke3sa8897.blob.core.windows.net        canonical name = vwan22spoke3sa8897.privatelink.blob.core.windows.net.
vwan22spoke3sa8897.privatelink.blob.core.windows.net    canonical name = blob.db3prdstr19a.store.core.windows.net.
Name:   blob.db3prdstr19a.store.core.windows.net
Address: 20.150.75.36
```

</details>
<p>

We can see that the endpoint is a public IP address, ***20.150.75.36***. We can see the CNAME `vwan22spoke3sa8897.privatelink.blob.core.windows.net.` created for the storage account which recursively resolves to the public IP address.

**5.3.** Test access to the storage account blob.

```sh
curl $spoke3_blob_url && echo
```

<details>

<summary>Sample output</summary>

```sh
Hello, World!
```

</details>
<p>

### 6. Private Link Access to Storage Account from On-premises

**6.1** Login to on-premises virtual machine `Vwan22-branch1Vm` via the [serial console](https://learn.microsoft.com/en-us/troubleshoot/azure/virtual-machines/serial-console-overview#access-serial-console-for-virtual-machines-via-azure-portal):
  - username = ***azureuser***
  - password = ***Password123***

 We will test access from `Vwan22-branch1Vm` to the storage account for ***spoke3*** via the private endpoint in ***hub1***.

**6.2.** Run `az login` using the VM's system-assigned managed identity.

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

**6.3.** Get the storage account hostname and blob URL.

```sh
spoke3_storage_account=$(az storage account list -g Vwan22_Vwan_2Region_RG --query "[?contains(name, 'vwan22spoke3sa')].name" -o tsv)

spoke3_sgtacct_host="$spoke3_storage_account.blob.core.windows.net"
spoke3_blob_url="https://$spoke3_sgtacct_host/spoke3/spoke3.txt"

echo -e "\n$spoke3_sgtacct_host\n" && echo
```

<details>

<summary>Sample output</summary>

```sh
vwan22spoke3sa8897.blob.core.windows.net
```

</details>
<p>

**6.4.** Resolve the storage account DNS name

```sh
nslookup $spoke3_sgtacct_host
```

<details>

<summary>Sample output</summary>

```sh
azureuser@branch1Vm:~$ nslookup $spoke3_sgtacct_host
Server:         127.0.0.53
Address:        127.0.0.53#53

Non-authoritative answer:
vwan22spoke3sa8897.blob.core.windows.net        canonical name = vwan22spoke3sa8897.privatelink.blob.core.windows.net.
Name:   vwan22spoke3sa8897.privatelink.blob.core.windows.net
Address: 10.11.7.99
```

</details>
<p>

We can see that the storage account hostname resolves to the private endpoint ***10.11.7.99*** in ***hub1***. The following is a summary of the DNS resolution from `Vwan22-branch1Vm`:

- On-premises server `Vwan22-branch1Vm` makes a DNS request for `vwan22spoke3sa8897.blob.core.windows.net`
- The request is received by on-premises DNS server `Vwan22-branch1-dns`
- The DNS server resolves `vwan22spoke3sa8897.blob.core.windows.net` to the CNAME `vwan22spoke3sa8897.privatelink.blob.core.windows.net`
- The DNS server has a conditional DNS forwarding defined in the branch1 unbound DNS configuration file, [output/branch1Dns.sh](./output/branch1Dns.sh).

  ```sh
  forward-zone:
          name: "privatelink.blob.core.windows.net."
          forward-addr: 10.11.8.4
  ```

  DNS Requests matching `privatelink.blob.core.windows.net` will be forwarded to the private DNS resolver inbound endpoint in ***hub1*** (10.11.8.4).
- The DNS server forwards the DNS request to the private DNS resolver inbound endpoint in ***hub1*** - which returns the IP address of the storage account private endpoint in ***hub1*** (10.11.7.99)

**6.5.** Test access to the storage account blob.

```sh
curl $spoke3_blob_url && echo
```

<details>

<summary>Sample output</summary>

```sh
Hello, World!
```

</details>
<p>

### 7. Virtual WAN Routes

**7.1.** Switch back to the lab directory `azure-network-terraform/2-virtual-wan/2-vwan-dual-region`

**7.2.** Display the virtual WAN routing table(s)

```sh
bash ../../scripts/_routes_vwan.sh Vwan22_Vwan_2Region_RG
```

<details>

<summary>Sample output</summary>

```sh
2-vwan-dual-region$ bash ../../scripts/_routes_vwan.sh Vwan22_Vwan_2Region_RG

Resource group: Vwan22_Vwan_2Region_RG

vHub:       Vwan22-vhub2-hub
RouteTable: defaultRouteTable
-------------------------------------------------------

AddressPrefixes    AsPath             NextHopType
-----------------  -----------------  --------------------------
10.30.0.0/24       65003              VPN_S2S_Gateway
10.4.0.0/20                           Virtual Network Connection
10.22.0.0/20                          Virtual Network Connection
10.22.16.0/20                         Virtual Network Connection
10.5.0.0/20        65020              HubBgpConnection
10.10.0.0/24       65520-65520-65001  Remote Hub
10.1.0.0/20        65520-65520        Remote Hub
10.2.0.0/20        65520-65520-65010  Remote Hub
10.11.0.0/20       65520-65520        Remote Hub
10.11.16.0/20      65520-65520        Remote Hub


vHub:       Vwan22-vhub1-hub
RouteTable: defaultRouteTable
-------------------------------------------------------

AddressPrefixes    AsPath             NextHopType
-----------------  -----------------  --------------------------
10.4.0.0/20        65520-65520        Remote Hub
10.5.0.0/20        65520-65520-65020  Remote Hub
10.30.0.0/24       65520-65520-65003  Remote Hub
10.22.0.0/20       65520-65520        Remote Hub
10.22.16.0/20      65520-65520        Remote Hub
10.10.0.0/24       65001              VPN_S2S_Gateway
10.11.0.0/20                          Virtual Network Connection
10.11.16.0/20                         Virtual Network Connection
10.1.0.0/20                           Virtual Network Connection
10.2.0.0/20        65010              HubBgpConnection
```

</details>
<p>

### 8. On-premises Routes

**8.1** Login to on-premises virtual machine `Vwan22-branch1Nva` via the [serial console](https://learn.microsoft.com/en-us/troubleshoot/azure/virtual-machines/serial-console-overview#access-serial-console-for-virtual-machines-via-azure-portal):
  - username = ***azureuser***
  - password = ***Password123***

**8.2.** Enter the VTY shell for the FRRouting daemon.

```sh
sudo vtysh
```

<details>

<summary>Sample output</summary>

```sh
azureuser@branch1Nva:~$ sudo vtysh

Hello, this is FRRouting (version 7.2.1).
Copyright 1996-2005 Kunihiro Ishiguro, et al.
```

</details>
<p>

**8.3.** Display the routing table by typing `show ip route` and pressing the space bar to show the complete output.

```sh
show ip route
```

<details>

<summary>Sample output</summary>

```sh
branch1Nva# show ip route
Codes: K - kernel route, C - connected, S - static, R - RIP,
       O - OSPF, I - IS-IS, B - BGP, E - EIGRP, N - NHRP,
       T - Table, v - VNC, V - VNC-Direct, A - Babel, D - SHARP,
       F - PBR, f - OpenFabric,
       > - selected route, * - FIB route, q - queued route, r - rejected route

K>* 0.0.0.0/0 [0/100] via 10.10.1.1, eth0, src 10.10.1.9, 00:54:42
B>* 10.1.0.0/20 [20/0] via 192.168.11.12, vti0, 00:00:42
  *                    via 192.168.11.13, vti1, 00:00:42
B>* 10.2.0.0/20 [20/0] via 192.168.11.12, vti0, 00:00:42
  *                    via 192.168.11.13, vti1, 00:00:42
B>* 10.4.0.0/20 [20/0] via 192.168.11.12, vti0, 00:00:42
  *                    via 192.168.11.13, vti1, 00:00:42
B>* 10.5.0.0/20 [20/0] via 192.168.11.12, vti0, 00:00:42
  *                    via 192.168.11.13, vti1, 00:00:42
S>* 10.10.0.0/24 [1/0] via 10.10.1.1, eth0, 00:54:41
C>* 10.10.1.0/24 is directly connected, eth0, 00:54:42
C>* 10.10.2.0/24 is directly connected, eth1, 00:54:42
B>* 10.11.0.0/20 [20/0] via 192.168.11.12, vti0, 00:00:42
  *                     via 192.168.11.13, vti1, 00:00:42
B>* 10.11.16.0/20 [20/0] via 192.168.11.12, vti0, 00:00:42
  *                      via 192.168.11.13, vti1, 00:00:42
B>* 10.22.0.0/20 [20/0] via 192.168.11.12, vti0, 00:00:42
  *                     via 192.168.11.13, vti1, 00:00:42
B>* 10.22.16.0/20 [20/0] via 192.168.11.12, vti0, 00:00:42
  *                      via 192.168.11.13, vti1, 00:00:42
B>* 10.30.0.0/24 [20/0] via 192.168.11.12, vti0, 00:00:42
  *                     via 192.168.11.13, vti1, 00:00:42
K>* 168.63.129.16/32 [0/100] via 10.10.1.1, eth0, src 10.10.1.9, 00:54:42
K>* 169.254.169.254/32 [0/100] via 10.10.1.1, eth0, src 10.10.1.9, 00:54:42
C>* 192.168.10.10/32 is directly connected, lo, 00:54:42
B>* 192.168.11.0/24 [20/0] via 192.168.11.12, vti0, 00:00:42
  *                        via 192.168.11.13, vti1, 00:00:42
S   192.168.11.12/32 [1/0] is directly connected, vti0, 00:00:42
C>* 192.168.11.12/32 is directly connected, vti0, 00:00:42
S   192.168.11.13/32 [1/0] is directly connected, vti1, 00:54:41
C>* 192.168.11.13/32 is directly connected, vti1, 00:54:42
```

We can see the Vnet ranges learned dynamically via BGP.

</details>
<p>

**8.4.** Display BGP information by typing `show ip bgp` and pressing the space bar to show the complete output.

```sh
show ip bgp
```

<details>

<summary>Sample output</summary>

```sh
branch1Nva# show ip bgp
BGP table version is 20, local router ID is 192.168.10.10, vrf id 0
Default local pref 100, local AS 65001
Status codes:  s suppressed, d damped, h history, * valid, > best, = multipath,
               i internal, r RIB-failure, S Stale, R Removed
Nexthop codes: @NNN nexthop's vrf id, < announce-nh-self
Origin codes:  i - IGP, e - EGP, ? - incomplete

   Network          Next Hop            Metric LocPrf Weight Path
*= 10.1.0.0/20      192.168.11.12                          0 65515 i
*>                  192.168.11.13                          0 65515 i
*= 10.2.0.0/20      192.168.11.13            0             0 65515 65010 i
*>                  192.168.11.12            0             0 65515 65010 i
*= 10.4.0.0/20      192.168.11.12                          0 65515 65520 65520 e
*>                  192.168.11.13                          0 65515 65520 65520 e
*= 10.5.0.0/20      192.168.11.12                          0 65515 65520 65520 65020 e
*>                  192.168.11.13                          0 65515 65520 65520 65020 e
*> 10.10.0.0/24     0.0.0.0                  0         32768 i
*= 10.11.0.0/20     192.168.11.12                          0 65515 i
*>                  192.168.11.13                          0 65515 i
*= 10.11.16.0/20    192.168.11.12                          0 65515 i
*>                  192.168.11.13                          0 65515 i
*= 10.22.0.0/20     192.168.11.12                          0 65515 65520 65520 e
*>                  192.168.11.13                          0 65515 65520 65520 e
*= 10.22.16.0/20    192.168.11.12                          0 65515 65520 65520 e
*>                  192.168.11.13                          0 65515 65520 65520 e
*= 10.30.0.0/24     192.168.11.12                          0 65515 65520 65520 65003 e
*>                  192.168.11.13                          0 65515 65520 65520 65003 e
*= 192.168.11.0/24  192.168.11.12                          0 65515 i
*>                  192.168.11.13                          0 65515 i

Displayed  11 routes and 21 total paths
```

We can see the hub and spoke Vnet ranges being learned dynamically in the BGP table.

</details>
<p>

## Cleanup

1\. (Optional) Navigate back to the lab directory (if you are not already there)

```sh
cd azure-network-terraform/2-virtual-wan/2-vwan-dual-region
```

2\. (Optional) This is not required if `enable_diagnostics = false` in the [`main.tf`](./02-main.tf). If you deployed the lab with `enable_diagnostics = true`, in order to avoid terraform errors when re-deploying this lab, run a cleanup script to remove diagnostic settings that are not removed after the resource group is deleted.

```sh
bash ../../scripts/_cleanup.sh Vwan22_Vwan_2Region_RG
```

<details>

<summary>Sample output</summary>

```sh
2-vwan-dual-region$    bash ../../scripts/_cleanup.sh Vwan22_Vwan_2Region_RG

Resource group: Vwan22_Vwan_2Region_RG

⏳ Checking for diagnostic settings on resources in Vwan22_Vwan_2Region_RG ...
➜  Checking firewall ...
➜  Checking vnet gateway ...
➜  Checking vpn gateway ...
    ❌ Deleting: diag setting [Vwan22-vhub1-vpngw-diag] for vpn gateway [Vwan22-vhub1-vpngw] ...
    ❌ Deleting: diag setting [Vwan22-vhub2-vpngw-diag] for vpn gateway [Vwan22-vhub2-vpngw] ...
➜  Checking er gateway ...
➜  Checking app gateway ...
⏳ Checking for azure policies in Vwan22_Vwan_2Region_RG ...
Done!
```

</details>
<p>

3\. Delete the resource group to remove all resources installed.

```sh
az group delete -g Vwan22_Vwan_2Region_RG --no-wait
```

4\. Delete terraform state files and other generated files.

```sh
rm -rf .terraform*
rm terraform.tfstate*
```
