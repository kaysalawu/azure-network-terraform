# Secured Hub and Spoke - Single Region <!-- omit from toc -->
## Lab: Hs11 <!-- omit from toc -->

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

This terraform code deploys a single-region Secured Virtual Network (Vnet) hub and spoke topology using Azure firewall and User-Defined Routes (UDR) to direct traffic to the firewall.

![Secured Hub and Spoke (Single region)](../../images/scenarios/1-1-hub-spoke-azfw-single-region.png)

`Hub1` has an Azure firewall used for inspection of traffic between branch and spokes. User-Defined Routes (UDR) are used to influence the Vnet data plane to route traffic from the branch and spokes via the firewall. An isolated spoke (`Spoke3`) does not have Vnet peering to the hub (`Hub1`), but is reachable from the hub via Private Link Service.

`Branch1` is the on-premises network which is simulated using Vnet. A Multi-NIC Cisco-CSR-1000V NVA appliance connects to the Vnet hub using IPsec VPN connections with dynamic (BGP) routing.



## Prerequisites

Ensure you meet all requirements in the [prerequisites](../../prerequisites/) before proceeding.

## Deploy the Lab

1. Clone the Git Repository for the Labs
```sh
git clone https://github.com/kaysalawu/azure-network-terraform.git
```

2. Navigate to the lab directory
```sh
cd azure-network-terraform/1-hub-and-spoke/1-hub-spoke-azfw-single-region
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

Login to virtual machine `Hs11-spoke1-vm` via the serial console.
- username = **azureuser**
- password = **Password123**

![Hs11-spoke1-vm](../../images/demos/hs11-spoke1-vm.png)

Run the following tests from inside the serial console session.

### 1. Ping IP

This script pings the IP addresses of some test virtual machines and reports reachability and round trip time.

Run the IP ping test
```sh
ping-ip
```

Sample output
```sh
azureuser@Hs11-spoke1-vm:~$ ping-ip

 ping ip ...

branch1 - 10.10.0.5 -OK 8.164 ms
hub1    - 10.11.0.5 -OK 3.577 ms
spoke1  - 10.1.0.5 -OK 0.042 ms
spoke2  - 10.2.0.5 -OK 4.564 ms
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
azureuser@Hs11-spoke1-vm:~$ ping-dns

 ping dns ...

vm.branch1.corp - 10.10.0.5 -OK 7.485 ms
vm.hub1.az.corp - 10.11.0.5 -OK 2.550 ms
vm.spoke1.az.corp - 10.1.0.5 -OK 0.036 ms
vm.spoke2.az.corp - 10.2.0.5 -OK 3.851 ms
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
azureuser@Hs11-spoke1-vm:~$ curl-dns

 curl dns ...

200 (0.051782s) - 10.10.0.5 - vm.branch1.corp
200 (0.028942s) - 10.11.0.5 - vm.hub1.az.corp
200 (0.026053s) - 10.11.4.4 - spoke3.p.hub1.az.corp
200 (0.018581s) - 10.1.0.5 - vm.spoke1.az.corp
[15899.972313] cloud-init[1570]: 10.1.0.5 - - [17/Sep/2023 17:48:07] "GET / HTTP/1.1" 200 -
200 (0.035168s) - 10.2.0.5 - vm.spoke2.az.corp
000 (2.001681s) -  - vm.spoke3.az.corp
200 (0.016512s) - 104.18.114.97 - icanhazip.com
```
We can see that spoke3 `vm.spoke3.az.corp` returns a **000** HTTP response code. This is expected since there is no Vnet peering to `Spoke3` from `Hub1`. But `Spoke3` web application is reachable via Private Link Service private endpoint `spoke3.p.hub1.az.corp`.

### 4. Private Link Service

Test access to `Spoke3` application using the private endpoint in `Hub1`.
```sh
curl spoke3.p.hub1.az.corp
```

Sample output
```sh
azureuser@Hs11-spoke1-vm:~$ curl spoke3.p.hub1.az.corp
{
  "headers": {
    "Accept": "*/*",
    "Host": "spoke3.p.hub1.az.corp",
    "User-Agent": "curl/7.68.0"
  },
  "hostname": "Hs11-spoke3-vm",
  "local-ip": "10.3.0.5",
  "remote-ip": "10.3.3.4"
}
```
The `Hostname` and `Local-IP` fields belong to the servers running the web application - in this case `Spoke3` virtual machine. The `Remote-IP` field (as seen by the web servers) is an IP addresses in the Private Link Service NAT subnet.

### 5. Azure Firewall

Check the Azure Firewall logs to observe the traffic flow.
- Select the Azure Firewall resource `Hs11-azfw-hub1` in the Azure portal.
- Click on **Logs** in the left navigation pane.
- Click **Run** in the *Network rule log data* log category.

![Hs11-azfw-hub1-network-rule-log](../../images/demos/hs11-hub1-net-rule-log.png)
- On the *TargetIP* column deselect all IP addresses except spoke2 (10.2.0.5)

![Hs11-azfw-hub1-network-rule-log-data](../../images/demos/hs11-hub1-net-rule-log-detail.png)

Observe how traffic from spoke1 (10.1.0.5) to spoke2 flows via the firewall as expected.

Repeat steps 1-5 for all other spoke and branch virtual machines.

### 6. Onprem Routes

Let's login to the onprem router `Hs11-branch1-nva` and observe its dynamic routes.

1. Login to virtual machine `Hs11-branch1-nva` via the serial console.
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
...
[Truncated for brevity]
...
Gateway of last resort is 10.10.1.1 to network 0.0.0.0

S*    0.0.0.0/0 [1/0] via 10.10.1.1
      10.0.0.0/8 is variably subnetted, 14 subnets, 4 masks
B        10.1.0.0/16 [20/0] via 10.11.7.4, 01:13:55
B        10.2.0.0/16 [20/0] via 10.11.7.4, 01:13:55
S        10.10.0.0/24 [1/0] via 10.10.2.1
C        10.10.1.0/24 is directly connected, GigabitEthernet1
L        10.10.1.9/32 is directly connected, GigabitEthernet1
C        10.10.2.0/24 is directly connected, GigabitEthernet2
L        10.10.2.9/32 is directly connected, GigabitEthernet2
C        10.10.10.0/30 is directly connected, Tunnel0
L        10.10.10.1/32 is directly connected, Tunnel0
C        10.10.10.4/30 is directly connected, Tunnel1
L        10.10.10.5/32 is directly connected, Tunnel1
B        10.11.0.0/16 [20/0] via 10.11.7.4, 01:13:55
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
Hs11-branch1-nva-vm#show ip bgp
BGP table version is 5, local router ID is 192.168.10.10
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
 *>   10.10.0.0/24     10.10.2.1                0         32768 i
 *>   10.11.0.0/16     10.11.7.4                              0 65515 i
 *                     10.11.7.5                              0 65515 i
```

## Cleanup

1. Make sure you are in the lab directory
```sh
cd azure-network-terraform/1-hub-and-spoke/1-hub-spoke-azfw-single-region
```

2. Delete the resource group to remove all resources installed.\
Run the following Azure CLI command:

```sh
az group delete -g Hs11RG --no-wait
```

# TODO:
# 1. Use actual vm names for modules
