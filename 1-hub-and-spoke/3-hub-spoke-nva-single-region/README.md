# Hub and Spoke - Dual Region <!-- omit from toc -->
## Lab: Hs13 <!-- omit from toc -->

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

This terraform code deploys a single-region standard Virtual Network (Vnet) hub and spoke topology using Virtual Network Appliances (NVA) in the hub.

![Hub and Spoke (Single region)](../../images/scenarios/1-3-hub-spoke-nva-single-region.png)

`Hub1` has an Azure Route Server (ARS) with BGP session to a Network Virtual Appliance (NVA) using a Cisco-CSR-100V router. The direct spokes `Spoke1` and `Spoke2` have Vnet peering to `Hub1`. An isolated `Spoke3` does not have Vnet peering to the `Hub1``, but is reachable from the hub via Private Link Service.

`Branch1` is the on-premises networks which is simulated using Vnet. A Multi-NIC Cisco-CSR-1000V NVA appliance connects to the Vnet hub using IPsec VPN connections with dynamic (BGP) routing.


## Prerequisites

Ensure you meet all requirements in the [prerequisites](../../prerequisites/) before proceeding.

## Deploy the Lab

1. Clone the Git Repository for the Labs
```sh
git clone https://github.com/kaysalawu/azure-network-terraform.git
```

2. Navigate to the lab directory
```sh
cd azure-network-terraform/1-hub-and-spoke/3-hub-spoke-nva-single-region
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

Login to virtual machine `Hs13-spoke1-vm` via the serial console.
- username = **azureuser**
- password = **Password123**

![Hs13-spoke1-vm](../../images/demos/hs13-spoke1-vm.png)

Run the following tests from inside the serial console session.

### 1. Ping IP

This script pings the IP addresses of some test virtual machines and reports reachability and round trip time.

Run the IP ping test
```sh
ping-ip
```
Sample output
```sh
azureuser@Hs13-spoke1-vm:~$ ping-ip

 ping ip ...

branch1 - 10.10.0.5 -OK 14.111 ms
hub1    - 10.11.0.5 -OK 2.538 ms
spoke1  - 10.1.0.5 -OK 0.043 ms
spoke2  - 10.2.0.5 -OK 3.009 ms
internet - icanhazip.com -NA
```

### 2. Ping DNS

This script pings the DNS name of some test virtual machines and reports reachability and round trip time.

Run the DNS ping test
```sh
ping-dns
```

Sample output
```sh
azureuser@Hs13-spoke1-vm:~$ ping-dns

 ping dns ...

vm.branch1.corp - 10.10.0.5 -OK 7.100 ms
vm.hub1.az.corp - 10.11.0.5 -OK 2.085 ms
vm.spoke1.az.corp - 10.1.0.5 -OK 0.040 ms
vm.spoke2.az.corp - 10.2.0.5 -OK 4.382 ms
icanhazip.com - 104.18.115.97 -NA
```

### 3. Curl DNS

This script uses curl to check reachability of web server (python Flask) on the test virtual machines. It reports HTTP response message, round trip time and IP address.

Run the DNS curl test
```sh
curl-dns
```

Sample output
```sh
azureuser@Hs13-spoke1-vm:~$ curl-dns

 curl dns ...

200 (0.057189s) - 10.10.0.5 - vm.branch1.corp
200 (0.027151s) - 10.11.0.5 - vm.hub1.az.corp
200 (0.023730s) - 10.11.4.4 - spoke3.p.hub1.az.corp
200 (0.017258s) - 10.1.0.5 - vm.spoke1.az.corp
[ 4471.136340] cloud-init[1527]: 10.1.0.5 - - [17/Sep/2023 14:34:19] "GET / HTTP/1.1" 200 -
200 (0.025640s) - 10.2.0.5 - vm.spoke2.az.corp
000 (2.000986s) -  - vm.spoke3.az.corp
200 (0.017255s) - 104.18.114.97 - icanhazip.com
```
We can see that spoke3 `vm.spoke3.az.corp` returns a **000** HTTP response code. This is expected since there is no Vnet peering to `Spoke3` from `Hub1`. But `Spoke3` web application is reachable via Private Link Service private endpoint `spoke3.p.hub1.az.corp`. The same explanation applies to `Spoke6` virtual machine `vm.spoke6.az.corp`

### 4. Private Link Service

Test access to `Spoke3` application using the private endpoint in `Hub1`.
```sh
curl spoke3.p.hub1.az.corp
```

Sample output
```sh
azureuser@Hs13-spoke1-vm:~$ curl spoke3.p.hub1.az.corp
{
  "headers": {
    "Accept": "*/*",
    "Host": "spoke3.p.hub1.az.corp",
    "User-Agent": "curl/7.68.0"
  },
  "hostname": "Hs13-spoke3-vm",
  "local-ip": "10.3.0.5",
  "remote-ip": "10.3.3.4"
}
```

The `Hostname` and `Local-IP` fields belong to the servers running the web application - in this case `Spoke3` virtual machine. The `Remote-IP` field (as seen by the web servers) is an IP addresses in the Private Link Service NAT subnet.

### 5. Network Virtual Appliance (NVA)

1. Run a tracepath to `vm.spoke2.az.corp` (10.2.0.5) to observe the traffic flow through the NVA.

```sh
tracepath vm.spoke2.az.corp
```

Sample output
```sh
azureuser@Hs13-spoke1-vm:~$ tracepath vm.spoke2.az.corp
 1?: [LOCALHOST]                      pmtu 1500
 1:  10.11.1.9                                            41.160ms
 1:  10.11.1.9                                             1.423ms
 2:  10.2.0.5                                              4.598ms reached
     Resume: pmtu 1500 hops 2 back 2
```

We can observe the traffic flow from `Spoke1` to `Spoke2` goes through the NVA in `Hub1` (IP address 10.11.1.9) before reaching the destination `Spoke2` (10.2.0.5).

Repeat steps 1-5 for all other spoke and branch virtual machines.

### 6. Onprem Routes

Let's login to the onprem router `Hs13-branch1-nva` and observe its dynamic routes.

1. Login to virtual machine `Hs13-branch1-nva` via the serial console.
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
Hs13-branch1-nva-vm#show ip route
...
[Truncated for brevity]
...
Gateway of last resort is 10.10.1.1 to network 0.0.0.0

S*    0.0.0.0/0 [1/0] via 10.10.1.1
      10.0.0.0/8 is variably subnetted, 14 subnets, 4 masks
B        10.1.0.0/16 [20/0] via 10.11.7.4, 00:37:33
B        10.2.0.0/16 [20/0] via 10.11.7.4, 00:37:33
S        10.10.0.0/24 [1/0] via 10.10.2.1
C        10.10.1.0/24 is directly connected, GigabitEthernet1
L        10.10.1.9/32 is directly connected, GigabitEthernet1
C        10.10.2.0/24 is directly connected, GigabitEthernet2
L        10.10.2.9/32 is directly connected, GigabitEthernet2
C        10.10.10.0/30 is directly connected, Tunnel0
L        10.10.10.1/32 is directly connected, Tunnel0
C        10.10.10.4/30 is directly connected, Tunnel1
L        10.10.10.5/32 is directly connected, Tunnel1
B        10.11.0.0/16 [20/0] via 10.11.7.4, 00:37:33
S        10.11.7.4/32 is directly connected, Tunnel0
S        10.11.7.5/32 is directly connected, Tunnel1
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
Hs13-branch1-nva-vm#show ip bgp
BGP table version is 5, local router ID is 192.168.10.10
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
 *>   10.10.0.0/24     10.10.2.1                0         32768 i
 *    10.11.0.0/16     10.11.7.5                              0 65515 i
 *>                    10.11.7.4                              0 65515 i
```

## Cleanup

1. Make sure you are in the lab directory
```sh
cd azure-network-terraform/1-hub-and-spoke/3-hub-spoke-nva-single-region
```

2. Delete the resource group to remove all resources installed.\
Run the following Azure CLI command:

```sh
az group delete -g Hs13RG --no-wait
```
