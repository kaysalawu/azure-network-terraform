# Hub and Spoke - Dual Region <!-- omit from toc -->

Contents
- [Overview](#overview)
- [Prerequisites](#prerequisites)
- [Deploy the Lab](#deploy-the-lab)
- [Troubleshooting](#troubleshooting)
- [Testing](#testing)
  - [1. Ping IP](#1-ping-ip)
  - [2. Ping DNS](#2-ping-dns)
  - [3. Curl DNS](#3-curl-dns)
  - [4. Private Link Service](#4-private-link-service)
  - [5. Onprem Routes](#5-onprem-routes)
- [Cleanup](#cleanup)

## Overview

This terraform code deploys a multi-region standard hub and spoke topology playground.

`Hub1` has an Azure Route Server (ARS) with BGP session to a Network Virtual Appliance (NVA) using a Cisco-CSR-100V router. The direct spokes `Spoke1` and `Spoke2` have VNET peering to `Hub1`. An isolated `Spoke3` does not have VNET peering to the ``Hub1, but is reachable from the hub via Private Link Service.

`Hub2` has an ARS with BGP session to an NVA using a Cisco-CSR-100V router. The direct spokes `Spoke4` and `Spoke5` have VNET peering to `Hub2`. An isolated `Spoke6` does not have VNET peering to the `Hub2`, but is reachable from the hub via Private Link Service.

The hubs are connected together via IPsec VPN and BGP dynamic routing to allow multi-region network reachability.

`Branch1` and `Branch3`are the on-premises networks which are simulated in VNETs using multi-NIC Cisco-CSR-100V NVA appliances.

![Hub and Spoke (Dual region)](../../images/scenarios//1-2-hub-spoke-dual-region.png)

## Prerequisites

Ensure you meet all requirements in the [prerequisites](../../prerequisites/) before proceeding.

## Deploy the Lab

1. Clone the Git Repository for the Labs
```sh
git clone https://github.com/kaysalawu/azure-network-terraform.git
```

2. Navigate to the lab directory
```sh
cd azure-network-terraform/1-hub-and-spoke/2-hub-spoke-dual-region
```

3. Run the following terraform commands and type **yes** at the prompt:
```sh
terraform init
terraform plan
terraform apply
```

## Troubleshooting

See the [troubleshooting](../../troubleshooting/) section for tips on how to resolve common issues that may occur during the deployment of the lab.

## Testing

Each virtual machine is pre-configured with a shell [script](../../scripts/server.sh) to run various types of tests. Serial console access has been configured for all virtual mchines. You can [access the serial console](https://learn.microsoft.com/en-us/troubleshoot/azure/virtual-machines/serial-console-overview#access-serial-console-for-virtual-machines-via-azure-portal) of a virtual machine from the Azure portal.

Login to virtual machine `HubSpokeS2-spoke1-vm` via the serial console.
- username = **azureuser**
- password = **Password123**

![HubSpokeS2-spoke1-vm](../../images/demos/hubspokes2-spoke1-vm.png)

Run the following tests from inside the serial console session.

### 1. Ping IP

This script pings the IP addresses of some test virtual machines and reports reachability and round trip time.

1.1. Run the IP ping test
```sh
ping-ip
```
Sample output
```sh
azureuser@HubSpokeS2-spoke1-vm:~$ ping-ip

 ping ip ...

branch1 - 10.10.0.5 -OK 7.984 ms
hub1    - 10.11.0.5 -OK 1.179 ms
spoke1  - 10.1.0.5 -OK 0.043 ms
spoke2  - 10.2.0.5 -OK 4.964 ms
branch3 - 10.30.0.5 -OK 30.264 ms
hub2    - 10.22.0.5 -OK 18.955 ms
spoke4  - 10.4.0.5 -OK 19.610 ms
spoke5  - 10.5.0.5 -OK 19.025 ms
```

### 2. Ping DNS

This script pings the DNS name of some test virtual machines and reports reachability and round trip time.

2.1. Run the DNS ping test
```sh
ping-dns
```

Sample output
```sh
azureuser@HubSpokeS2-spoke1-vm:~$ ping-dns

 ping dns ...

vm.branch1.corp.net - 10.10.0.5 -OK 5.791 ms
vm.hub1.az.corp.net - 10.11.0.5 -OK 1.710 ms
vm.spoke1.az.corp.net - 10.1.0.5 -OK 0.042 ms
vm.spoke2.az.corp.net - 10.2.0.5 -OK 4.848 ms
vm.branch3.corp.net - 10.30.0.5 -OK 21.400 ms
vm.hub2.az.corp.net - 10.22.0.5 -OK 19.483 ms
vm.spoke4.az.corp.net - 10.4.0.5 -OK 18.950 ms
vm.spoke5.az.corp.net - 10.5.0.5 -OK 19.209 ms
```

### 3. Curl DNS

This script uses curl to check reachability of web server (python Flask) on the test virtual machines. It reports HTTP response message, round trip time and IP address.

3.1. Run the DNS curl test
```sh
curl-dns
```

Sample output
```sh
azureuser@HubSpokeS2-spoke1-vm:~$ curl-dns

 curl dns ...

200 (0.043893s) - 10.10.0.5 - vm.branch1.corp.net
200 (0.018958s) - 10.11.0.5 - vm.hub1.az.corp.net
200 (0.018440s) - 10.11.4.4 - spoke3.p.hub1.az.corp.net
[ 3627.717619] cloud-init[1515]: 10.1.0.5 - - [21/Jan/2023 18:19:01] "GET / HTTP/1.1" 200 -
200 (0.016111s) - 10.1.0.5 - vm.spoke1.az.corp.net
200 (0.100426s) - 10.2.0.5 - vm.spoke2.az.corp.net
000 (2.000390s) -  - vm.spoke3.az.corp.net
200 (0.064293s) - 10.30.0.5 - vm.branch3.corp.net
200 (0.086481s) - 10.22.0.5 - vm.hub2.az.corp.net
200 (0.066288s) - 10.22.3.4 - spoke6.p.hub2.az.corp.net
200 (0.082019s) - 10.4.0.5 - vm.spoke4.az.corp.net
200 (0.228785s) - 10.5.0.5 - vm.spoke5.az.corp.net
000 (2.001621s) -  - vm.spoke6.az.corp.net
```
We can see that spoke3 `vm.spoke3.az.corp.net` returns a **000** HTTP response code. This is expected since there is no Vnet peering to `Spoke3` from `Hub1`. But `Spoke3` web application is reachable via Private Link Service private endpoint `spoke3.p.hub1.az.corp.net`. The same explanation applies to `Spoke6` virtual machine `vm.spoke6.az.corp.net`

### 4. Private Link Service

Test access to `Spoke3` application using the private endpoint in `Hub1`.
```sh
curl spoke3.p.hub1.az.corp.net
```

Sample output
```sh
azureuser@HubSpokeS2-spoke1-vm:~$ curl spoke3.p.hub1.az.corp.net
{
  "headers": {
    "Accept": "*/*",
    "Host": "spoke3.p.hub1.az.corp.net",
    "User-Agent": "curl/7.68.0"
  },
  "hostname": "HubSpokeS2-spoke3-vm",
  "local-ip": "10.3.0.5",
  "remote-ip": "10.3.3.4"
}
```
Test access to `Spoke6` application using the private endpoint in `Hub2`.
```sh
curl spoke6.p.hub2.az.corp.net
```

Sample output
```sh
azureuser@HubSpokeS2-spoke1-vm:~$ curl spoke6.p.hub2.az.corp.net
{
  "headers": {
    "Accept": "*/*",
    "Host": "spoke6.p.hub2.az.corp.net",
    "User-Agent": "curl/7.68.0"
  },
  "hostname": "HubSpokeS2-spoke6-vm",
  "local-ip": "10.6.0.5",
  "remote-ip": "10.6.3.4"
}
```

The `Hostname` and `Local-IP` fields belong to the servers running the web application - in this case `Spoke3` and `Spoke6`virtual machines. The `Remote-IP` fields (as seen by the web servers) are the respective IP addresses in the Private Link Service NAT subnets.

Repeat steps 1-4 for all other virtual machines.

### 5. Onprem Routes

Let's login to the onprem router `HubSpokeS2-branch1-nva` and observe its dynamic routes.

1. Login to virtual machine `HubSpokeS2-branch1-nva` via the serial console.
2. Enter username and password
   - username = **azureuser**
   - password = **Password123**
3. Enter the Cisco enable mode
```sh
enable
```
4. Display the routing table by typing `show ip route` and pressing the space bar to show the complete output.
```sh
show ip route
```

Sample output
```sh
HubSpokeS2-branch1-nva-vm#show ip route
[Truncated]
...
Gateway of last resort is 10.10.1.1 to network 0.0.0.0

S*    0.0.0.0/0 [1/0] via 10.10.1.1
      10.0.0.0/8 is variably subnetted, 18 subnets, 4 masks
B        10.1.0.0/16 [20/0] via 10.11.7.4, 00:36:26
B        10.2.0.0/16 [20/0] via 10.11.7.4, 00:36:26
B        10.4.0.0/16 [20/0] via 10.11.7.5, 00:19:36
B        10.5.0.0/16 [20/0] via 10.11.7.5, 00:19:36
S        10.10.0.0/24 [1/0] via 10.10.2.1
C        10.10.1.0/24 is directly connected, GigabitEthernet1
L        10.10.1.9/32 is directly connected, GigabitEthernet1
C        10.10.2.0/24 is directly connected, GigabitEthernet2
L        10.10.2.9/32 is directly connected, GigabitEthernet2
C        10.10.10.0/30 is directly connected, Tunnel0
L        10.10.10.1/32 is directly connected, Tunnel0
C        10.10.10.4/30 is directly connected, Tunnel1
L        10.10.10.5/32 is directly connected, Tunnel1
B        10.11.0.0/16 [20/0] via 10.11.7.4, 00:36:26
S        10.11.7.4/32 is directly connected, Tunnel0
S        10.11.7.5/32 is directly connected, Tunnel1
B        10.22.0.0/16 [20/0] via 10.11.7.5, 00:19:36
B        10.30.0.0/24 [20/0] via 10.11.7.5, 00:19:36
      168.63.0.0/32 is subnetted, 1 subnets
S        168.63.129.16 [254/0] via 10.10.1.1
      169.254.0.0/32 is subnetted, 1 subnets
S        169.254.169.254 [254/0] via 10.10.1.1
      192.168.10.0/32 is subnetted, 1 subnets
C        192.168.10.10 is directly connected, Loopback0
```

5. Show BGP information
```sh
HubSpokeS2-branch1-nva-vm#show ip bgp
BGP table version is 9, local router ID is 192.168.10.10
Status codes: s suppressed, d damped, h history, * valid, > best, i - internal,
              r RIB-failure, S Stale, m multipath, b backup-path, f RT-Filter,
              x best-external, a additional-path, c RIB-compressed,
              t secondary path, L long-lived-stale,
Origin codes: i - IGP, e - EGP, ? - incomplete
RPKI validation codes: V valid, I invalid, N Not found

     Network          Next Hop            Metric LocPrf Weight Path
 *>   10.1.0.0/16      10.11.7.4                              0 65515 i
 *                     10.11.7.5                              0 65515 i
 *>   10.2.0.0/16      10.11.7.4                              0 65515 i
 *                     10.11.7.5                              0 65515 i
 *    10.4.0.0/16      10.11.7.4                              0 65515 65000 65000 i
 *>                    10.11.7.5                              0 65515 65000 65000 i
 *    10.5.0.0/16      10.11.7.4                              0 65515 65000 65000 i
 *>                    10.11.7.5                              0 65515 65000 65000 i
 *>   10.10.0.0/24     10.10.2.1                0         32768 i
 *>   10.11.0.0/16     10.11.7.4                              0 65515 i
     Network          Next Hop            Metric LocPrf Weight Path
 *                     10.11.7.5                              0 65515 i
 *    10.22.0.0/16     10.11.7.4                              0 65515 65000 65000 i
 *>                    10.11.7.5                              0 65515 65000 65000 i
 *    10.30.0.0/24     10.11.7.4                              0 65515 65000 65000 65003 i
 *>                    10.11.7.5                              0 65515 65000 65000 65003 i
```

## Cleanup

1. Navigate to the lab directory
```sh
cd azure-network-terraform/1-hub-and-spoke/2-hub-spoke-dual-region
```

Delete the resource group to remove all resources installed.\
Run the following Azure CLI command:

```sh
az group delete -g HubSpokeS2RG --no-wait
```
