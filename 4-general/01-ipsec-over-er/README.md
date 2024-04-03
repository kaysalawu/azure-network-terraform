# Lab01 - IPsec over ExpressRoute <!-- omit from toc -->

Contents

- [Overview](#overview)
- [Prerequisites](#prerequisites)
- [Deploy the Lab](#deploy-the-lab)
- [Results](#results)
  - [1. Spoke1](#1-spoke1)
  - [2. Branch2 VM](#2-branch2-vm)
  - [3. Branch2](#3-branch2)
  - [4. Hub1](#4-hub1)
  - [6. Vnet Gateways](#6-vnet-gateways)
  - [6. Express Route Circuits](#6-express-route-circuits)
- [Troubleshooting](#troubleshooting)
- [Cleanup](#cleanup)

## Overview

This lab deploys a single region hub and spoke topology to demonstrate IPsec over ExpressRoute to an on-premises branch location. Megaport is used as the ExpressRoute provider.

Related articles and documentation:
* [Lab - Virtual WAN Scenario: IPsec VPN over ER](https://github.com/kaysalawu/azure-virtualwan/tree/main/vpn-over-er)
* [Configure a Site-to-Site VPN connection over ExpressRoute private peering](https://learn.microsoft.com/en-us/azure/vpn-gateway/site-to-site-vpn-private-peering)

  <img src="./images/architecture.png" alt="er-ecmp-topology" width="800">

## Prerequisites

Ensure you meet all requirements in the [prerequisites](../../prerequisites/README.md) before proceeding.

> **NOTE**: You need to have an active [megaport](https://www.megaport.com/) account. You will need to supply the megaport credentials in order to deploy the lab:
* `megaport_access_key`
* `megaport_secret_key`

## Deploy the Lab

1. Clone the Git Repository for the Labs

   ```sh
   git clone https://github.com/kaysalawu/azure-network-terraform.git
   ```

2. Navigate to the lab directory

   ```sh
   cd azure-network-terraform/4-general/01-ipsec-over-er
   ```

3. Run the following terraform commands and type ***yes*** at the prompt:

   ```sh
   terraform init
   terraform plan
   terraform apply -parallelism=50
   ```

4. Manually configure the secondary express route connection in Megaport portal.

## Results

### 1. Spoke1

All packets from `spoke1Vm` to `branch2Vm` are routed through the NVA in the hub; and then via the VPN gateway where the traffic is encrypted and sent over the ExpressRoute circuit to branch2.

<details>
<summary>Spoke1Vm - Curl DNS</summary>

```sh
azureuser@spoke1Vm:~$ curl-dns

 curl dns ...

200 (0.026233s) - 10.10.0.5 - branch1vm.corp
200 (0.089145s) - 10.20.0.5 - branch2vm.corp
200 (0.019477s) - 10.11.0.5 - hub1vm.eu.az.corp
200 (0.013727s) - 10.11.7.88 - spoke3pls.eu.az.corp
200 (0.008463s) - 10.1.0.5 - spoke1vm.eu.az.corp
200 (0.023157s) - 10.2.0.5 - spoke2vm.eu.az.corp
200 (0.014426s) - 104.16.184.241 - icanhazip.com
200 (0.033923s) - 10.11.7.99 - https://g01spoke3saf19d.blob.core.windows.net/spoke3/spoke3.txt
```

</details>
<p>

<details>
<summary>Spoke1Vm - Tracepath</summary>

```sh
azureuser@spoke1Vm:~$ trace-ip

 trace ip ...


branch1
-------------------------------------
 1?: [LOCALHOST]                      pmtu 1500
 1:  10.11.1.4                                             3.464ms
 1:  10.11.1.4                                             1.007ms
 2:  10.10.10.5                                            3.158ms
 3:  10.10.0.5                                             3.953ms reached
     Resume: pmtu 1500 hops 3 back 3

branch2
-------------------------------------
 1?: [LOCALHOST]                      pmtu 1500
 1:  10.11.1.4                                             1.139ms
 1:  10.11.1.4                                             1.001ms
 2:  10.10.10.9                                           27.916ms
 3:  10.20.0.5                                            28.806ms reached
     Resume: pmtu 1500 hops 3 back 3

hub1
-------------------------------------
 1?: [LOCALHOST]                      pmtu 1500
 1:  10.11.1.4                                             1.258ms
 1:  10.11.1.4                                             0.815ms
 2:  10.11.0.5                                             2.238ms reached
     Resume: pmtu 1500 hops 2 back 2

spoke1
-------------------------------------
 1:  spoke1vm.internal.cloudapp.net                        0.064ms reached
     Resume: pmtu 65535 hops 1 back 1

spoke2
-------------------------------------
 1?: [LOCALHOST]                      pmtu 1500
 1:  10.11.1.4                                             1.437ms
 2:  10.2.0.5                                              3.087ms reached
     Resume: pmtu 1500 hops 2 back 2

internet
-------------------------------------
 1?: [LOCALHOST]                      pmtu 1500
 1:  10.11.1.4                                             1.321ms
 2:  no reply
 3:  no reply
```

</details>
<p>

<details>
<summary>Spoke1Vm - Effective Routes</summary>

```sh
01-ipsec-over-er$ . ../../scripts/_routes_nic.sh G01_IPsecOverER_RG

Resource group: G01_IPsecOverER_RG

Available NICs:
1. G01-branch1-dns-main
2. G01-branch1-nva-trust-nic
3. G01-branch1-nva-untrust-nic
4. G01-branch1-vm-main-nic
5. G01-branch2-dns-main
6. G01-branch2-nva-trust-nic
7. G01-branch2-nva-untrust-nic
8. G01-branch2-vm-main-nic
9. G01-hub1-nva-trust-nic
10. G01-hub1-nva-untrust-nic
11. G01-hub1-spoke3-blob-pep.nic.1d8c0b09-49a3-4122-b25b-7293a752621e
12. G01-hub1-spoke3-pls-pep.nic.968982fc-e561-43bd-89c0-a8a8775bbde9
13. G01-hub1-vm-main-nic
14. G01-spoke1-vm-main-nic
15. G01-spoke2-vm-main-nic
16. G01-spoke3-pls.nic.afac48ba-5169-4de6-947c-43a261e4af84
17. G01-spoke3-vm-main-nic

Select NIC to view effective routes (enter the number)

Selection: 14

Effective routes for G01-spoke1-vm-main-nic

Source    Prefix         State    NextHopType        NextHopIP
--------  -------------  -------  -----------------  -----------
Default   10.1.0.0/20    Active   VnetLocal
Default   10.11.0.0/20   Invalid  VNetPeering
Default   10.11.16.0/20  Invalid  VNetPeering
Default   0.0.0.0/0      Invalid  Internet
User      10.11.0.0/20   Active   VirtualAppliance   10.11.2.99
User      0.0.0.0/0      Active   VirtualAppliance   10.11.2.99
User      10.11.16.0/20  Active   VirtualAppliance   10.11.2.99
Default   10.11.7.99/32  Active   InterfaceEndpoint
Default   10.11.7.88/32  Active   InterfaceEndpoint
```

</details>
<p>

### 2. Branch2 VM

<details>
<summary>Branch2Vm - Curl DNS</summary>

```sh
azureuser@branch2Vm:~$ curl-dns

 curl dns ...

200 (0.076975s) - 10.10.0.5 - branch1vm.corp
200 (0.010942s) - 10.20.0.5 - branch2vm.corp
200 (0.106217s) - 10.11.0.5 - hub1vm.eu.az.corp
200 (0.100717s) - 10.11.7.88 - spoke3pls.eu.az.corp
200 (0.108893s) - 10.1.0.5 - spoke1vm.eu.az.corp
200 (0.103099s) - 10.2.0.5 - spoke2vm.eu.az.corp
200 (0.066517s) - 104.16.184.241 - icanhazip.com
200 (0.119872s) - 10.11.7.99 - https://g01spoke3saf19d.blob.core.windows.net/spoke3/spoke3.txt
```

</details>
<p>

<details>
<summary>Branch2Vm - Tracepath</summary>

```sh
azureuser@branch2Vm:~$ trace-ip

 trace ip ...


branch1
-------------------------------------
 1?: [LOCALHOST]                      pmtu 1500
 1:  10.20.1.9                                             1.148ms
 1:  10.20.1.9                                             2.466ms
 2:  10.20.1.9                                             2.650ms pmtu 1436
 2:  10.10.10.5                                           26.555ms
 3:  10.10.0.5                                            26.768ms reached
     Resume: pmtu 1436 hops 3 back 3

branch2
-------------------------------------
 1:  branch2Vm                                             0.055ms reached
     Resume: pmtu 65535 hops 1 back 1

hub1
-------------------------------------
 1?: [LOCALHOST]                      pmtu 1500
 1:  10.20.1.9                                             1.014ms
 1:  10.20.1.9                                             1.646ms
 2:  10.20.1.9                                             1.186ms pmtu 1436
 2:  10.11.1.4                                            26.242ms
 3:  10.11.0.5                                            26.799ms reached
     Resume: pmtu 1436 hops 3 back 3

spoke1
-------------------------------------
 1?: [LOCALHOST]                      pmtu 1500
 1:  10.20.1.9                                             0.999ms
 1:  10.20.1.9                                             0.910ms
 2:  10.20.1.9                                             1.319ms pmtu 1436
 2:  10.11.1.4                                            25.928ms
 3:  10.1.0.5                                             26.361ms reached
     Resume: pmtu 1436 hops 3 back 3

spoke2
-------------------------------------
 1?: [LOCALHOST]                      pmtu 1500
 1:  10.20.1.9                                             1.310ms
 1:  10.20.1.9                                             2.022ms
 2:  10.20.1.9                                             2.643ms pmtu 1436
 2:  10.11.1.4                                            30.055ms
 3:  10.2.0.5                                             29.106ms reached
     Resume: pmtu 1436 hops 3 back 3

internet
-------------------------------------
 1?: [LOCALHOST]                      pmtu 1500
 1:  no reply
 2:  no reply
```

</details>
<p>

### 3. Branch2

Run `sudo vtysh` to enter the FRR shell.

<details>
<summary>Branch2Nva - IP Interfaces</summary>

```sh
branch2Nva# show interface brief
Interface       Status  VRF             Addresses
---------       ------  ---             ---------
eth0            up      default         10.20.1.9/24
eth1            up      default         10.20.2.9/24
ip_vti0         down    default
lo              up      default         192.168.20.20/32
vti0            up      default         10.10.10.9/32
vti1            up      default         10.10.10.13/32
```

</details>
<p>

<details>
<summary>Branch2Nva - IP routes</summary>

```sh
branch2Nva# show ip route
Codes: K - kernel route, C - connected, S - static, R - RIP,
       O - OSPF, I - IS-IS, B - BGP, E - EIGRP, N - NHRP,
       T - Table, v - VNC, V - VNC-Direct, A - Babel, D - SHARP,
       F - PBR, f - OpenFabric,
       > - selected route, * - FIB route, q - queued route, r - rejected route

S   0.0.0.0/0 [1/0] via 10.20.1.1, eth0, 00:18:42
K>* 0.0.0.0/0 [0/100] via 10.20.1.1, eth0, src 10.20.1.9, 00:18:43
B>* 10.1.0.0/20 [20/0] via 10.11.16.14, vti0, 00:18:41
  *                    via 10.11.16.15, vti1, 00:18:41
B>* 10.2.0.0/20 [20/0] via 10.11.16.14, vti0, 00:18:41
  *                    via 10.11.16.15, vti1, 00:18:41
B>* 10.10.0.0/24 [20/0] via 10.11.16.14, vti0, 00:18:30
  *                     via 10.11.16.15, vti1, 00:18:30
B>* 10.11.0.0/20 [20/0] via 10.11.16.14, vti0, 00:18:41
  *                     via 10.11.16.15, vti1, 00:18:41
B>* 10.11.16.0/20 [20/0] via 10.11.16.14, vti0, 00:18:41
  *                      via 10.11.16.15, vti1, 00:18:41
S>* 10.11.16.4/32 [1/0] via 10.20.1.1, eth0, 00:18:42
S>* 10.11.16.5/32 [1/0] via 10.20.1.1, eth0, 00:18:42
S   10.11.16.14/32 [1/0] is directly connected, vti0, 00:18:42
C>* 10.11.16.14/32 is directly connected, vti0, 00:18:43
S   10.11.16.15/32 [1/0] is directly connected, vti1, 00:18:42
C>* 10.11.16.15/32 is directly connected, vti1, 00:18:43
S>* 10.20.0.0/24 [1/0] via 10.20.1.1, eth0, 00:18:42
C>* 10.20.1.0/24 is directly connected, eth0, 00:18:43
C>* 10.20.2.0/24 is directly connected, eth1, 00:18:43
K>* 168.63.129.16/32 [0/100] via 10.20.1.1, eth0, src 10.20.1.9, 00:18:43
K>* 169.254.169.254/32 [0/100] via 10.20.1.1, eth0, src 10.20.1.9, 00:18:43
C>* 192.168.20.20/32 is directly connected, lo, 00:18:43
```

</details>
<p>

<details>
<summary>Branch2Nva - BGP table detailed</summary>

```sh
branch2Nva# show ip bgp
BGP table version is 9, local router ID is 192.168.20.20, vrf id 0
Default local pref 100, local AS 65002
Status codes:  s suppressed, d damped, h history, * valid, > best, = multipath,
               i internal, r RIB-failure, S Stale, R Removed
Nexthop codes: @NNN nexthop's vrf id, < announce-nh-self
Origin codes:  i - IGP, e - EGP, ? - incomplete

   Network          Next Hop            Metric LocPrf Weight Path
*= 10.1.0.0/20      10.11.16.15                            0 65515 i
*>                  10.11.16.14                            0 65515 i
*= 10.2.0.0/20      10.11.16.15                            0 65515 i
*>                  10.11.16.14                            0 65515 i
*= 10.10.0.0/24     10.11.16.14                            0 65515 65001 i
*>                  10.11.16.15                            0 65515 65001 i
*= 10.11.0.0/20     10.11.16.15                            0 65515 i
*>                  10.11.16.14                            0 65515 i
*= 10.11.16.0/20    10.11.16.15                            0 65515 i
*>                  10.11.16.14                            0 65515 i
*> 10.20.0.0/24     0.0.0.0                  0         32768 i
```

</details>
<p>

<details>
<summary>Branch2Vm - Curl DNS</summary>

```sh
azureuser@branch2Vm:~$ curl-dns

 curl dns ...

200 (0.086913s) - 10.10.0.5 - branch1vm.corp
200 (0.011955s) - 10.20.0.5 - branch2vm.corp
200 (0.125528s) - 10.11.0.5 - hub1vm.eu.az.corp
200 (0.119653s) - 10.11.7.88 - spoke3pls.eu.az.corp
200 (0.102884s) - 10.1.0.5 - spoke1vm.eu.az.corp
200 (0.109936s) - 10.2.0.5 - spoke2vm.eu.az.corp
200 (0.023319s) - 104.16.184.241 - icanhazip.com
200 (0.122121s) - 10.11.7.99 - https://g01spoke3saf19d.blob.core.windows.net/spoke3/spoke3.txt
```

</details>
<p>

<details>
<summary>Branch2Vm - Tracepath</summary>

```sh
azureuser@branch2Vm:~$ trace-ip

 trace ip ...


branch1
-------------------------------------
 1?: [LOCALHOST]                      pmtu 1500
 1:  10.20.1.9                                             1.148ms
 1:  10.20.1.9                                             2.466ms
 2:  10.20.1.9                                             2.650ms pmtu 1436
 2:  10.10.10.5                                           26.555ms
 3:  10.10.0.5                                            26.768ms reached
     Resume: pmtu 1436 hops 3 back 3

branch2
-------------------------------------
 1:  branch2Vm                                             0.055ms reached
     Resume: pmtu 65535 hops 1 back 1

hub1
-------------------------------------
 1?: [LOCALHOST]                      pmtu 1500
 1:  10.20.1.9                                             1.014ms
 1:  10.20.1.9                                             1.646ms
 2:  10.20.1.9                                             1.186ms pmtu 1436
 2:  10.11.1.4                                            26.242ms
 3:  10.11.0.5                                            26.799ms reached
     Resume: pmtu 1436 hops 3 back 3

spoke1
-------------------------------------
 1?: [LOCALHOST]                      pmtu 1500
 1:  10.20.1.9                                             0.999ms
 1:  10.20.1.9                                             0.910ms
 2:  10.20.1.9                                             1.319ms pmtu 1436
 2:  10.11.1.4                                            25.928ms
 3:  10.1.0.5                                             26.361ms reached
     Resume: pmtu 1436 hops 3 back 3

spoke2
-------------------------------------
 1?: [LOCALHOST]                      pmtu 1500
 1:  10.20.1.9                                             1.310ms
 1:  10.20.1.9                                             2.022ms
 2:  10.20.1.9                                             2.643ms pmtu 1436
 2:  10.11.1.4                                            30.055ms
 3:  10.2.0.5                                             29.106ms reached
     Resume: pmtu 1436 hops 3 back 3

internet
-------------------------------------
 1?: [LOCALHOST]                      pmtu 1500
 1:  no reply
 2:  no reply
```

</details>
<p>

### 4. Hub1

<details>
<summary>Hub1Nva Untrust NIC - Effective Routes</summary>

```sh
01-ipsec-over-er$ . ../../scripts/_routes_nic.sh G01_IPsecOverER_RG

Resource group: G01_IPsecOverER_RG

Available NICs:
1. G01-branch1-dns-main
2. G01-branch1-nva-trust-nic
3. G01-branch1-nva-untrust-nic
4. G01-branch1-vm-main-nic
5. G01-branch2-dns-main
6. G01-branch2-nva-trust-nic
7. G01-branch2-nva-untrust-nic
8. G01-branch2-vm-main-nic
9. G01-hub1-nva-trust-nic
10. G01-hub1-nva-untrust-nic
11. G01-hub1-spoke3-blob-pep.nic.1d8c0b09-49a3-4122-b25b-7293a752621e
12. G01-hub1-spoke3-pls-pep.nic.968982fc-e561-43bd-89c0-a8a8775bbde9
13. G01-hub1-vm-main-nic
14. G01-spoke1-vm-main-nic
15. G01-spoke2-vm-main-nic
16. G01-spoke3-pls.nic.afac48ba-5169-4de6-947c-43a261e4af84
17. G01-spoke3-vm-main-nic

Select NIC to view effective routes (enter the number)

Selection: 10

Effective routes for G01-hub1-nva-untrust-nic

Source                 Prefix          State    NextHopType            NextHopIP
---------------------  --------------  -------  ---------------------  ------------
Default                10.11.0.0/20    Active   VnetLocal
Default                10.11.16.0/20   Active   VnetLocal
Default                10.1.0.0/20     Active   VNetPeering
Default                10.2.0.0/20     Active   VNetPeering
VirtualNetworkGateway  172.16.0.12/30  Active   VirtualNetworkGateway  10.20.88.110
VirtualNetworkGateway  172.16.0.12/30  Active   VirtualNetworkGateway  10.20.88.111
VirtualNetworkGateway  10.10.0.0/24    Active   VirtualNetworkGateway  10.11.16.14
VirtualNetworkGateway  10.10.0.0/24    Active   VirtualNetworkGateway  10.11.16.15
VirtualNetworkGateway  172.16.0.0/30   Active   VirtualNetworkGateway  10.20.88.110
VirtualNetworkGateway  172.16.0.0/30   Active   VirtualNetworkGateway  10.20.88.111
VirtualNetworkGateway  10.20.0.0/24    Active   VirtualNetworkGateway  10.11.16.14
VirtualNetworkGateway  10.20.0.0/24    Active   VirtualNetworkGateway  10.11.16.15
VirtualNetworkGateway  10.20.0.0/20    Active   VirtualNetworkGateway  10.20.88.110
VirtualNetworkGateway  10.20.0.0/20    Active   VirtualNetworkGateway  10.20.88.111
VirtualNetworkGateway  172.16.0.4/30   Active   VirtualNetworkGateway  10.20.88.110
VirtualNetworkGateway  172.16.0.4/30   Active   VirtualNetworkGateway  10.20.88.111
VirtualNetworkGateway  10.20.16.0/20   Active   VirtualNetworkGateway  10.20.88.110
VirtualNetworkGateway  10.20.16.0/20   Active   VirtualNetworkGateway  10.20.88.111
VirtualNetworkGateway  172.16.0.8/30   Active   VirtualNetworkGateway  10.20.88.110
VirtualNetworkGateway  172.16.0.8/30   Active   VirtualNetworkGateway  10.20.88.111
Default                0.0.0.0/0       Active   Internet
Default                10.11.7.99/32   Active   InterfaceEndpoint
Default                10.11.7.88/32   Active   InterfaceEndpoint
```

</details>
<p>

### 6. Vnet Gateways

<details>
<summary>Vnet Gateway Route Tables</summary>

```sh
01-ipsec-over-er$ ../../scripts/vnet-gateway/get_route_tables.sh G01_IPsecOverER_RG

Resource group: G01_IPsecOverER_RG

Gateway: G01-branch2-ergw
Route tables:
Network         NextHop     Origin    SourcePeer    AsPath             Weight
--------------  ----------  --------  ------------  -----------------  --------
10.20.0.0/20                Network   10.20.16.13                      32768
10.20.16.0/20               Network   10.20.16.13                      32768
10.11.16.0/20   10.20.16.4  EBgp      10.20.16.4    12076-64512-12076  32769
10.11.16.0/20   10.20.16.5  EBgp      10.20.16.5    12076-64512-12076  32769
172.16.0.8/30   10.20.16.4  EBgp      10.20.16.4    12076-64512        32769
172.16.0.8/30   10.20.16.5  EBgp      10.20.16.5    12076-64512        32769
172.16.0.4/30   10.20.16.4  EBgp      10.20.16.4    12076-64512        32769
172.16.0.4/30   10.20.16.5  EBgp      10.20.16.5    12076-64512        32769
10.1.0.0/20     10.20.16.4  EBgp      10.20.16.4    12076-64512-12076  32769
10.1.0.0/20     10.20.16.5  EBgp      10.20.16.5    12076-64512-12076  32769
10.2.0.0/20     10.20.16.4  EBgp      10.20.16.4    12076-64512-12076  32769
10.2.0.0/20     10.20.16.5  EBgp      10.20.16.5    12076-64512-12076  32769
10.11.0.0/20    10.20.16.4  EBgp      10.20.16.4    12076-64512-12076  32769
10.11.0.0/20    10.20.16.5  EBgp      10.20.16.5    12076-64512-12076  32769
172.16.0.0/30   10.20.16.4  EBgp      10.20.16.4    12076-64512        32769
172.16.0.0/30   10.20.16.5  EBgp      10.20.16.5    12076-64512        32769
172.16.0.12/30  10.20.16.4  EBgp      10.20.16.4    12076-64512        32769
172.16.0.12/30  10.20.16.5  EBgp      10.20.16.5    12076-64512        32769

Gateway: G01-hub1-ergw
Route tables:
Network         NextHop      Origin    SourcePeer    AsPath             Weight
--------------  -----------  --------  ------------  -----------------  --------
10.11.0.0/20                 Network   10.11.16.12                      32768
10.11.16.0/20                Network   10.11.16.12                      32768
10.1.0.0/20                  Network   10.11.16.12                      32768
10.2.0.0/20                  Network   10.11.16.12                      32768
10.10.0.0/24    10.11.16.15  IBgp      10.11.16.15   65001              32768
10.10.0.0/24    10.11.16.14  IBgp      10.11.16.14   65001              32768
172.16.0.4/30   10.11.16.6   EBgp      10.11.16.6    12076-64512        32769
172.16.0.4/30   10.11.16.7   EBgp      10.11.16.7    12076-64512        32769
172.16.0.0/30   10.11.16.6   EBgp      10.11.16.6    12076-64512        32769
172.16.0.0/30   10.11.16.7   EBgp      10.11.16.7    12076-64512        32769
172.16.0.8/30   10.11.16.6   EBgp      10.11.16.6    12076-64512        32769
172.16.0.8/30   10.11.16.7   EBgp      10.11.16.7    12076-64512        32769
10.20.16.0/20   10.11.16.6   EBgp      10.11.16.6    12076-64512-12076  32769
10.20.16.0/20   10.11.16.7   EBgp      10.11.16.7    12076-64512-12076  32769
10.20.0.0/20    10.11.16.6   EBgp      10.11.16.6    12076-64512-12076  32769
10.20.0.0/20    10.11.16.7   EBgp      10.11.16.7    12076-64512-12076  32769
172.16.0.12/30  10.11.16.6   EBgp      10.11.16.6    12076-64512        32769
172.16.0.12/30  10.11.16.7   EBgp      10.11.16.7    12076-64512        32769
10.20.0.0/24    10.11.16.14  IBgp      10.11.16.14   65002              32768
10.20.0.0/24    10.11.16.15  IBgp      10.11.16.15   65002              32768

Gateway: G01-hub1-vpngw
Route tables:
Network           NextHop        Origin    SourcePeer     AsPath    Weight
----------------  -------------  --------  -------------  --------  --------
10.11.0.0/20      10.11.16.12    IBgp      10.11.16.12              32769
10.11.0.0/20      10.11.16.13    IBgp      10.11.16.13              32769
10.11.16.0/20     10.11.16.12    IBgp      10.11.16.12              32769
10.11.16.0/20     10.11.16.13    IBgp      10.11.16.13              32769
10.1.0.0/20       10.11.16.12    IBgp      10.11.16.12              32769
10.1.0.0/20       10.11.16.13    IBgp      10.11.16.13              32769
10.2.0.0/20       10.11.16.12    IBgp      10.11.16.12              32769
10.2.0.0/20       10.11.16.13    IBgp      10.11.16.13              32769
10.20.0.0/24      192.168.20.20  EBgp      192.168.20.20  65002     32768
10.20.0.0/24      10.11.16.15    IBgp      10.11.16.15    65002     32768
192.168.10.10/32                 Network   10.11.16.14              32768
192.168.10.10/32  10.11.16.15    IBgp      10.11.16.15              32768
10.10.0.0/24      192.168.10.10  EBgp      192.168.10.10  65001     32768
10.10.0.0/24      10.11.16.15    IBgp      10.11.16.15    65001     32768
192.168.20.20/32                 Network   10.11.16.14              32768
192.168.20.20/32  10.11.16.15    IBgp      10.11.16.15              32768
10.11.0.0/20                     Network   10.11.16.14              32768
10.11.16.0/20                    Network   10.11.16.14              32768
10.1.0.0/20                      Network   10.11.16.14              32768
10.2.0.0/20                      Network   10.11.16.14              32768
10.11.0.0/20      10.11.16.12    IBgp      10.11.16.12              32769
10.11.0.0/20      10.11.16.13    IBgp      10.11.16.13              32769
10.11.16.0/20     10.11.16.12    IBgp      10.11.16.12              32769
10.11.16.0/20     10.11.16.13    IBgp      10.11.16.13              32769
10.1.0.0/20       10.11.16.12    IBgp      10.11.16.12              32769
10.1.0.0/20       10.11.16.13    IBgp      10.11.16.13              32769
10.20.0.0/24      192.168.20.20  EBgp      192.168.20.20  65002     32768
10.20.0.0/24      10.11.16.14    IBgp      10.11.16.14    65002     32768
10.2.0.0/20       10.11.16.12    IBgp      10.11.16.12              32769
10.2.0.0/20       10.11.16.13    IBgp      10.11.16.13              32769
192.168.20.20/32                 Network   10.11.16.15              32768
192.168.20.20/32  10.11.16.14    IBgp      10.11.16.14              32768
192.168.10.10/32                 Network   10.11.16.15              32768
192.168.10.10/32  10.11.16.14    IBgp      10.11.16.14              32768
10.10.0.0/24      192.168.10.10  EBgp      192.168.10.10  65001     32768
10.10.0.0/24      10.11.16.14    IBgp      10.11.16.14    65001     32768
10.11.0.0/20                     Network   10.11.16.15              32768
10.11.16.0/20                    Network   10.11.16.15              32768
10.1.0.0/20                      Network   10.11.16.15              32768
10.2.0.0/20                      Network   10.11.16.15              32768
```

</details>
<p>

<details>
<summary>Vnet Gateway -  BGP Peers</summary>

```sh
01-ipsec-over-er$ ../../scripts/vnet-gateway/get_bgp_peer_status.sh G01_IPsecOverER_RG

Resource group: G01_IPsecOverER_RG

Gateway: G01-branch2-ergw
Route tables:
Neighbor    ASN    LocalAddress    RoutesReceived    State
----------  -----  --------------  ----------------  ---------
10.20.16.4  12076  10.20.16.13     8                 Connected
10.20.16.5  12076  10.20.16.13     8                 Connected

Gateway: G01-hub1-ergw
Route tables:
Neighbor     ASN    LocalAddress    RoutesReceived    State
-----------  -----  --------------  ----------------  ---------
10.11.16.6   12076  10.11.16.12     6                 Connected
10.11.16.7   12076  10.11.16.12     6                 Connected
10.11.16.14  65515  10.11.16.12     2                 Connected
10.11.16.15  65515  10.11.16.12     2                 Connected

Gateway: G01-hub1-vpngw
Route tables:
Neighbor       ASN    LocalAddress    RoutesReceived    State
-------------  -----  --------------  ----------------  ---------
192.168.20.20  65002  10.11.16.14     1                 Connected
192.168.10.10  65001  10.11.16.14     1                 Connected
10.11.16.13    65515  10.11.16.14     4                 Connected
10.11.16.12    65515  10.11.16.14     4                 Connected
10.11.16.14    65515  10.11.16.14     0                 Unknown
10.11.16.15    65515  10.11.16.14     4                 Connected
192.168.20.20  65002  10.11.16.15     1                 Connected
192.168.10.10  65001  10.11.16.15     1                 Connected
10.11.16.13    65515  10.11.16.15     4                 Connected
10.11.16.12    65515  10.11.16.15     4                 Connected
10.11.16.14    65515  10.11.16.15     4                 Connected
10.11.16.15    65515  10.11.16.15     0                 Unknown
```

</details>
<p>

### 6. Express Route Circuits

<details>
<summary>Express Route Circuit - Route Tables</summary>

```sh
01-ipsec-over-er$ ../../scripts/vnet-gateway/get_er_route_tables.sh G01_IPsecOverER_RG

Resource group: G01_IPsecOverER_RG


⏳ AzurePrivatePeering (Primary): G01-branch2-er
LocPrf    Network         NextHop       Path         Weight
--------  --------------  ------------  -----------  --------
          10.1.0.0/20     172.16.0.9    64512 12076  0
          10.2.0.0/20     172.16.0.9    64512 12076  0
          10.11.0.0/20    172.16.0.9    64512 12076  0
          10.11.16.0/20   172.16.0.9    64512 12076  0
          10.20.0.0/20    10.20.16.12   65515        0
          10.20.0.0/20    10.20.16.13*  65515        0
          10.20.16.0/20   10.20.16.12   65515        0
          10.20.16.0/20   10.20.16.13*  65515        0
          172.16.0.0/30   172.16.0.9    64512 ?      0
          172.16.0.4/30   172.16.0.9    64512 ?      0
          172.16.0.12/30  172.16.0.9    64512 ?      0

⏳ AzurePrivatePeering (Secondary): G01-branch2-er
LocPrf    Network        NextHop       Path         Weight
--------  -------------  ------------  -----------  --------
          10.1.0.0/20    172.16.0.13   64512 12076  0
          10.2.0.0/20    172.16.0.13   64512 12076  0
          10.11.0.0/20   172.16.0.13   64512 12076  0
          10.11.16.0/20  172.16.0.13   64512 12076  0
          10.20.0.0/20   172.16.0.13   64512 12076  0
          10.20.0.0/20   10.20.16.13   65515        0
          10.20.0.0/20   10.20.16.12*  65515        0
          10.20.16.0/20  172.16.0.13   64512 12076  0
          10.20.16.0/20  10.20.16.13   65515        0
          10.20.16.0/20  10.20.16.12*  65515        0
          172.16.0.0/30  172.16.0.13   64512 ?      0
          172.16.0.4/30  172.16.0.13   64512 ?      0
          172.16.0.8/30  172.16.0.13   64512 ?      0

⏳ AzurePrivatePeering (Primary): G01-hub1-er
LocPrf    Network         NextHop       Path         Weight
--------  --------------  ------------  -----------  --------
          10.1.0.0/20     10.11.16.12   65515        0
          10.1.0.0/20     10.11.16.13*  65515        0
          10.2.0.0/20     10.11.16.12   65515        0
          10.2.0.0/20     10.11.16.13*  65515        0
          10.11.0.0/20    10.11.16.12   65515        0
          10.11.0.0/20    10.11.16.13*  65515        0
          10.11.16.0/20   10.11.16.12   65515        0
          10.11.16.0/20   10.11.16.13*  65515        0
          10.20.0.0/20    172.16.0.1    64512 12076  0
          10.20.16.0/20   172.16.0.1    64512 12076  0
          172.16.0.4/30   172.16.0.1    64512 ?      0
          172.16.0.8/30   172.16.0.1    64512 ?      0
          172.16.0.12/30  172.16.0.1    64512 ?      0

⏳ AzurePrivatePeering (Secondary): G01-hub1-er
LocPrf    Network         NextHop       Path         Weight
--------  --------------  ------------  -----------  --------
          10.1.0.0/20     172.16.0.5    64512 12076  0
          10.1.0.0/20     10.11.16.12   65515        0
          10.1.0.0/20     10.11.16.13*  65515        0
          10.2.0.0/20     172.16.0.5    64512 12076  0
          10.2.0.0/20     10.11.16.12   65515        0
          10.2.0.0/20     10.11.16.13*  65515        0
          10.11.0.0/20    172.16.0.5    64512 12076  0
          10.11.0.0/20    10.11.16.12   65515        0
          10.11.0.0/20    10.11.16.13*  65515        0
          10.11.16.0/20   172.16.0.5    64512 12076  0
          10.11.16.0/20   10.11.16.12   65515        0
          10.11.16.0/20   10.11.16.13*  65515        0
          10.20.0.0/20    172.16.0.5    64512 12076  0
          10.20.16.0/20   172.16.0.5    64512 12076  0
          172.16.0.0/30   172.16.0.5    64512 ?      0
          172.16.0.8/30   172.16.0.5    64512 ?      0
          172.16.0.12/30  172.16.0.5    64512 ?      0
⭐ Done!
```

</details>
<p>

## Troubleshooting

See the [troubleshooting](../../troubleshooting/README.md) section for tips on how to resolve common issues that may occur during the deployment of the lab.

## Cleanup

1\. (Optional) Navigate back to the lab directory (if you are not already there)

```sh
cd azure-network-terraform/4-general/01-ipsec-over-er
```

2\. (Optional) This is not required if `enable_diagnostics = false` in the [`main.tf`](./02-main.tf). If you deployed the lab with `enable_diagnostics = true`, in order to avoid terraform errors when re-deploying this lab, run a cleanup script to remove diagnostic settings that are not removed after the resource group is deleted.

```sh
bash ../../scripts/_cleanup.sh G01_IPsecOverER_RG
```

<details>

<summary>Sample output</summary>

```sh
01-ipsec-over-er$ bash ../../scripts/_cleanup.sh G01_IPsecOverER_RG

Resource group: G01_IPsecOverER_RG

⏳ Checking for diagnostic settings on resources in G01_IPsecOverER_RG ...
➜  Checking firewall ...
➜  Checking vnet gateway ...
    ❌ Deleting: diag setting [G01-hub1-ergw-diag] for vnet gateway [G01-hub1-ergw] ...
    ❌ Deleting: diag setting [G01-hub1-vpngw-diag] for vnet gateway [G01-hub1-vpngw] ...
➜  Checking vpn gateway ...
➜  Checking er gateway ...
➜  Checking app gateway ...
⏳ Checking for azure policies in G01_IPsecOverER_RG ...
Done!
```

</details>
<p>

3\. Delete Vnet gateway connections to express route circuits.

```sh
01-ipsec-over-er$ bash ../../scripts/express-route/delete_ergw_connections.sh G01_IPsecOverER_RG

Resource group: G01_IPsecOverER_RG

⏳ Processing circuit: G01-branch2-er
❓ Deleting connection: G01-branch2-er
❌ Deleted connection: G01-branch2-er
❓ Deleting connection: G01-hub1-er
❌ Deleted connection: G01-hub1-er
⏳ Processing circuit: G01-hub1-er
❓ Deleting connection: G01-branch2-er
❌ Deleted connection: G01-branch2-er
❓ Deleting connection: G01-hub1-er
❌ Deleted connection: G01-hub1-er
```

</details>
<p>

4\. Delete all express route private peerings.

```sh

```

</details>
<p>

5\. Delete the resource group to remove all resources installed.

```sh
az group delete -g G01_IPsecOverER_RG --no-wait
```

6\. Go to Megaport portal and delete MCR and VXCs created.

7\. Delete terraform state files and other generated files.

```sh
rm -rf .terraform*
rm terraform.tfstate*
```
