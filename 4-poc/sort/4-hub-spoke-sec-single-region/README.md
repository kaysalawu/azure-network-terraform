# Hub and Spoke - Single Region <!-- omit from toc -->

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

This terraform code deploys a hub and spoke topology playground to observe dynamic routing with Azure Route Server (ARS) and a Network Virtual Appiance (NVA).

`Hub1` ARS with BGP session to a Network Virtual Appliance (NVA) using a Cisco-CSR-100V router. The direct spokes `Spoke1` and `Spoke2` have VNET peering to `Hub1`. An isolated `Spoke3` does not have VNET peering to the hub, but is reachable from `Hub1` via Private Link Service.

`Branch1` is the on-premises network which is simulated in a VNET using a multi-NIC Cisco-CSR-100V NVA appliance.

![Hub and Spoke Secure (Single region)](../../images/scenarios/1-3-hub-spoke-sec-single-region.png)

## Prerequisites

Ensure you meet all requirements in the [prerequisites](../../prerequisites/) before proceeding.

## Deploy the Lab

1. Clone the Git Repository for the Labs
```sh
git clone https://github.com/kaysalawu/azure-network-terraform.git
```

2. Navigate to the lab directory
```sh
cd azure-network-terraform/1-hub-and-spoke/1-hub-spoke-single-region
```

3. Run the following terraform commands and type **yes** at the prompt:
```hcl
terraform init
terraform plan
terraform apply
```

## Troubleshooting

See the [troubleshooting](../../troubleshooting/) section for tips on how to resolve common issues that may occur during the deployment of the lab.

## Testing

Each virtual machine is pre-configured with a shell [script](../../scripts/server.sh) to run various types of tests. Serial console access has been configured for all virtual mchines. You can [access the serial console](https://learn.microsoft.com/en-us/troubleshoot/azure/virtual-machines/serial-console-overview#access-serial-console-for-virtual-machines-via-azure-portal) of a virtual machine from the Azure portal.

Login to virtual machine `HubSpokeS1-spoke1-vm` via the serial console.
- username = **azureuser**
- password = **Password123**

![HubSpokeS1-spoke1-vm](../../images/demos/hubspokes1-spoke1-vm.png)

Run the following tests from inside the serial console session.

### 1. Ping IP

This script pings the IP addresses of some test virtual machines and reports reachability and round trip time.

Run the IP ping test
```sh
ping-ip
```
Sample output
```sh
azureuser@HubSpokeS1-spoke2-vm:~$ ping-ip

 ping ip ...

branch1 - 10.10.0.5 -OK 9.087 ms
hub1    - 10.11.0.5 -OK 1.878 ms
spoke1  - 10.1.0.5 -OK 5.353 ms
spoke2  - 10.2.0.5 -OK 0.035 ms
```

### 2. Ping DNS

This script pings the DNS name of some test virtual machines and reports reachability and round trip time.

Run the DNS ping test
```sh
ping-dns
```

Sample output
```sh
azureuser@HubSpokeS1-spoke2-vm:~$ ping-dns

 ping dns ...

vm.branch1.corp - 10.10.0.5 -OK 5.539 ms
vm.hub1.az.corp - 10.11.0.5 -OK 1.782 ms
vm.spoke1.az.corp - 10.1.0.5 -OK 5.107 ms
vm.spoke2.az.corp - 10.2.0.5 -OK 0.032 ms
```

### 3. Curl DNS

This script uses curl to check reachability of web server (python Flask) on the test virtual machines. It reports HTTP response message, round trip time and IP address.

Run the DNS curl test
```sh
curl-dns
```

Sample output
```sh
azureuser@HubSpokeS1-spoke2-vm:~$ curl-dns

 curl dns ...

200 (0.044847s) - 10.10.0.5 - vm.branch1.corp
200 (0.019998s) - 10.11.0.5 - vm.hub1.az.corp
200 (0.024760s) - 10.11.4.4 - spoke3.p.hub1.az.corp
200 (0.041191s) - 10.1.0.5 - vm.spoke1.az.corp
[ 3627.028144] cloud-init[1511]: 10.2.0.5 - - [21/Jan/2023 19:02:00] "GET / HTTP/1.1" 200 -
200 (0.015262s) - 10.2.0.5 - vm.spoke2.az.corp
000 (2.001251s) -  - vm.spoke3.az.corp
```
We can see that spoke3 (vm.spoke3.az.corp) returns a **000** HTTP response code. This is expected since there is no Vnet peering to `Spoke3` from `Hub1`. But `Spoke3` web application is reachable via Private Link Service private endpoint (spoke3.p.hub1.az.corp).

### 4. Private Link Service

Test access to `Spoke3` application using the private endpoint in `Hub1`.
```sh
curl spoke3.p.hub1.az.corp
```

Sample output
```sh
azureuser@HubSpokeS1-spoke2-vm:~$ curl spoke3.p.hub1.az.corp
{
  "headers": {
    "Accept": "*/*",
    "Host": "spoke3.p.hub1.az.corp",
    "User-Agent": "curl/7.68.0"
  },
  "hostname": "HubSpokeS1-spoke3-vm",
  "local-ip": "10.3.0.5",
  "remote-ip": "10.3.3.4"
}
```
The `Hostname` and `Local-IP` field belong to the server running the web application - in this case `Spoke3` virtual machine. The `Remote-IP` field (as seen by the web server) is the IP address in the Private Link Service NAT subnets.

Repeat steps 1-4 for all other virtual machines.

### 5. Onprem Routes

Let's login to the onprem router `HubSpokeS1-branch1-nva` and observe its dynamic routes.

1. Login to virtual machine `HubSpokeS1-branch1-nva` via the serial console.
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
HubSpokeS1-branch1-nva-vm#show ip route
[Truncated]
...
Gateway of last resort is 10.10.1.1 to network 0.0.0.0

S*    0.0.0.0/0 [1/0] via 10.10.1.1
      10.0.0.0/8 is variably subnetted, 14 subnets, 4 masks
B        10.1.0.0/16 [20/0] via 10.11.7.4, 00:26:32
B        10.2.0.0/16 [20/0] via 10.11.7.4, 00:26:32
S        10.10.0.0/24 [1/0] via 10.10.2.1
C        10.10.1.0/24 is directly connected, GigabitEthernet1
L        10.10.1.9/32 is directly connected, GigabitEthernet1
C        10.10.2.0/24 is directly connected, GigabitEthernet2
L        10.10.2.9/32 is directly connected, GigabitEthernet2
C        10.10.10.0/30 is directly connected, Tunnel0
L        10.10.10.1/32 is directly connected, Tunnel0
C        10.10.10.4/30 is directly connected, Tunnel1
L        10.10.10.5/32 is directly connected, Tunnel1
B        10.11.0.0/16 [20/0] via 10.11.7.4, 00:26:32
S        10.11.7.4/32 is directly connected, Tunnel1
S        10.11.7.5/32 is directly connected, Tunnel0
      168.63.0.0/32 is subnetted, 1 subnets
S        168.63.129.16 [254/0] via 10.10.1.1
      169.254.0.0/32 is subnetted, 1 subnets
S        169.254.169.254 [254/0] via 10.10.1.1
      192.168.10.0/32 is subnetted, 1 subnets
C        192.168.10.10 is directly connected, Loopback0
```

5. Show BGP information
```sh
HubSpokeS1-branch1-nva-vm#show ip bgp
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

1. Navigate to the lab directory
```sh
cd azure-network-terraform/1-hub-and-spoke/1-hub-spoke-single-region
```

2. Delete the resource group to remove all resources installed.\
Run the following Azure CLI command:

```sh
az group delete -g HubSpokeS1RG --no-wait
```
