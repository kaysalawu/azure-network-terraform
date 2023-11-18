# Hub and Spoke - Dual Region <!-- omit from toc -->
## Lab: Hs14 <!-- omit from toc -->

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
  - [5. Network Virtual Appliance (NVA)](#5-network-virtual-appliance-nva)
  - [6. Onprem Routes](#6-onprem-routes)
- [Cleanup](#cleanup)

## Overview

This terraform code deploys a multi-region Virtual Network (Vnet) hub and spoke topology with dynamic routing using Network Virtual Aplliance (NVA) and Azure Route Server (ARS).

![Hub and Spoke (Dual region)](../../images/scenarios/1-4-hub-spoke-nva-dual-region.png)

`Hub1` has an Azure Route Server (ARS) with BGP session to a Network Virtual Appliance (NVA) using a Cisco-CSR-100V router. The direct spokes `Spoke1` and `Spoke2` have Vnet peering to `Hub1`. An isolated spoke (`Spoke3`) does not have Vnet peering to the hub (`Hub1`), but is reachable from the hub via Private Link Service.

`Hub2` has an ARS with BGP session to an NVA using a Cisco-CSR-100V router. The direct spokes `Spoke4` and `Spoke5` have Vnet peering to `Hub2`. An isolated `Spoke6` does not have Vnet peering to the `Hub2`, but is reachable from the hub via Private Link Service.

The hubs are connected together via IPsec VPN overlay and BGP dynamic routing to allow multi-region network reachability.

`Branch1` and `Branch3` are on-premises networks which are simulated using Vnets. Multi-NIC Cisco-CSR-1000V NVA appliances connect to the Vnet hubs using IPsec VPN connections with dynamic (BGP) routing.

## Prerequisites

Ensure you meet all requirements in the [prerequisites](../../prerequisites/) before proceeding.

## Deploy the Lab

1. Clone the Git Repository for the Labs
```sh
git clone https://github.com/kaysalawu/azure-network-terraform.git
```

2. Navigate to the lab directory
```sh
cd azure-network-terraform/1-hub-and-spoke/4-hub-spoke-nva-dual-region
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

Login to virtual machine `Hs14-spoke1-vm` via the serial console.
- username = **azureuser**
- password = **Password123**

![Hs14-spoke1-vm](../../images/demos/hs14-spoke1-vm.png)

Run the following tests from inside the serial console session.

### 1. Ping IP

This script pings the IP addresses of some test virtual machines and reports reachability and round trip time.

1.1. Run the IP ping test
```sh
ping-ip
```
Sample output
```sh
azureuser@Hs14-spoke1-vm:~$ ping-ip

 ping ip ...

branch1 - 10.10.0.5 -OK 6.574 ms
hub1    - 10.11.0.5 -OK 4.616 ms
spoke1  - 10.1.0.5 -OK 0.032 ms
spoke2  - 10.2.0.5 -OK 4.738 ms
branch3 - 10.30.0.5 -OK 22.287 ms
hub2    - 10.22.0.5 -OK 21.208 ms
spoke4  - 10.4.0.5 -OK 21.574 ms
spoke5  - 10.5.0.5 -OK 20.790 ms
internet - icanhazip.com -NA
```

### 2. Ping DNS

This script pings the DNS name of some test virtual machines and reports reachability and round trip time.

2.1. Run the DNS ping test
```sh
ping-dns
```

Sample output
```sh
azureuser@Hs14-spoke1-vm:~$ ping-dns

 ping dns ...

vm.branch1.corp - 10.10.0.5 -OK 6.902 ms
vm.hub1.az.corp - 10.11.0.5 -OK 4.253 ms
vm.spoke1.az.corp - 10.1.0.5 -OK 0.029 ms
vm.spoke2.az.corp - 10.2.0.5 -OK 5.066 ms
vm.branch3.corp - 10.30.0.5 -OK 21.902 ms
vm.hub2.az.corp - 10.22.0.5 -OK 20.679 ms
vm.spoke4.az.corp - 10.4.0.5 -OK 21.885 ms
vm.spoke5.az.corp - 10.5.0.5 -OK 21.008 ms
icanhazip.com - 104.18.114.97 -NA
```

### 3. Curl DNS

This script uses curl to check reachability of web server (python Flask) on the test virtual machines. It reports HTTP response message, round trip time and IP address.

3.1. Run the DNS curl test
```sh
curl-dns
```

Sample output
```sh
azureuser@Hs14-spoke1-vm:~$ curl-dns

 curl dns ...

200 (0.039655s) - 10.10.0.5 - vm.branch1.corp
200 (0.032831s) - 10.11.0.5 - vm.hub1.az.corp
200 (0.024300s) - 10.11.4.4 - spoke3.p.hub1.az.corp
[ 9308.555585] cloud-init[1568]: 10.1.0.5 - - [17/Sep/2023 15:19:40] "GET / HTTP/1.1" 200 -
200 (0.024380s) - 10.1.0.5 - vm.spoke1.az.corp
200 (0.032727s) - 10.2.0.5 - vm.spoke2.az.corp
000 (2.000988s) -  - vm.spoke3.az.corp
200 (0.070766s) - 10.30.0.5 - vm.branch3.corp
200 (0.069757s) - 10.22.0.5 - vm.hub2.az.corp
200 (0.069787s) - 10.22.4.4 - spoke6.p.hub2.az.corp
200 (0.074629s) - 10.4.0.5 - vm.spoke4.az.corp
200 (0.068120s) - 10.5.0.5 - vm.spoke5.az.corp
000 (2.001429s) -  - vm.spoke6.az.corp
200 (0.023326s) - 104.18.115.97 - icanhazip.com
```
We can see that spoke3 `vm.spoke3.az.corp` returns a **000** HTTP response code. This is expected since there is no Vnet peering to `Spoke3` from `Hub1`. But `Spoke3` web application is reachable via Private Link Service private endpoint `spoke3.p.hub1.az.corp`. The same explanation applies to `Spoke6` virtual machine `vm.spoke6.az.corp`

### 4. Private Link Service

Test access to `Spoke3` application using the private endpoint in `Hub1`.
```sh
curl spoke3.p.hub1.az.corp
```

Sample output
```sh
azureuser@Hs14-spoke1-vm:~$ curl spoke3.p.hub1.az.corp
{
  "headers": {
    "Accept": "*/*",
    "Host": "spoke3.p.hub1.az.corp",
    "User-Agent": "curl/7.68.0"
  },
  "hostname": "Hs14-spoke3-vm",
  "local-ip": "10.3.0.5",
  "remote-ip": "10.3.3.4"
}
```
Test access to `Spoke6` application using the private endpoint in `Hub2`.
```sh
curl spoke6.p.hub2.az.corp
```

Sample output
```sh
azureuser@Hs14-spoke1-vm:~$ curl spoke6.p.hub2.az.corp
{
  "headers": {
    "Accept": "*/*",
    "Host": "spoke6.p.hub2.az.corp",
    "User-Agent": "curl/7.68.0"
  },
  "hostname": "Hs14-spoke6-vm",
  "local-ip": "10.6.0.5",
  "remote-ip": "10.6.3.4"
}
```

The `Hostname` and `Local-IP` fields belong to the servers running the web application - in this case `Spoke3` and `Spoke6`virtual machines. The `Remote-IP` fields (as seen by the web servers) are the respective IP addresses in the Private Link Service NAT subnets.

### 5. Network Virtual Appliance (NVA)

1. Run a tracepath to `vm.spoke2.az.corp` (10.2.0.5) to observe the traffic flow through the NVA.

```sh
tracepath vm.spoke2.az.corp
```

Sample output
```sh
azureuser@Hs14-spoke1-vm:~$ tracepath vm.spoke2.az.corp
 1?: [LOCALHOST]                      pmtu 1500
 1:  10.11.1.9                                             2.452ms
 1:  10.11.1.9                                             2.265ms
 2:  10.2.0.5                                              5.295ms reached
     Resume: pmtu 1500 hops 2 back 2
```

We can observe the traffic flow from `Spoke1` to `Spoke2` goes through the NVA in `Hub1` (IP address 10.11.1.9) before reaching the destination `Spoke2` (10.2.0.5).

2. Run a tracepath to `vm.spoke5.az.corp` (10.5.0.5) to observe the traffic flow through the NVA in both hubs.

```sh
tracepath vm.spoke5.az.corp
```

Sample output
```sh
azureuser@Hs14-spoke1-vm:~$ tracepath vm.spoke5.az.corp
 1?: [LOCALHOST]                      pmtu 1500
 1:  10.11.1.9                                             2.551ms
 1:  10.11.1.9                                             2.445ms
 2:  10.11.1.9                                             5.484ms pmtu 1446
 2:  10.22.50.1                                           20.987ms
 3:  10.5.0.5                                             21.653ms reached
     Resume: pmtu 1446 hops 3 back 3
```

We can observe the traffic flow from `Spoke1` to `Spoke5` as summarized below:
-  traffic flows through the NVA in `Hub1` (10.11.1.9)
-  then traverses NVA in `Hub2` (10.22.50.1 is the IPsec overlay IP address)
-  then reaches the final destination `Spoke5` (10.5.0.5).


### 6. Onprem Routes

Let's login to the onprem router `Hs14-branch1-nva` and observe its dynamic routes.

1. Login to virtual machine `Hs14-branch1-nva` via the serial console.
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
Hs14-branch1-nva-vm#show ip route
...
[Truncated for brevity]
...
Gateway of last resort is 10.10.1.1 to network 0.0.0.0

S*    0.0.0.0/0 [1/0] via 10.10.1.1
      10.0.0.0/8 is variably subnetted, 18 subnets, 4 masks
B        10.1.0.0/16 [20/0] via 10.11.7.4, 01:35:19
B        10.2.0.0/16 [20/0] via 10.11.7.4, 01:35:19
B        10.4.0.0/16 [20/0] via 10.11.7.5, 00:58:33
B        10.5.0.0/16 [20/0] via 10.11.7.5, 00:58:33
S        10.10.0.0/24 [1/0] via 10.10.2.1
C        10.10.1.0/24 is directly connected, GigabitEthernet1
L        10.10.1.9/32 is directly connected, GigabitEthernet1
C        10.10.2.0/24 is directly connected, GigabitEthernet2
L        10.10.2.9/32 is directly connected, GigabitEthernet2
C        10.10.10.0/30 is directly connected, Tunnel0
L        10.10.10.1/32 is directly connected, Tunnel0
C        10.10.10.4/30 is directly connected, Tunnel1
L        10.10.10.5/32 is directly connected, Tunnel1
B        10.11.0.0/16 [20/0] via 10.11.7.4, 01:35:19
S        10.11.7.4/32 is directly connected, Tunnel1
S        10.11.7.5/32 is directly connected, Tunnel0
B        10.22.0.0/16 [20/0] via 10.11.7.5, 00:58:33
B        10.30.0.0/24 [20/0] via 10.11.7.5, 00:58:33
      168.63.0.0/32 is subnetted, 1 subnets
S        168.63.129.16 [254/0] via 10.10.1.1
      169.254.0.0/32 is subnetted, 1 subnets
S        169.254.169.254 [254/0] via 10.10.1.1
      192.168.10.0/32 is subnetted, 1 subnets
C        192.168.10.10 is directly connected, Loopback0
```

5. Display BGP information by typing `show ip bgp` and pressing the space bar to show the complete output.
```sh
show ip bgp
```

Sample output
```sh
Hs14-branch1-nva-vm#show ip bgp
BGP table version is 9, local router ID is 192.168.10.10
Status codes: s suppressed, d damped, h history, * valid, > best, i - internal,
              r RIB-failure, S Stale, m multipath, b backup-path, f RT-Filter,
              x best-external, a additional-path, c RIB-compressed,
              t secondary path, L long-lived-stale,
Origin codes: i - IGP, e - EGP, ? - incomplete
RPKI validation codes: V valid, I invalid, N Not found

     Network          Next Hop            Metric LocPrf Weight Path
 *    10.1.0.0/16      10.11.7.5                              0 65515 i
 *>                    10.11.7.4                              0 65515 i
 *    10.2.0.0/16      10.11.7.5                              0 65515 i
 *>                    10.11.7.4                              0 65515 i
 *    10.4.0.0/16      10.11.7.4                              0 65515 65000 65000 i
 *>                    10.11.7.5                              0 65515 65000 65000 i
 *    10.5.0.0/16      10.11.7.4                              0 65515 65000 65000 i
 *>                    10.11.7.5                              0 65515 65000 65000 i
 *>   10.10.0.0/24     10.10.2.1                0         32768 i
 *    10.11.0.0/16     10.11.7.5                              0 65515 i
     Network          Next Hop            Metric LocPrf Weight Path
 *>                    10.11.7.4                              0 65515 i
 *    10.22.0.0/16     10.11.7.4                              0 65515 65000 65000 i
 *>                    10.11.7.5                              0 65515 65000 65000 i
 *    10.30.0.0/24     10.11.7.4                              0 65515 65000 65000 65003 i
 *>                    10.11.7.5                              0 65515 65000 65000 65003 i
```

## Cleanup

1. Make sure you are in the lab directory
```sh
cd azure-network-terraform/1-hub-and-spoke/4-hub-spoke-nva-dual-region
```

Delete the resource group to remove all resources installed.\
Run the following Azure CLI command:

```sh
az group delete -g Hs14RG --no-wait
```
