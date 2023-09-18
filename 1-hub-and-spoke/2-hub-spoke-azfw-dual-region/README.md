# Secured Hub and Spoke - Dual Region <!-- omit from toc -->
## Lab: Hs12 <!-- omit from toc -->

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
  - [5. Azure Firewall](#5-azure-firewall)
  - [6. Onprem Routes](#6-onprem-routes)
- [Cleanup](#cleanup)

## Overview

This terraform code deploys a multi-region Secured Virtual Network (Vnet) hub and spoke topology using Azure firewall and User-Defined Routes (UDR) to direct traffic to the firewall.

![Secured Hub and Spoke (Dual region)](../../images/scenarios/1-2-hub-spoke-azfw-dual-region.png)

`Hub1` has an Azure firewall used for inspection of traffic between branch and spokes. User-Defined Routes (UDR) are used to influence the Vnet data plane to route traffic from the branch and spokes via the firewall. An isolated spoke (`Spoke3`) does not have Vnet peering to the hub (`Hub1`), but is reachable from the hub via Private Link Service.

`Hub2` has an Azure firewall used for inspection of traffic between branch and spokes. UDRs are used to influence the Vnet data plane to route traffic from the branch and spokes via the firewall. An isolated spoke (`Spoke6`) does not have Vnet peering to the hub (`Hub2`), but is reachable from the hub via Private Link Service.

The hubs are connected together via Vnet peering to allow spoke-to-spoke network reachability.

`Branch1` and `Branch3` are on-premises networks which are simulated using Vnets. Multi-NIC Cisco-CSR-1000V NVA appliances connect to the Vnet hubs using IPsec VPN connections with dynamic (BGP) routing.

> **_NOTE:_** In this lab, the branches are dual-homed to both hubs. You could also have a single branch connected to a single hub, but with some additional routing configuration.

## Prerequisites

Ensure you meet all requirements in the [prerequisites](../../prerequisites/) before proceeding.

## Deploy the Lab

1. Clone the Git Repository for the Labs
```sh
git clone https://github.com/kaysalawu/azure-network-terraform.git
```

2. Navigate to the lab directory
```sh
cd azure-network-terraform/1-hub-and-spoke/2-hub-spoke-azfw-dual-region
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

Login to virtual machine `Hs12-spoke1-vm` via the serial console.
- username = **azureuser**
- password = **Password123**

![Hs12-spoke1-vm](../../images/demos/hs12-spoke1-vm.png)

Run the following tests from inside the serial console.

### 1. Ping IP

This script pings the IP addresses of some test virtual machines and reports reachability and round trip time.

Run the IP ping test
```sh
ping-ip
```
Sample output
```sh
azureuser@Hs12-spoke1-vm:~$ ping-ip

 ping ip ...

branch1 - 10.10.0.5 -OK 7.298 ms
hub1    - 10.11.0.5 -OK 4.286 ms
spoke1  - 10.1.0.5 -OK 0.047 ms
spoke2  - 10.2.0.5 -OK 3.138 ms
branch3 - 10.30.0.5 -OK 20.547 ms
hub2    - 10.22.0.5 -OK 20.366 ms
spoke4  - 10.4.0.5 -OK 20.381 ms
spoke5  - 10.5.0.5 -OK 22.304 ms
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
azureuser@Hs12-spoke1-vm:~$ ping-dns

 ping dns ...

vm.branch1.corp - 10.10.0.5 -OK 7.314 ms
vm.hub1.az.corp - 10.11.0.5 -OK 4.418 ms
vm.spoke1.az.corp - 10.1.0.5 -OK 0.034 ms
vm.spoke2.az.corp - 10.2.0.5 -OK 3.530 ms
vm.branch3.corp - 10.30.0.5 -OK 20.758 ms
vm.hub2.az.corp - 10.22.0.5 -OK 20.676 ms
vm.spoke4.az.corp - 10.4.0.5 -OK 19.971 ms
vm.spoke5.az.corp - 10.5.0.5 -OK 20.552 ms
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
azureuser@Hs12-spoke1-vm:~$ curl-dns

 curl dns ...

200 (0.052560s) - 10.10.0.5 - vm.branch1.corp
200 (0.033386s) - 10.11.0.5 - vm.hub1.az.corp
200 (0.024690s) - 10.11.4.4 - pep.hub1.az.corp
[23017.099663] cloud-init[1588]: 10.1.0.5 - - [17/Sep/2023 19:46:43] "GET / HTTP/1.1" 200 -
200 (0.017805s) - 10.1.0.5 - vm.spoke1.az.corp
200 (0.029626s) - 10.2.0.5 - vm.spoke2.az.corp
000 (2.001577s) -  - vm.spoke3.az.corp
000 (2.001826s) - 10.30.0.5 - vm.branch3.corp
200 (0.073012s) - 10.22.0.5 - vm.hub2.az.corp
200 (0.067024s) - 10.22.4.4 - pep.hub2.az.corp
200 (0.068769s) - 10.4.0.5 - vm.spoke4.az.corp
200 (0.074421s) - 10.5.0.5 - vm.spoke5.az.corp
000 (2.001662s) -  - vm.spoke6.az.corp
200 (0.041685s) - 104.18.115.97 - icanhazip.com
```
We can see that spoke3 `vm.spoke3.az.corp` returns a **000** HTTP response code. This is expected as there is no Vnet peering to `Spoke3` from `Hub1`. But `Spoke3` web application is reachable via Private Link Service private endpoint `pep.hub1.az.corp`. The same explanation applies to `Spoke6` virtual machine `vm.spoke6.az.corp`

### 4. Private Link Service

Test access to `Spoke3` application using the private endpoint in `Hub1`.
```sh
curl pep.hub1.az.corp
```

Sample output
```sh
azureuser@Hs12-spoke1-vm:~$ curl pep.hub1.az.corp
{
  "headers": {
    "Accept": "*/*",
    "Host": "pep.hub1.az.corp",
    "User-Agent": "curl/7.68.0"
  },
  "hostname": "Hs12-spoke3-vm",
  "local-ip": "10.3.0.5",
  "remote-ip": "10.3.3.4"
}
```
Test access to `Spoke6` application using the private endpoint in `Hub2`.
```sh
curl pep.hub2.az.corp
```

Sample output
```sh
azureuser@Hs12-spoke1-vm:~$ curl pep.hub2.az.corp
{
  "headers": {
    "Accept": "*/*",
    "Host": "pep.hub2.az.corp",
    "User-Agent": "curl/7.68.0"
  },
  "hostname": "Hs12-spoke6-vm",
  "local-ip": "10.6.0.5",
  "remote-ip": "10.6.3.4"
}
```

The `hostname` and `local-ip` fields belong to the servers running the web application - in this case `Spoke3` and `Spoke6`virtual machines. The `remote-ip` fields (as seen by the web servers) are the respective IP addresses in the Private Link Service NAT subnets.

### 5. Azure Firewall

Check the Azure Firewall logs to observe the traffic flow.
- Select the Azure Firewall resource `Hs12-azfw-hub1` in the Azure portal.
- Click on **Logs** in the left navigation pane.
- Click **Run** in the *Network rule log data* log category.

![Hs12-azfw-hub1-network-rule-log](../../images/demos/hs12-hub1-net-rule-log.png)
- On the *TargetIP* column deselect all IP addresses except spoke2 (10.2.0.5)

![Hs12-azfw-hub1-network-rule-log-data](../../images/demos/hs12-hub1-net-rule-log-detail.png)

Observe how traffic from spoke1 (10.1.0.5) to spoke2 flows via the firewall as expected.

Repeat steps 1-5 for all other spoke and branch virtual machines.

### 6. Onprem Routes

Let's login to the onprem router `Hs12-branch1-nva` and observe its dynamic routes.

1. Login to virtual machine `Hs12-branch1-nva` via the serial console.
2. Enter username and password
   - username = **azureuser**
   - password = **Password123**
3. Enter the Cisco enable mode
```sh
enable
```
4. Display the routing table
```sh
show ip route
```

Sample output
```sh
Hs12-branch1-nva-vm#show ip route
...
[Truncated for brevity]
...
Gateway of last resort is 10.10.1.1 to network 0.0.0.0

S*    0.0.0.0/0 [1/0] via 10.10.1.1
      10.0.0.0/8 is variably subnetted, 24 subnets, 4 masks
B        10.1.0.0/16 [20/0] via 10.11.7.4, 03:33:14
B        10.2.0.0/16 [20/0] via 10.11.7.4, 03:33:14
B        10.4.0.0/16 [20/0] via 10.22.7.4, 03:33:14
B        10.5.0.0/16 [20/0] via 10.22.7.4, 03:33:14
S        10.10.0.0/24 [1/0] via 10.10.2.1
C        10.10.1.0/24 is directly connected, GigabitEthernet1
L        10.10.1.9/32 is directly connected, GigabitEthernet1
C        10.10.2.0/24 is directly connected, GigabitEthernet2
L        10.10.2.9/32 is directly connected, GigabitEthernet2
C        10.10.10.0/30 is directly connected, Tunnel0
L        10.10.10.1/32 is directly connected, Tunnel0
C        10.10.10.4/30 is directly connected, Tunnel1
L        10.10.10.5/32 is directly connected, Tunnel1
C        10.10.10.8/30 is directly connected, Tunnel2
L        10.10.10.9/32 is directly connected, Tunnel2
C        10.10.10.12/30 is directly connected, Tunnel3
L        10.10.10.13/32 is directly connected, Tunnel3
B        10.11.0.0/16 [20/0] via 10.11.7.4, 03:33:14
S        10.11.7.4/32 is directly connected, Tunnel1
S        10.11.7.5/32 is directly connected, Tunnel0
B        10.22.0.0/16 [20/0] via 10.22.7.4, 03:33:14
S        10.22.7.4/32 is directly connected, Tunnel3
S        10.22.7.5/32 is directly connected, Tunnel2
B        10.30.0.0/24 [20/0] via 10.22.7.4, 03:32:55
      168.63.0.0/32 is subnetted, 1 subnets
S        168.63.129.16 [254/0] via 10.10.1.1
      169.254.0.0/32 is subnetted, 1 subnets
S        169.254.169.254 [254/0] via 10.10.1.1
      192.168.10.0/32 is subnetted, 1 subnets
C        192.168.10.10 is directly connected, Loopback0
```

5. Display BGP information
```sh
show ip bgp
```

Sample output
```sh
Hs12-branch1-nva-vm#show ip bgp
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
 *    10.4.0.0/16      10.22.7.5                              0 65515 i
 *>                    10.22.7.4                              0 65515 i
 *    10.5.0.0/16      10.22.7.5                              0 65515 i
 *>                    10.22.7.4                              0 65515 i
 *>   10.10.0.0/24     10.10.2.1                0         32768 i
 *>   10.11.0.0/16     10.11.7.4                              0 65515 i
 *                     10.11.7.5                              0 65515 i
 *    10.22.0.0/16     10.22.7.5                              0 65515 i
 *>                    10.22.7.4                              0 65515 i
     Network          Next Hop            Metric LocPrf Weight Path
 *    10.30.0.0/24     10.11.7.4                              0 65515 65003 i
 *                     10.22.7.5                              0 65515 65003 i
 *                     10.11.7.5                              0 65515 65003 i
 *>                    10.22.7.4                              0 65515 65003 i
```

## Cleanup

1. Make sure you are in the lab directory
```sh
cd azure-network-terraform/1-hub-and-spoke/2-hub-spoke-azfw-dual-region
```

2. Delete the resource group to remove all resources installed.\
Run the following Azure CLI command:

```sh
az group delete -g Hs12RG --no-wait
```
