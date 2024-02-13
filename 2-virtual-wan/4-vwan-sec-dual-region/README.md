# Secured Virtual WAN - Dual Region <!-- omit from toc -->

## Lab: Vwan24 <!-- omit from toc -->

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
  - [5. Private Link (App Service) Access from Public Client](#5-private-link-app-service-access-from-public-client)
  - [6. Private Link (Storage Account) Access from On-premises](#6-private-link-storage-account-access-from-on-premises)
  - [7. Virtual WAN Routes](#7-virtual-wan-routes)
  - [8. On-premises Routes](#8-on-premises-routes)
  - [9. Azure Firewall (Optional)](#9-azure-firewall-optional)
- [Cleanup](#cleanup)

## Overview

Deploy a dual-region Secured Virtual WAN (Vwan) topology to observe traffic routing patterns. [Routing Intent](https://learn.microsoft.com/en-us/azure/virtual-wan/how-to-routing-policies) feature is enabled to allow traffic inspection through the Azure firewalls in the virtual hubs. Learn about multi-region traffic routing patterns, routing intent [security policies](https://learn.microsoft.com/en-us/azure/virtual-wan/how-to-routing-policies), [hybrid DNS](https://learn.microsoft.com/en-us/azure/dns/private-resolver-hybrid-dns) resolution, [connecting NVA](https://learn.microsoft.com/en-us/azure/virtual-wan/scenario-bgp-peering-hub) into the virtual hubs, and [PrivateLink Services](https://learn.microsoft.com/en-us/azure/private-link/private-link-service-overview) access to IaaS, [PrivateLink](https://learn.microsoft.com/en-us/azure/private-link/private-link-overview) access to PaaS services.

<img src="../../images/scenarios/2-4-vwan-sec-dual-region.png" alt="Secured Virtual WAN - Dual Region" width="900">

Standard Virtual Network (Vnet) hubs (***hub1*** and ***hub2***) connect to Vwan hubs (***vHub1*** and ***vHub2*** respectively). Direct spokes (***spoke1*** and ***spoke4***) are connected directly to the Vwan hubs. ***Spoke2*** and ***spoke5*** are indirect spokes from a Vwan perspective; and are connected to standard Vnet hubs - ***hub1*** and ***hub2*** respectively. ***Spoke2*** and ***spoke5*** use the Network Virtual Appliance (NVA) in the Vnet hubs as the next hop for traffic to all destinations.

The isolated spokes (***spoke3*** and ***spoke6***) do not have Vnet peering to their respective Vnet hubs, but are reachable via [Private Link Service](https://learn.microsoft.com/en-us/azure/private-link/private-link-service-overview) endpoints in the hubs.

***Branch1*** and ***branch3*** are on-premises networks simulated using Vnets. Multi-NIC Cisco-CSR-1000V NVA appliances connect to the hubs using IPsec VPN connections with dynamic (BGP) routing. Branches, ***branch1*** and ***branch3*** connect to each other via the Virtual WAN.

## Prerequisites

Ensure you meet all requirements in the [prerequisites](../../prerequisites/) before proceeding.

## Deploy the Lab

1. Clone the Git Repository for the Labs

   ```sh
   git clone https://github.com/kaysalawu/azure-network-terraform.git
   ```

2. Navigate to the lab directory

   ```sh
   cd azure-network-terraform/2-virtual-wan/4-vwan-sec-dual-region
   ```

3. Run the following terraform commands and type ***yes*** at the prompt:

   ```sh
   terraform init
   terraform plan
   terraform apply -parallelism=50
   ```

## Troubleshooting

See the [troubleshooting](../../troubleshooting/) section for tips on how to resolve common issues that may occur during the deployment of the lab.

## Outputs

The table below shows the auto-generated output files from the lab. They are located in the `output` directory.

| Item    | Description  | Location |
|--------|--------|--------|
| IP ranges and DNS | IP ranges and DNS hostname values | [output/values.md](./output/values.md) |
| Branch1 DNS | Authoritative DNS and forwarding | [output/branch1-unbound.sh](./output/branch1-unbound.sh) |
| Branch3 DNS | Authoritative DNS and forwarding | [output/branch3-unbound.sh](./output/branch3-unbound.sh) |
| Branch1 NVA | Cisco IOS commands - IPsec, BGP, route maps | [output/branch1-nva.sh](./output/branch1-nva.sh) |
| Branch3 NVA | Cisco IOS commands - IPsec, BGP, route maps | [output/branch3-nva.sh](./output/branch3-nva.sh) |
| Web server | Python Flask web server, test scripts | [output/server.sh](./output/server.sh) |
||||

## Dashboards (Optional)

This lab contains a number of pre-configured dashboards for monitoring network gateways, VPN gateways, and Azure Firewall.

To view dashboards, set `enable_diagnostics = true` in the [`main.tf`](./02-main.tf). Then run `terraform apply` to update the deployment.

To view the dashboards, follow the steps below:

1. From the Azure portal menu, select **Dashboard hub**.

2. Under **Browse**, select **Shared dashboards**.

3. Select the dashboard you want to view.

   <img src="../../images/demos/virtual-wan/vwan24-shared-dashboards.png" alt="Shared dashboards" width="900">

4. Click on a dashboard under **Go to dashboard** column.

   Sample dashboard for VPN gateway in ***hub1***.

    <img src="../../images/demos/virtual-wan/vwan24-vhub1-vpngw-db.png" alt="Go to dashboard" width="900">

    Sample dashboard for Azure Firewall in ***hub1***.

   <img src="../../images/demos/virtual-wan/vwan24-vhub1-azfw-db.png" alt="Go to dashboard" width="900">

## Testing

Each virtual machine is pre-configured with a shell [script](../../scripts/server.sh) to run various types of network reachability tests. Serial console access has been configured for all virtual machines.

Login to virtual machine `Vwan24-spoke1-vm` via the [serial console](https://learn.microsoft.com/en-us/troubleshoot/azure/virtual-machines/serial-console-overview#access-serial-console-for-virtual-machines-via-azure-portal):

- On Azure portal select *Virtual machines*
- Select the virtual machine `Vwan24-spoke1-vm`
- Under ***Help*** section, select ***Serial console*** and wait for a login prompt
- Enter the login credentials
  - username = ***azureuser***
  - password = ***Password123***
- You should now be in a shell session `azureuser@Vwan24-spoke1-vm:~$`

Run the following tests from inside the serial console session.

### 1. Ping IP

This script pings the IP addresses of some test virtual machines and reports reachability and round trip time.

**1.1.** Run the IP ping test

```sh
ping-ip
```

Sample output

```sh
azureuser@spoke1Vm:~$ ping-ip

 ping ip ...

branch1 - 10.10.0.5 -OK 1135.061 ms
hub1    - 10.11.0.5 -OK 3.586 ms
spoke1  - 10.1.0.5 -OK 0.049 ms
spoke2  - 10.2.0.5 -OK 4.054 ms
branch3 - 10.30.0.5 -OK 1981.217 ms
hub2    - 10.22.0.5 -OK 72.214 ms
spoke4  - 10.4.0.5 -OK 70.227 ms
spoke5  - 10.5.0.5 -OK 71.587 ms
internet - icanhazip.com -NA
```

### 2. Ping DNS

This script pings the DNS name of some test virtual machines and reports reachability and round trip time. This tests hybrid DNS resolution between on-premises and Azure.

**2.1.** Run the DNS ping test

```sh
ping-dns
```

Sample output

```sh
azureuser@spoke1Vm:~$ ping-dns

 ping dns ...

branch1Vm.corp - 10.10.0.5 -OK 1172.319 ms
hub1Vm.eu.az.corp - 10.11.0.5 -OK 4.636 ms
spoke1Vm.eu.az.corp - 10.1.0.5 -OK 0.029 ms
spoke2Vm.eu.az.corp - 10.2.0.5 -OK 4.864 ms
branch3Vm.corp - 10.30.0.5 -OK 901.629 ms
hub2Vm.us.az.corp - 10.22.0.5 -OK 72.131 ms
spoke4Vm.us.az.corp - 10.4.0.5 -OK 70.959 ms
spoke5Vm.us.az.corp - 10.5.0.5 -OK 74.171 ms
icanhazip.com - 104.18.114.97 -NA
```

### 3. Curl DNS

This script uses curl to check reachability of web server (python Flask) on the test virtual machines. It reports HTTP response message, round trip time and IP address.

**3.1.** Run the DNS curl test

```sh
curl-dns
```

Sample output

```sh
azureuser@spoke1Vm:~$ curl-dns

 curl dns ...

200 (3.928167s) - 10.10.0.5 - branch1Vm.corp
200 (0.020961s) - 10.11.0.5 - hub1Vm.eu.az.corp
200 (0.019124s) - 10.11.7.88 - spoke3pls.eu.az.corp
200 (0.009890s) - 10.1.0.5 - spoke1Vm.eu.az.corp
200 (0.021219s) - 10.2.0.5 - spoke2Vm.eu.az.corp
200 (3.681159s) - 10.30.0.5 - branch3Vm.corp
200 (0.168131s) - 10.22.0.5 - hub2Vm.us.az.corp
200 (0.170549s) - 10.22.7.88 - spoke6pls.us.az.corp
200 (0.232775s) - 10.4.0.5 - spoke4Vm.us.az.corp
200 (0.174013s) - 10.5.0.5 - spoke5Vm.us.az.corp
200 (0.015324s) - 104.18.115.97 - icanhazip.com
200 (0.030781s) - 10.11.7.99 - https://vwan24spoke3sa07c5.blob.core.windows.net/spoke3/spoke3.txt
200 (0.301143s) - 10.22.7.99 - https://vwan24spoke6sa07c5.blob.core.windows.net/spoke6/spoke6.txt
```

### 4. Private Link Service

**4.1.** Test access to ***spoke3*** web application using the private endpoint in ***hub1***.

```sh
curl spoke3pls.eu.az.corp
```

Sample output

```sh
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

**4.2.** Test access to ***spoke6*** web application using the private endpoint in ***hub2***.

```sh
curl spoke6pls.us.az.corp
```

Sample output

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

The `Hostname` and `Local-IP` fields identifies the actual web servers - in this case ***spoke3*** and ***spoke6*** virtual machines. The `Remote-IP` fields (as seen by the web servers) are IP addresses in the Private Link Service NAT subnets in ***spoke3*** and ***spoke6*** respectively.

### 5. Private Link (App Service) Access from Public Client

Storage account with container blobs are deployed and accessible via private endpoints in ***hub1*** and ***hub2*** respectively. The storage accounts have the following naming convention:

* vwan24spoke3sa\<AAAA\>.blob.core.windows.net
* vwan24spoke6sa\<BBBB\>.blob.core.windows.net

Where ***\<AAAA\>*** and ***\<BBBB\>*** are randomly generated two-byte strings.

**5.1.** On your local machine, get the storage account hostname and blob URL.

```sh
spoke3_storage_account=$(az storage account list -g Vwan24RG --query "[?contains(name, 'vwan24spoke3sa')].name" -o tsv)

spoke3_sgtacct_host="$spoke3_storage_account.blob.core.windows.net"
spoke3_blob_url="https://$spoke3_sgtacct_host/spoke3/spoke3.txt"

echo -e "\n$spoke3_sgtacct_host\n"
```

Sample output (yours will be different)

```sh
vwan24spoke3sa07c5.blob.core.windows.net
```

**5.2.** Resolve the hostname

```sh
nslookup $spoke3_sgtacct_host
```

Sample output (yours will be different)

```sh
4-vwan-sec-dual-region$ nslookup $spoke3_sgtacct_host
Server:         8.8.8.8
Address:        8.8.8.8#53

Non-authoritative answer:
vwan24spoke3sa07c5.blob.core.windows.net        canonical name = vwan24spoke3sa07c5.privatelink.blob.core.windows.net.
vwan24spoke3sa07c5.privatelink.blob.core.windows.net    canonical name = blob.db4prdstr10a.store.core.windows.net.
Name:   blob.db4prdstr10a.store.core.windows.net
Address: 20.60.145.4
```

We can see that the endpoint is a public IP address, ***20.60.145.4***. We can see the CNAME `vwan24spoke3sa07c5.privatelink.blob.core.windows.net.` created for the storage account which recursively resolves to the public IP address.

**5.3.** Test access to the storage account blob.

```sh
curl $spoke3_blob_url && echo
```

Sample output

```sh
Hello, World!
```

### 6. Private Link (Storage Account) Access from On-premises

**6.1** Login to on-premises virtual machine `Vwan24-branch1-vm` via the [serial console](https://learn.microsoft.com/en-us/troubleshoot/azure/virtual-machines/serial-console-overview#access-serial-console-for-virtual-machines-via-azure-portal):
  - username = ***azureuser***
  - password = ***Password123***

 We will test access from `Vwan24-branch1-vm` to the storage account for ***spoke3*** via the private endpoint in ***hub1***.

**6.2.** Run az login with user assigned managed identity to authenticate to Azure.

```sh
/usr/local/bin/az-login
```

**6.3.** Get the storage account hostname and blob URL.

```sh
spoke3_storage_account=$(az storage account list -g Vwan24RG --query "[?contains(name, 'vwan24spoke3sa')].name" -o tsv)

spoke3_sgtacct_host="$spoke3_storage_account.blob.core.windows.net"
spoke3_blob_url="https://$spoke3_sgtacct_host/spoke3/spoke3.txt"

echo -e "\n$spoke3_sgtacct_host\n"
```

Sample output (yours will be different)

```sh
vwan24spoke3sa07c5.blob.core.windows.net
```

**6.4.** Resolve the storage account DNS name

```sh
nslookup $spoke3_sgtacct_host
```

Sample output

```sh
azureuser@vm:~$ nslookup $spoke3_sgtacct_host
Server:         127.0.0.53
Address:        127.0.0.53#53

Non-authoritative answer:
vwan24spoke3sa07c5.blob.core.windows.net        canonical name = vwan24spoke3sa07c5.privatelink.blob.core.windows.net.
Name:   vwan24spoke3sa07c5.privatelink.blob.core.windows.net
Address: 10.11.7.99
```

We can see that the storage account hostname resolves to the private endpoint ***10.11.7.99*** in ***hub1***. The following is a summary of the DNS resolution from `Vwan24-branch1-vm`:

- On-premises server `Vwan24-branch1-vm` makes a DNS request for `vwan24spoke3sa07c5.blob.core.windows.net`
- The request is received by on-premises DNS server `Vwan24-branch1-dns`
- The DNS server resolves `vwan24spoke3sa07c5.blob.core.windows.net` to the CNAME `vwan24spoke3sa07c5.privatelink.blob.core.windows.net`
- The DNS server has a conditional DNS forwarding defined in the branch1 unbound DNS configuration file, [output/branch1-unbound.sh](./output/branch1-unbound.sh).

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

Sample output

```sh
Hello, World!
```

### 7. Virtual WAN Routes

**7.1.** Go back to the lab directory `azure-network-terraform/2-virtual-wan/4-vwan-sec-dual-region`

**7.2.** Display the virtual WAN routing table(s)

```sh
bash ../../scripts/_routes_vwan.sh Vwan24RG
```

Sample output

```sh
4-vwan-sec-dual-region$ bash ../../scripts/_routes_vwan.sh Vwan24RG

Resource group: Vwan24RG

vHub:       Vwan24-vhub2-hub
RouteTable: defaultRouteTable
-------------------------------------------------------

AddressPrefixes    NextHopType
-----------------  --------------
0.0.0.0/0          Azure Firewall
10.0.0.0/8         Azure Firewall
172.16.0.0/12      Azure Firewall
192.168.0.0/16     Azure Firewall
8.8.8.8/32         Azure Firewall


vHub:     Vwan24-vhub2-hub
Firewall: Vwan24-vhub2-azfw
-------------------------------------------------------

AddressPrefixes    NextHopType                 AsPath
-----------------  --------------------------  -----------------
10.4.0.0/20        Virtual Network Connection
10.22.0.0/20       Virtual Network Connection
10.22.16.0/20      Virtual Network Connection
10.5.0.0/20        HubBgpConnection            65020
10.30.0.0/24       VPN_S2S_Gateway             65003
10.10.0.0/24       Remote Hub                  65520-65520-65001
10.1.0.0/20        Remote Hub                  65520-65520
10.2.0.0/20        Remote Hub                  65520-65520-65010
10.11.0.0/20       Remote Hub                  65520-65520
10.11.16.0/20      Remote Hub                  65520-65520
0.0.0.0/0          Internet

vHub:       Vwan24-vhub1-hub
RouteTable: defaultRouteTable
-------------------------------------------------------

AddressPrefixes    NextHopType
-----------------  --------------
0.0.0.0/0          Azure Firewall
10.0.0.0/8         Azure Firewall
172.16.0.0/12      Azure Firewall
192.168.0.0/16     Azure Firewall
8.8.8.8/32         Azure Firewall


vHub:     Vwan24-vhub1-hub
Firewall: Vwan24-vhub1-azfw
-------------------------------------------------------

AddressPrefixes    NextHopType                 AsPath
-----------------  --------------------------  -----------------
10.1.0.0/20        Virtual Network Connection
10.11.0.0/20       Virtual Network Connection
10.11.16.0/20      Virtual Network Connection
10.2.0.0/20        HubBgpConnection            65010
10.4.0.0/20        Remote Hub                  65520-65520
10.5.0.0/20        Remote Hub                  65520-65520-65020
10.30.0.0/24       Remote Hub                  65520-65520-65003
10.22.0.0/20       Remote Hub                  65520-65520
10.22.16.0/20      Remote Hub                  65520-65520
10.10.0.0/24       VPN_S2S_Gateway             65001
0.0.0.0/0          Internet
```

### 8. On-premises Routes

**8.1** Login to on-premises virtual machine `Vwan24-branch1-nva` via the [serial console](https://learn.microsoft.com/en-us/troubleshoot/azure/virtual-machines/serial-console-overview#access-serial-console-for-virtual-machines-via-azure-portal):
  - username = ***azureuser***
  - password = ***Password123***

**8.2.** Enter the Cisco ***enable*** mode

```sh
enable
```

**8.4.** Display the routing table by typing `show ip route` and pressing the space bar to show the complete output.

```sh
show ip route
```

Sample output

```sh
Vwan24-branch1-nva-vm#show ip route
...
[Truncated for brevity]
...
Gateway of last resort is 10.10.1.1 to network 0.0.0.0

S*    0.0.0.0/0 [1/0] via 10.10.1.1
      10.0.0.0/8 is variably subnetted, 18 subnets, 4 masks
B        10.1.0.0/20 [20/0] via 192.168.11.12, 04:13:04
B        10.2.0.0/20 [20/0] via 192.168.11.12, 04:13:04
B        10.4.0.0/20 [20/0] via 192.168.11.12, 04:13:04
B        10.5.0.0/20 [20/0] via 192.168.11.12, 04:13:04
S        10.10.0.0/24 [1/0] via 10.10.2.1
C        10.10.1.0/24 is directly connected, GigabitEthernet1
L        10.10.1.9/32 is directly connected, GigabitEthernet1
C        10.10.2.0/24 is directly connected, GigabitEthernet2
L        10.10.2.9/32 is directly connected, GigabitEthernet2
C        10.10.10.0/30 is directly connected, Tunnel0
L        10.10.10.1/32 is directly connected, Tunnel0
C        10.10.10.4/30 is directly connected, Tunnel1
L        10.10.10.5/32 is directly connected, Tunnel1
B        10.11.0.0/20 [20/0] via 192.168.11.12, 04:13:04
B        10.11.16.0/20 [20/0] via 192.168.11.12, 04:13:04
B        10.22.0.0/20 [20/0] via 192.168.11.12, 04:13:04
B        10.22.16.0/20 [20/0] via 192.168.11.12, 04:13:04
B        10.30.0.0/24 [20/0] via 192.168.11.12, 04:13:04
      168.63.0.0/32 is subnetted, 1 subnets
S        168.63.129.16 [254/0] via 10.10.1.1
      169.254.0.0/32 is subnetted, 1 subnets
S        169.254.169.254 [254/0] via 10.10.1.1
      192.168.10.0/32 is subnetted, 1 subnets
C        192.168.10.10 is directly connected, Loopback0
      192.168.11.0/24 is variably subnetted, 3 subnets, 2 masks
B        192.168.11.0/24 [20/0] via 192.168.11.12, 04:13:04
S        192.168.11.12/32 is directly connected, Tunnel1
S        192.168.11.13/32 is directly connected, Tunnel0
```

We can see the Vnet ranges learned dynamically via BGP.

**8.5.** Display BGP information by typing `show ip bgp`.

```sh
show ip bgp
```

Sample output

```sh
Vwan24-branch1-nva#show ip bgp
BGP table version is 13, local router ID is 192.168.10.10
Status codes: s suppressed, d damped, h history, * valid, > best, i - internal,
              r RIB-failure, S Stale, m multipath, b backup-path, f RT-Filter,
              x best-external, a additional-path, c RIB-compressed,
              t secondary path, L long-lived-stale,
Origin codes: i - IGP, e - EGP, ? - incomplete
RPKI validation codes: V valid, I invalid, N Not found

     Network          Next Hop            Metric LocPrf Weight Path
 r    0.0.0.0          192.168.11.13                          0 65515 i
 r>                    192.168.11.12                          0 65515 i
 *    10.1.0.0/20      192.168.11.13                          0 65515 i
 *>                    192.168.11.12                          0 65515 i
 *    10.2.0.0/20      192.168.11.13            0             0 65515 65010 i
 *>                    192.168.11.12            0             0 65515 65010 i
 *    10.4.0.0/20      192.168.11.13                          0 65515 65520 65520 e
 *>                    192.168.11.12                          0 65515 65520 65520 e
 *    10.5.0.0/20      192.168.11.13                          0 65515 65520 65520 65020 e
 *>                    192.168.11.12                          0 65515 65520 65520 65020 e
     Network          Next Hop            Metric LocPrf Weight Path
 *>   10.10.0.0/24     10.10.2.1                0         32768 i
 *    10.11.0.0/20     192.168.11.13                          0 65515 i
 *>                    192.168.11.12                          0 65515 i
 *    10.11.16.0/20    192.168.11.13                          0 65515 i
 *>                    192.168.11.12                          0 65515 i
 *    10.22.0.0/20     192.168.11.13                          0 65515 65520 65520 e
 *>                    192.168.11.12                          0 65515 65520 65520 e
 *    10.22.16.0/20    192.168.11.13                          0 65515 65520 65520 e
 *>                    192.168.11.12                          0 65515 65520 65520 e
 *>   10.30.0.0/24     192.168.11.12                          0 65515 65520 65520 65003 e
 *                     192.168.11.13                          0 65515 65520 65520 65003 e
 *    192.168.11.0     192.168.11.13                          0 65515 i
 *>                    192.168.11.12                          0 65515 i
```

We can see our hub and spoke Vnet ranges being learned dynamically in the BGP table.

### 9. Azure Firewall (Optional)

To view firewall logs, set `enable_diagnostics = true` in the [`main.tf`](./02-main.tf). Then run `terraform apply` to update the deployment. Wait for about 15 minutes to get some logs.

**9.1.** Check the Azure Firewall logs to observe the traffic flow.

- Select the Azure Firewall resource `Vwan24-hub1-azfw` in the Azure portal.
- Click on **Logs** in the left navigation pane.
- Click on **Firewall Logs (Resource Specific Tables)**.
- Click on **Run** in the log category *Network rule logs*.

   <img src="../../images/demos/virtual-wan/vwan24-hub1-net-rule-log.png" alt="Network rule log" width="1000">

Observe the firewall logs based on traffic flows generated from our tests.

<img src="../../images/demos/virtual-wan/vwan24-hub1-net-rule-log-detail.png" alt="Network rule log data" width="1200">

**9.2** Repeat the same steps for the Azure Firewall resource `Vwan24-hub2-azfw`.

## Cleanup

1. (Optional) Navigate back to the lab directory (if you are not already there)

   ```sh
   cd azure-network-terraform/2-virtual-wan/4-vwan-sec-dual-region
   ```

2. (Optional) This is not required if you have not set `enable_diagnostics = true` in the [`main.tf`](./02-main.tf). In order to avoid terraform errors when re-deploying this lab, run a cleanup script to remove diagnostic settings that may not be removed after the resource group is deleted.

   ```sh
   bash ../../scripts/_cleanup.sh Vwan24
   ```

   Sample output

   ```sh
   4-vwan-sec-dual-region$    bash ../../scripts/_cleanup.sh Vwan24

   Resource group: Vwan24RG

   ⏳ Checking for diagnostic settings on resources in Vwan24RG ...
   ➜  Checking firewall ...
       ❌ Deleting: diag setting [Vwan24-vhub1-azfw-diag] for firewall [Vwan24-vhub1-azfw] ...
       ❌ Deleting: diag setting [Vwan24-vhub2-azfw-diag] for firewall [Vwan24-vhub2-azfw] ...
   ➜  Checking vnet gateway ...
   ➜  Checking vpn gateway ...
       ❌ Deleting: diag setting [Vwan24-vhub1-vpngw-diag] for vpn gateway [Vwan24-vhub1-vpngw] ...
       ❌ Deleting: diag setting [Vwan24-vhub2-vpngw-diag] for vpn gateway [Vwan24-vhub2-vpngw] ...
   ➜  Checking er gateway ...
   ➜  Checking app gateway ...
   ⏳ Checking for azure policies in Vwan24RG ...
   Done!
   ```

3. Delete the resource group to remove all resources installed.

   ```sh
   az group delete -g Vwan24RG --no-wait
   ```

4. Delete terraform state files and other generated files.

   ```sh
   rm -rf .terraform*
   rm terraform.tfstate*
   ```
