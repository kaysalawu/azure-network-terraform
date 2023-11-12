
# Virtual WAN - Dual Hub (Mixed) <!-- omit from toc -->

Contents- [Overview](#overview)
- [Overview](#overview)
- [Prerequisites](#prerequisites)
- [Deploy the Lab](#deploy-the-lab)
- [Troubleshooting](#troubleshooting)
- [Testing](#testing)
  - [1. Ping IP](#1-ping-ip)
  - [2. Ping DNS](#2-ping-dns)
  - [3. Curl DNS](#3-curl-dns)
  - [4. Private Link Service](#4-private-link-service)
  - [5. Virtual WAN Routes](#5-virtual-wan-routes)
  - [6. Onprem Routes](#6-onprem-routes)
- [Cleanup](#cleanup)

## Overview

This terraform code deploys a multi-hub (multi-region) virtual WAN architecture playground to observe dynamic routing patterns.

For one region, we integrate the standard hub (`hub1`) to the virtual WAN hub (`vHub1`) via a virtual WAN connection. `vHub1` has a direct spoke (`Spoke1`) connected via a virtual WAN connection. `Spoke2` is an indirect spoke from a virtual WAN perspective; and is connected via standard VNET peering to `Hub1`.

For the second region, we integrate the standard hub (`hub2`) to the virtual WAN hub (`vHub2`) via an IPsec VPN connection. `vHub2` has a direct spoke (`Spoke4`) connected via a virtual WAN connection. `Spoke5` is an indirect spoke from a virtual WAN perspective; and is connected via standard VNET peering to `Hub2`.

The isolated spokes (`Spoke3` and `Spoke6`) do not have VNET peering to their respective hubs (`Hub1` and `Hub2`), but are reachable via Private Link Service through a private endpoint in each hub.

`Branch1` and `Branch3`are the on-premises networks which are simulated in VNETs using multi-NIC Cisco-CSR-100V NVA appliances.

![Virtual WAN - Dual Hub (Mixed))](../../images/scenarios//2-4-vwan-dual-hub-mixed.png)

## Prerequisites

Ensure you meet all requirements in the [prerequisites](../../prerequisites/) before proceeding.

## Deploy the Lab

1. Clone the Git Repository for the Labs
```sh
git clone https://github.com/kaysalawu/azure-network-terraform.git
```

2. Navigate to the lab directory
```sh
cd azure-network-terraform/2-virtual-wan/4-virtual-wan-dual-hub-mixed
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

Login to virtual machine `VwanS4-spoke1-vm` via the serial console.
- username = **azureuser**
- password = **Password123**

![VwanS4-spoke1-vm](../../images/demos/vwans4-spoke1-vm.png)

Run the following tests from inside the serial console session.

### 1. Ping IP

This script pings the IP addresses of some test virtual machines and reports reachability and round trip time.

Run the IP ping test
```sh
ping-ip
```
Sample output
```sh
azureuser@VwanS4-spoke4-vm:~$ ping-ip

 ping ip ...

branch1 - 10.10.0.5 -OK 23.398 ms
hub1    - 10.11.0.5 -OK 22.349 ms
spoke1  - 10.1.0.5 -OK 20.888 ms
spoke2  - 10.2.0.5 -OK 22.939 ms
branch3 - 10.30.0.5 -OK 3.577 ms
hub2    - 10.22.0.5 -OK 6.271 ms
spoke4  - 10.4.0.5 -OK 0.048 ms
spoke5  - 10.5.0.5 -OK 5.342 ms
```

### 2. Ping DNS

This script pings the DNS name of some test virtual machines and reports reachability and round trip time.

Run the DNS ping test
```sh
ping-dns
```

Sample output
```sh
azureuser@VwanS4-spoke4-vm:~$ ping-dns

 ping dns ...

vm.branch1.corp - 10.10.0.5 -OK 23.548 ms
vm.hub1.az.corp - 10.11.0.5 -OK 20.944 ms
vm.spoke1.az.corp - 10.1.0.5 -OK 20.955 ms
vm.spoke2.az.corp - 10.2.0.5 -OK 22.689 ms
vm.branch3.corp - 10.30.0.5 -OK 3.632 ms
vm.hub2.az.corp - 10.22.0.5 -OK 3.317 ms
vm.spoke4.az.corp - 10.4.0.5 -OK 0.036 ms
vm.spoke5.az.corp - 10.5.0.5 -OK 5.089 ms
```

### 3. Curl DNS

This script uses curl to check reachability of web server (python Flask) on the test virtual machines. It reports HTTP response message, round trip time and IP address.

Run the DNS curl test
```sh
curl-dns
```

Sample output
```sh
azureuser@VwanS4-spoke1-vm:~$ curl-dns

 curl dns ...

200 (0.032336s) - 10.10.0.5 - vm.branch1.corp
200 (0.024778s) - 10.11.0.5 - vm.hub1.az.corp
200 (0.026894s) - 10.11.4.4 - spoke3.p.hub1.az.corp
[ 2739.010960] cloud-init[1513]: 10.1.0.5 - - [21/Jan/2023 14:20:44] "GET / HTTP/1.1" 200 -
200 (0.015086s) - 10.1.0.5 - vm.spoke1.az.corp
200 (0.076300s) - 10.2.0.5 - vm.spoke2.az.corp
000 (2.000957s) -  - vm.spoke3.az.corp
200 (0.065216s) - 10.30.0.5 - vm.branch3.corp
200 (0.099569s) - 10.22.0.5 - vm.hub2.az.corp
200 (0.105734s) - 10.22.3.4 - spoke6.p.hub2.az.corp
200 (0.197329s) - 10.4.0.5 - vm.spoke4.az.corp
200 (0.115386s) - 10.5.0.5 - vm.spoke5.az.corp
000 (2.000373s) -  - vm.spoke6.az.corp
```
We can see that spoke3 `vm.spoke3.az.corp` returns a **000** HTTP response code. This is expected since there is no Vnet peering to `Spoke3` from `Hub1`. But `Spoke3` web application is reachable via Private Link Service private endpoint `spoke3.p.hub1.az.corp`. The same explanation applies to `Spoke6` virtual machine `vm.spoke6.az.corp`

### 4. Private Link Service

Test access to `Spoke3` application using the private endpoint in `Hub1`.
```sh
curl spoke3.p.hub1.az.corp
```

Sample output
```sh
azureuser@VwanS4-spoke1-vm:~$ curl spoke3.p.hub1.az.corp
{
  "headers": {
    "Accept": "*/*",
    "Host": "spoke3.p.hub1.az.corp",
    "User-Agent": "curl/7.68.0"
  },
  "hostname": "VwanS4-spoke3-vm",
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
azureuser@VwanS4-spoke1-vm:~$ curl spoke6.p.hub2.az.corp
{
  "headers": {
    "Accept": "*/*",
    "Host": "spoke6.p.hub2.az.corp",
    "User-Agent": "curl/7.68.0"
  },
  "hostname": "VwanS4-spoke6-vm",
  "local-ip": "10.6.0.5",
  "remote-ip": "10.6.3.4"
}
```

The `Hostname` and `Local-IP` fields belong to the servers running the web application - in this case `Spoke3` and `Spoke6`virtual machines. The `Remote-IP` fields (as seen by the web servers) are the respective IP addresses in the Private Link Service NAT subnets.

Repeat steps 1-4 for all other virtual machines.

### 5. Virtual WAN Routes

1. Ensure you are in the lab directory `azure-network-terraform/2-virtual-wan/4-virtual-wan-dual-hub-mixed`
2. Display the virtual WAN routing table(s)

```sh
bash ../../scripts/_routes.sh VwanS4RG
```

Sample output
```sh
salawu$ bash ../../scripts/_routes.sh VwanS4RG

Resource group: VwanS4RG

vHUB: VwanS4-vhub2-hub
Effective route table: defaultRouteTable
AddressPrefixes    AsPath             NextHopType
-----------------  -----------------  --------------------------
10.22.0.0/16       65021              VPN_S2S_Gateway
10.5.0.0/16        65021              VPN_S2S_Gateway
10.30.0.0/24       65003              VPN_S2S_Gateway
10.1.0.0/16        65520-65520        Remote Hub
10.10.0.0/24       65520-65520-65001  Remote Hub
10.2.0.0/16        65520-65520-65010  Remote Hub
10.11.0.0/16       65520-65520        Remote Hub
10.4.0.0/16                           Virtual Network Connection

vHUB: VwanS4-vhub1-hub
Effective route table: defaultRouteTable
AddressPrefixes    AsPath             NextHopType
-----------------  -----------------  --------------------------
10.2.0.0/16        65010              HubBgpConnection
10.11.0.0/16                          Virtual Network Connection
10.1.0.0/16                           Virtual Network Connection
10.5.0.0/16        65520-65520-65021  Remote Hub
10.30.0.0/24       65520-65520-65003  Remote Hub
10.22.0.0/16       65520-65520-65021  Remote Hub
10.4.0.0/16        65520-65520        Remote Hub
10.10.0.0/24       65001              VPN_S2S_Gateway
```

### 6. Onprem Routes

Let's login to the onprem router `VwanS4-branch1-nva` and observe its dynamic routes.

1. Login to virtual machine `VwanS4-branch1-nva` via the serial console.
2. Enter username and password
   - username = **azureuser**
   - password = **Password123**
3. Enter the Cisco enable mode
```sh
enable
```
1. Display the routing table by typing `show ip route` and pressing the space bar to show the complete output.
```sh
show ip route
```

Sample output
```sh
VwanS4-branch1-nva-vm#show ip route
[Truncated]
...
Gateway of last resort is 10.10.1.1 to network 0.0.0.0

S*    0.0.0.0/0 [1/0] via 10.10.1.1
      10.0.0.0/8 is variably subnetted, 16 subnets, 4 masks
B        10.1.0.0/16 [20/0] via 192.168.11.12, 02:54:04
B        10.2.0.0/16 [20/0] via 192.168.11.12, 02:54:04
B        10.4.0.0/16 [20/0] via 192.168.11.12, 02:54:04
B        10.5.0.0/16 [20/0] via 192.168.11.12, 02:54:04
S        10.10.0.0/24 [1/0] via 10.10.2.1
C        10.10.1.0/24 is directly connected, GigabitEthernet1
L        10.10.1.9/32 is directly connected, GigabitEthernet1
C        10.10.2.0/24 is directly connected, GigabitEthernet2
L        10.10.2.9/32 is directly connected, GigabitEthernet2
C        10.10.10.0/30 is directly connected, Tunnel0
L        10.10.10.1/32 is directly connected, Tunnel0
C        10.10.10.4/30 is directly connected, Tunnel1
L        10.10.10.5/32 is directly connected, Tunnel1
B        10.11.0.0/16 [20/0] via 192.168.11.12, 02:54:04
B        10.22.0.0/16 [20/0] via 192.168.11.12, 02:54:04
B        10.30.0.0/24 [20/0] via 192.168.11.13, 02:54:00
      168.63.0.0/32 is subnetted, 1 subnets
S        168.63.129.16 [254/0] via 10.10.1.1
      169.254.0.0/32 is subnetted, 1 subnets
S        169.254.169.254 [254/0] via 10.10.1.1
      192.168.10.0/32 is subnetted, 1 subnets
C        192.168.10.10 is directly connected, Loopback0
      192.168.11.0/24 is variably subnetted, 3 subnets, 2 masks
B        192.168.11.0/24 [20/0] via 192.168.11.12, 02:54:04
S        192.168.11.12/32 is directly connected, Tunnel1
S        192.168.11.13/32 is directly connected, Tunnel0
```

5. Show BGP information
```sh
VwanS4-branch1-nva-vm#show ip bgp
BGP table version is 10, local router ID is 192.168.10.10
Status codes: s suppressed, d damped, h history, * valid, > best, i - internal,
              r RIB-failure, S Stale, m multipath, b backup-path, f RT-Filter,
              x best-external, a additional-path, c RIB-compressed,
              t secondary path, L long-lived-stale,
Origin codes: i - IGP, e - EGP, ? - incomplete
RPKI validation codes: V valid, I invalid, N Not found

     Network          Next Hop            Metric LocPrf Weight Path
 *>   10.1.0.0/16      192.168.11.12                          0 65515 i
 *                     192.168.11.13                          0 65515 i
 *>   10.2.0.0/16      192.168.11.12            0             0 65515 65010 i
 *                     192.168.11.13            0             0 65515 65010 i
 *>   10.4.0.0/16      192.168.11.12                          0 65515 65520 65520 e
 *                     192.168.11.13                          0 65515 65520 65520 e
 *>   10.5.0.0/16      192.168.11.12                          0 65515 65520 65520 65021 e
 *                     192.168.11.13                          0 65515 65520 65520 65021 e
 *>   10.10.0.0/24     10.10.2.1                0         32768 i
     Network          Next Hop            Metric LocPrf Weight Path
 *>   10.11.0.0/16     192.168.11.12                          0 65515 i
 *                     192.168.11.13                          0 65515 i
 *>   10.22.0.0/16     192.168.11.12                          0 65515 65520 65520 65021 e
 *                     192.168.11.13                          0 65515 65520 65520 65021 e
 *    10.30.0.0/24     192.168.11.12                          0 65515 65520 65520 65003 e
 *>                    192.168.11.13                          0 65515 65520 65520 65003 e
 *>   192.168.11.0     192.168.11.12                          0 65515 i
 *                     192.168.11.13                          0 65515 i
```

## Cleanup

1. Navigate to the lab directory
```sh
cd azure-network-terraform/2-virtual-wan/4-virtual-wan-dual-hub-mixed
```

Delete the resource group to remove all resources installed.\
Run the following Azure CLI command:

```sh
az group delete -g VwanS4RG --no-wait
```
