# IPv6 Networking <!-- omit from toc -->

## Hs13 <!-- omit from toc -->

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
  - [7. Network Virtual Appliance (NVA)](#7-network-virtual-appliance-nva)
  - [8. On-premises Routes](#8-on-premises-routes)
- [ExpressRoute Tests](#expressroute-tests)
- [Cleanup](#cleanup)

## Overview

This lab deploys a single-region Hub and Spoke Vnet topology using Virtual Network Appliances (NVA) for traffic inspection. The lab demonstrates traffic routing patterns, [hybrid DNS](https://learn.microsoft.com/en-us/azure/dns/private-resolver-hybrid-dns) resolution, NVA deployment, and [PrivateLink Services](https://learn.microsoft.com/en-us/azure/private-link/private-link-service-overview) access to IaaS, [PrivateLink](https://learn.microsoft.com/en-us/azure/private-link/private-link-overview) access to PaaS services.

<img src="./images/architecture.png" alt="Hub and Spoke (Single region)" width="700">

***Hub1*** is a Vnet hub that has an NVA used for inspection of traffic between an on-premises branch and Vnet spokes. User-Defined Routes (UDR) are used to influence the hub Vnet data plane to route traffic between the branch and spokes via the NVA. An isolated spoke ***spoke3*** does not have Vnet peering to ***hub1***, but is reachable from the hub via [Private Link Service](https://learn.microsoft.com/en-us/azure/private-link/private-link-service-overview).

***Branch1*** is our on-premises network simulated in a Vnet. A Multi-NIC Linux Network Virtual Appliance (NVA) connects to the ***hub1*** using an IPsec VPN connection with dynamic (BGP) routing. ***Branch2*** is a simulated on-premises location connected to ***hub1*** using a Megaport express route circuit connection.

## Prerequisites

Ensure you meet all requirements in the [prerequisites](../../prerequisites/README.md) before proceeding.

## Deploy the Lab

1. Clone the Git Repository for the Labs

   ```sh
   git clone https://github.com/kaysalawu/azure-network-terraform.git
   ```

2. Navigate to the lab directory

   ```sh
   cd azure-network-terraform/4-general/07-ipv6-networking
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
| Branch1 NVA | Linux Strongswan + FRR configuration | [output/branch1Nva.sh](./output/branch1Nva.sh) |
| (Optional) Hub1 Linux NVA | Linux NVA configuration | [output/hub1-linux-nva.sh](./output/hub1-linux-nva.sh) |
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

4. Click on a dashboard under **Go to dashboard** column.

   Sample dashboard for VPN gateway in ***hub1***.

    <img src="../../images/demos/hub-and-spoke/hs13-hub1-vpngw-db.png" alt="Go to dashboard" width="900">

    </details>
<p>

## Testing

Each virtual machine is pre-configured with a shell [script](../../scripts/server.sh) to run various types of network reachability tests. Serial console access has been configured for all virtual machines.

Login to virtual machine `Hs13-spoke1Vm` via the [serial console](https://learn.microsoft.com/en-us/troubleshoot/azure/virtual-machines/serial-console-overview#access-serial-console-for-virtual-machines-via-azure-portal):

- On Azure portal select *Virtual machines*
- Select the virtual machine `Hs13-spoke1Vm`
- Under ***Help*** section, select ***Serial console*** and wait for a login prompt
- Enter the login credentials
  - username = ***azureuser***
  - password = ***Password123***
- You should now be in a shell session `azureuser@Hs13-spoke1Vm:~$`

Run the following tests from inside the serial console session.

### 1. Ping IP

This script pings the IP addresses of some test virtual machines and reports reachability and round trip time.

**1.1.** Run the IP ping tests

```sh
ping-ipv4
ping-ipv6
```

<details>

<summary>Sample output</summary>

```sh
azureuser@branch1Vm:~$ ping-ipv4

 ping ipv4 ...

branch1  - 10.10.0.5 -OK 0.064 ms
branch2  - 10.20.0.5 -NA
hub1-vm  - 10.11.0.5 -OK 5.651 ms
spoke1   - 10.1.0.5 -OK 6.007 ms
spoke2   - 10.2.0.5 -OK 4.813 ms
internet - icanhazip.com -NA
```

```sh
azureuser@branch1Vm:~$ ping-ipv6

 ping ipv6 ...

branch1  - fd00:db8:10::5 -OK 0.040 ms
branch2  - fd00:db8:20::5 -NA
hub1-vm  - fd00:db8:11::5 -NA
spoke1   - fd00:db8:1::5 -NA
spoke2   - fd00:db8:2::5 -NA
internet - icanhazip.com -NA
```

</details>
<p>

### 2. Ping DNS

This script pings the DNS name of some test virtual machines and reports reachability and round trip time. This tests hybrid DNS resolution between on-premises and Azure.

**2.1.** Run the DNS ping tests

```sh
ping-dns4
ping-dns6
```

<details>

<summary>Sample output</summary>

```sh
azureuser@spoke1Vm:~$ ping-ipv4

 ping ipv4 ...

branch1  - 10.10.0.5 -OK 4.585 ms
branch2  - 10.20.0.5 -OK 5.811 ms
hub1-vm  - 10.11.0.5 -OK 3.547 ms
spoke1   - 10.1.0.5 -OK 0.067 ms
spoke2   - 10.2.0.5 -OK 3.355 ms
internet - icanhazip.com -OK 3.602 ms
```

```sh
azureuser@spoke1Vm:~$ ping-ipv6

 ping ipv6 ...

branch1  - fd00:db8:10::5 -NA
branch2  - fd00:db8:20::5 -OK 4.795 ms
hub1-vm  - fd00:db8:11::5 -OK 3.730 ms
spoke1   - fd00:db8:1::5 -OK 0.054 ms
spoke2   - fd00:db8:2::5 -OK 7.370 ms
internet - icanhazip.com -NA
```

</details>
<p>

### 3. Curl DNS

This script uses curl to check reachability of web server (python Flask) on the test virtual machines. It reports HTTP response message, round trip time and IP address.

**3.1.** Run the DNS curl test

```sh
curl-dns4
curl-dns6
```

<details>

<summary>Sample output</summary>

```sh
azureuser@spoke1Vm:~$ curl-dns4

 curl dns ipv4 ...

200 (0.016005s) - 10.10.0.5 - branch1vm.corp
200 (0.012758s) - 10.20.0.5 - branch2vm.corp
200 (0.016667s) - 10.11.0.5 - hub1vm.eu.az.corp
200 (0.011021s) - 10.11.7.88 - spoke3pls.eu.az.corp
200 (0.010677s) - 10.1.0.5 - spoke1vm.eu.az.corp
200 (0.015877s) - 10.2.0.5 - spoke2vm.eu.az.corp
200 (0.071379s) - 104.16.185.241 - icanhazip.com
200 (0.027701s) - 10.11.7.99 - https://hs13spoke3sa5466.blob.core.windows.net/spoke3/spoke3.txt
```

```sh
azureuser@spoke1Vm:~$ curl-dns6

 curl dns ipv6 ...

 - branch1vm.corp
200 (0.016963s) - fd00:db8:20::5 - branch2vm.corp
200 (0.017906s) - fd00:db8:11::5 - hub1vm.eu.az.corp
000 (0.009046s) -  - spoke3pls.eu.az.corp
200 (0.011219s) - fd00:db8:1::5 - spoke1vm.eu.az.corp
200 (0.017509s) - fd00:db8:2::5 - spoke2vm.eu.az.corp
000 (2.252689s) -  - icanhazip.com
000 (0.007842s) -  - https://hs13spoke3sa5466.blob.core.windows.net/spoke3/spoke3.txt
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

```sh
azureuser@spoke1Vm:~$ curl -4 spoke3pls.eu.az.corp
{
  "app": "SERVER",
  "hostname": "spoke3Vm",
  "server-ipv4": "10.3.0.5",
  "server-ipv6": "fd00:db8:3::5",
  "remote-addr": "10.3.6.4",
  "headers": {
    "host": "spoke3pls.eu.az.corp",
    "user-agent": "curl/7.68.0",
    "accept": "*/*"
  }
}
```

</details>
<p>

The `Hostname` and `server-ipv4` fields identify the target web server - in this case ***spoke3*** virtual machine. The `remote-addr` field (as seen by the web server) is an IP address in the Private Link Service NAT subnet in ***spoke3***.

### 5. Private Link Access to Storage Account

A storage account with a container blob deployed and accessible via private endpoints in ***hub1***. The storage accounts have the following naming convention:

* hs13spoke3sa\<AAAA\>.blob.core.windows.net

Where ***\<AAAA\>*** is a randomly generated two-byte string.

**5.1.** On your Cloudshell (or local machine), get the storage account hostname and blob URL.

```sh
spoke3_storage_account=$(az storage account list -g Hs13_HubSpoke_Nva_1Region_RG --query "[?contains(name, 'hs13spoke3sa')].name" -o tsv)

spoke3_sgtacct_host="$spoke3_storage_account.blob.core.windows.net"
spoke3_blob_url="https://$spoke3_sgtacct_host/spoke3/spoke3.txt"

echo -e "\n$spoke3_sgtacct_host\n" && echo
```

<details>

<summary>Sample output</summary>

```sh
hs13spoke3sa5466.blob.core.windows.net
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
3-hub-spoke-nva-single-region$ nslookup $spoke3_sgtacct_host
Server:         8.8.8.8
Address:        8.8.8.8#53

Non-authoritative answer:
hs13spoke3sa5466.blob.core.windows.net  canonical name = hs13spoke3sa5466.privatelink.blob.core.windows.net.
hs13spoke3sa5466.privatelink.blob.core.windows.net      canonical name = blob.db4prdstr12a.store.core.windows.net.
Name:   blob.db4prdstr12a.store.core.windows.net
Address: 20.60.145.164
```

</details>
<p>

We can see that the endpoint is a public IP address, ***20.60.145.164***. We can see the CNAME `hs13spoke3sa5466.privatelink.blob.core.windows.net.` created for the storage account which recursively resolves to the public IP address.

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

**6.1** Login to on-premises virtual machine `Hs13-branch1Vm` via the [serial console](https://learn.microsoft.com/en-us/troubleshoot/azure/virtual-machines/serial-console-overview#access-serial-console-for-virtual-machines-via-azure-portal):
  - username = ***azureuser***
  - password = ***Password123***

 We will test access from `Hs13-branch1Vm` to the storage account for ***spoke3*** via the private endpoint in ***hub1***.

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
spoke3_storage_account=$(az storage account list -g Hs13_HubSpoke_Nva_1Region_RG --query "[?contains(name, 'hs13spoke3sa')].name" -o tsv)

spoke3_sgtacct_host="$spoke3_storage_account.blob.core.windows.net"
spoke3_blob_url="https://$spoke3_sgtacct_host/spoke3/spoke3.txt"

echo -e "\n$spoke3_sgtacct_host\n" && echo
```

<details>

<summary>Sample output</summary>

```sh
hs13spoke3sa5466.blob.core.windows.net
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
hs13spoke3sa5466.blob.core.windows.net  canonical name = hs13spoke3sa5466.privatelink.blob.core.windows.net.
Name:   hs13spoke3sa5466.privatelink.blob.core.windows.net
Address: 10.11.7.99
```

</details>
<p>

We can see that the storage account hostname resolves to the private endpoint ***10.11.7.99*** in ***hub1***. The following is a summary of the DNS resolution from `Hs13-branch1Vm`:

- On-premises server `Hs13-branch1Vm` makes a DNS request for `hs13spoke3sa5466.blob.core.windows.net`
- The request is received by on-premises DNS server `Hs13-branch1-dns`
- The DNS server resolves `hs13spoke3sa5466.blob.core.windows.net` to the CNAME `hs13spoke3sa5466.privatelink.blob.core.windows.net`
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

### 7. Network Virtual Appliance (NVA)

Whilst still logged into the on-premises server `Hs13-branch1Vm` via the serial console, we will test connectivity to all virtual machines using a `trace-ip` script using the linux `tracepath` utility.

**7.1.** Run the `trace-ip` script

```sh
trace-ipv4
```

<details>

<summary>Sample output</summary>

```sh
azureuser@branch1Vm:~$ trace-ipv4

 trace ipv4 ...

branch1
-------------------------------------
 1:  branch1Vm                                             0.113ms reached
     Resume: pmtu 65535 hops 1 back 1

branch2
-------------------------------------
 1?: [LOCALHOST]                      pmtu 1500
 1:  10.10.1.9                                             1.095ms
 1:  10.10.1.9                                             1.187ms
 2:  no reply
 3:  no reply

hub1-vm
-------------------------------------
 1?: [LOCALHOST]                      pmtu 1500
 1:  10.10.1.9                                             1.722ms
 1:  10.10.1.9                                             1.192ms
 2:  10.10.1.9                                             2.079ms pmtu 1436
 2:  10.10.1.9                                             0.925ms pmtu 1422
 2:  10.11.1.4                                             3.368ms
 3:  10.11.0.5                                             6.169ms reached
     Resume: pmtu 1422 hops 3 back 3

spoke1
-------------------------------------
 1?: [LOCALHOST]                      pmtu 1500
 1:  10.10.1.9                                             1.075ms
 1:  10.10.1.9                                             1.016ms
 2:  10.10.1.9                                             1.024ms pmtu 1436
 2:  10.10.1.9                                             1.230ms pmtu 1422
 2:  10.11.1.4                                             4.757ms
 3:  10.1.0.5                                              4.833ms reached
     Resume: pmtu 1422 hops 3 back 3

spoke2
-------------------------------------
 1?: [LOCALHOST]                      pmtu 1500
 1:  10.10.1.9                                             2.882ms
 1:  10.10.1.9                                             1.181ms
 2:  10.10.1.9                                             1.060ms pmtu 1436
 2:  10.10.1.9                                             1.139ms pmtu 1422
 2:  10.11.1.4                                             2.693ms
 3:  10.2.0.5                                              4.741ms reached
     Resume: pmtu 1422 hops 3 back 3

internet
-------------------------------------
 1?: [LOCALHOST]                      pmtu 1500
 1:  no reply
 2:  no reply
```

</details>
<p>

We can observe that traffic to ***spoke1***, ***spoke2*** and ***hub1*** flow symmetrically via the NVA in ***hub1*** (10.11.1.4).

### 8. On-premises Routes

**8.1** Login to on-premises virtual machine `Hs13-branch1Nva` via the [serial console](https://learn.microsoft.com/en-us/troubleshoot/azure/virtual-machines/serial-console-overview#access-serial-console-for-virtual-machines-via-azure-portal):
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
show ipv6 route
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

S   0.0.0.0/0 [1/0] via 10.10.1.1, eth0, 20:35:45
K>* 0.0.0.0/0 [0/100] via 10.10.1.1, eth0, src 10.10.1.9, 20:35:45
B>* 10.1.0.0/20 [20/0] via 10.11.16.14, vti0, 00:08:12
  *                    via 10.11.16.15, vti1, 00:08:12
B>* 10.2.0.0/20 [20/0] via 10.11.16.14, vti0, 00:08:12
  *                    via 10.11.16.15, vti1, 00:08:12
S>* 10.10.0.0/24 [1/0] via 10.10.1.1, eth0, 20:35:45
C>* 10.10.1.0/24 is directly connected, eth0, 20:35:45
C>* 10.10.2.0/24 is directly connected, eth1, 20:35:45
B>* 10.11.0.0/20 [20/0] via 10.11.16.14, vti0, 00:08:12
  *                     via 10.11.16.15, vti1, 00:08:12
B>* 10.11.16.0/20 [20/0] via 10.11.16.14, vti0, 00:08:12
  *                      via 10.11.16.15, vti1, 00:08:12
S   10.11.16.14/32 [1/0] is directly connected, vti0, 00:08:12
C>* 10.11.16.14/32 is directly connected, vti0, 00:08:12
S   10.11.16.15/32 [1/0] is directly connected, vti1, 00:08:12
C>* 10.11.16.15/32 is directly connected, vti1, 00:08:12
K>* 168.63.129.16/32 [0/100] via 10.10.1.1, eth0, src 10.10.1.9, 20:35:45
K>* 169.254.169.254/32 [0/100] via 10.10.1.1, eth0, src 10.10.1.9, 20:35:45
C>* 192.168.10.10/32 is directly connected, lo, 20:35:45
```

```sh
branch1Nva# show ipv6 route
Codes: K - kernel route, C - connected, S - static, R - RIPng,
       O - OSPFv3, I - IS-IS, B - BGP, N - NHRP, T - Table,
       v - VNC, V - VNC-Direct, A - Babel, D - SHARP, F - PBR,
       f - OpenFabric,
       > - selected route, * - FIB route, q - queued route, r - rejected route

K * ::/0 [0/200] via fe80::1234:5678:9abc, eth1, 20:36:07
K>* ::/0 [0/100] via fe80::1234:5678:9abc, eth0, 20:36:07
K>* fd00:db8:10:1::/64 [0/100] is directly connected, eth0, 20:36:07
C>* fd00:db8:10:1::9/128 is directly connected, eth0, 20:36:07
K>* fd00:db8:10:2::/64 [0/200] is directly connected, eth1, 20:36:07
C>* fd00:db8:10:2::9/128 is directly connected, eth1, 20:36:07
C * fe80::/64 is directly connected, vti1, 00:08:34
C * fe80::/64 is directly connected, vti0, 00:08:34
C * fe80::/64 is directly connected, eth1, 20:36:07
C>* fe80::/64 is directly connected, eth0, 20:36:07
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
BGP table version is 1389, local router ID is 192.168.10.10, vrf id 0
Default local pref 100, local AS 65001
Status codes:  s suppressed, d damped, h history, * valid, > best, = multipath,
               i internal, r RIB-failure, S Stale, R Removed
Nexthop codes: @NNN nexthop's vrf id, < announce-nh-self
Origin codes:  i - IGP, e - EGP, ? - incomplete

   Network          Next Hop            Metric LocPrf Weight Path
*> 10.1.0.0/20      10.11.16.14                            0 65515 i
*=                  10.11.16.15                            0 65515 i
*> 10.2.0.0/20      10.11.16.14                            0 65515 i
*=                  10.11.16.15                            0 65515 i
*> 10.10.0.0/24     0.0.0.0                  0         32768 i
*> 10.11.0.0/20     10.11.16.14                            0 65515 i
*=                  10.11.16.15                            0 65515 i
*> 10.11.16.0/20    10.11.16.14                            0 65515 i
*=                  10.11.16.15                            0 65515 i

Displayed  5 routes and 9 total paths
```

We can see the hub and spoke Vnet ranges being learned dynamically in the BGP table.

</details>
<p>

## ExpressRoute Tests

See the [Branch2 Tests](./BRANCH2.md) for tests to run on the on-premises virtual machine `Hs13-branch2Vm`.

## Cleanup

1\. (Optional) Navigate back to the lab directory (if you are not already there)

```sh
cd azure-network-terraform/4-general/07-ipv6-networking
```

2\. (Optional) This is not required if `enable_diagnostics = false` in the [`main.tf`](./02-main.tf). If you deployed the lab with `enable_diagnostics = true`, in order to avoid terraform errors when re-deploying this lab, run a cleanup script to remove diagnostic settings that are not removed after the resource group is deleted.

```sh
bash ../../scripts/_cleanup.sh Hs13_HubSpoke_Nva_1Region_RG
```

<details>

<summary>Sample output</summary>

```sh
3-hub-spoke-nva-single-region$    bash ../../scripts/_cleanup.sh Hs13_HubSpoke_Nva_1Region_RG

Resource group: Hs13_HubSpoke_Nva_1Region_RG

⏳ Checking for diagnostic settings on resources in Hs13_HubSpoke_Nva_1Region_RG ...
➜  Checking firewall ...
➜  Checking vnet gateway ...
    ❌ Deleting: diag setting [Hs13-hub1-vpngw-diag] for vnet gateway [Hs13-hub1-vpngw] ...
➜  Checking vpn gateway ...
➜  Checking er gateway ...
➜  Checking app gateway ...
⏳ Checking for azure policies in Hs13_HubSpoke_Nva_1Region_RG ...
Done!
```

</details>
<p>

3\. Delete the resource group to remove all resources installed.

```sh
az group delete -g Hs13_HubSpoke_Nva_1Region_RG --no-wait
```

4\. Delete terraform state files and other generated files.

```sh
rm -rf .terraform*
rm terraform.tfstate*
```
