# Hub and Spoke - Single Region (NVA) <!-- omit from toc -->

## Lab: Hs13 <!-- omit from toc -->

Contents

- [Overview](#overview)
- [Prerequisites](#prerequisites)
- [Deploy the Lab](#deploy-the-lab)
- [Troubleshooting](#troubleshooting)
- [Outputs](#outputs)
- [Testing](#testing)
  - [1. Ping IP](#1-ping-ip)
  - [2. Ping DNS](#2-ping-dns)
  - [3. Curl DNS](#3-curl-dns)
  - [4. Private Link Service](#4-private-link-service)
  - [5. Private Link (App Service) Access from Public Client](#5-private-link-app-service-access-from-public-client)
  - [6. Private Link (App Service) Access from On-premises](#6-private-link-app-service-access-from-on-premises)
  - [7. Network Virtual Appliance (NVA)](#7-network-virtual-appliance-nva)
  - [8. On-premises Routes](#8-on-premises-routes)
- [Cleanup](#cleanup)

## Overview

Deploy a single-region Hub and Spoke Vnet topology using Virtual Network Appliances (NVA) for traffic inspection. Learn about traffic routing patterns, [hybrid DNS](https://learn.microsoft.com/en-us/azure/dns/private-resolver-hybrid-dns) resolution, NVA deployment, and [PrivateLink Services](https://learn.microsoft.com/en-us/azure/private-link/private-link-service-overview) access to IaaS, [PrivateLink](https://learn.microsoft.com/en-us/azure/private-link/private-link-overview) access to PaaS services.

![Hub and Spoke (Single region)](../../images/poc/4-1-megaport-er-two-locations.png)

***Hub1*** is a Vnet hub that has an NVA used for inspection of traffic between an on-premises branch and Vnet spokes. User-Defined Routes (UDR) are used to influence the hub Vnet data plane to route traffic between the branch and spokes via the NVA. An isolated spoke ***spoke3*** does not have Vnet peering to ***hub1***, but is reachable from the hub via [Private Link Service](https://learn.microsoft.com/en-us/azure/private-link/private-link-service-overview).

There are two on-premises locations - ***Branch1*** and ***Branch2*** that are connected via ExpressRoute using Megaport as the ExpressRoute partner. This allows us to observe dynamic routing with ExpressRoute deployed in two Microsoft peering locations.

***Branch1*** is an on-premises network simulated in a Vnet. An ExpressRoute virtual network gateway connects the branch to an ExpressRoute circuit in the Microsoft peering location ***FRA11***. Similarly, ***Branch2*** is the second on-premises network simulated in a Vnet. An ExpressRoute virtual network gateway connects the branch to an ExpressRoute circuit in the Microsoft peering location ***AM5***.

## Prerequisites

Ensure you meet all requirements in the [prerequisites](../../prerequisites/) before proceeding.

## Deploy the Lab

1. Clone the Git Repository for the Labs

   ```sh
   git clone https://github.com/kaysalawu/azure-network-terraform.git
   ```

2. Navigate to the lab directory

   ```sh
   cd azure-network-terraform/4-general/1-er-two-edge-locations
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

The table below show the auto-generated output files from the lab. They are located in the `output` directory.

| Item    | Description  | Location |
|--------|--------|--------|
| IP ranges and DNS | IP ranges and DNS hostname values | [output/values.md](./output/values.md) |
| Branch DNS Server | Unbound DNS server configuration showing on-premises authoritative zones and conditional forwarding to hub private DNS resolver endpoint | [output/branch-unbound.sh](./output/branch-unbound.sh) |
| Branch1 NVA | Cisco IOS commands for IPsec VPN, BGP, route maps etc. | [output/branch1-nva.sh](./output/branch1-nva.sh) |
| Hub1 NVA | Linux NVA configuration. | [output/hub1-linux-nva.sh](./output/hub1-linux-nva.sh) |
| Web server for workload VMs | Python Flask web server and various test and debug scripts | [output/server.sh](./output/server.sh) |
||||

## Testing

Each virtual machine is pre-configured with a shell [script](../../scripts/server.sh) to run various types of network reachability tests. Serial console access has been configured for all virtual machines. You can [access the serial console](https://learn.microsoft.com/en-us/troubleshoot/azure/virtual-machines/serial-console-overview#access-serial-console-for-virtual-machines-via-azure-portal) of a virtual machine from the Azure portal.

Login to virtual machine `Hs13-spoke1-vm` via the serial console:

- On Azure portal select *Virtual machines*
- Select the virtual machine `Hs13-spoke1-vm`
- Under ***Help*** section, select ***Serial console*** and wait for a login prompt
- Enter the login credentials
  - username = ***azureuser***
  - password = ***Password123***
- You should now be in a shell session `azureuser@Hs13-spoke1-vm:~$`

Run the following tests from inside the serial console session.

### 1. Ping IP

This script pings the IP addresses of some test virtual machines and reports reachability and round trip time.

**1.1.** Run the IP ping test

```sh
ping-ip
```

Sample output

```sh
azureuser@Hs13-spoke1-vm:~$ ping-ip

 ping ip ...

branch1 - 10.10.0.5 -OK 8.427 ms
hub1    - 10.11.0.5 -OK 4.725 ms
spoke1  - 10.1.0.5 -OK 0.033 ms
spoke2  - 10.2.0.5 -OK 4.373 ms
internet - icanhazip.com -OK 5.015 ms
```

### 2. Ping DNS

This script pings the DNS name of some test virtual machines and reports reachability and round trip time. This tests hybrid DNS resolution between on-premises and Azure.

**2.1.** Run the DNS ping test

```sh
ping-dns
```

Sample output

```sh
azureuser@Hs13-spoke1-vm:~$ ping-dns

 ping dns ...

vm.branch1.corp - 10.10.0.5 -OK 9.356 ms
vm.hub1.az.corp - 10.11.0.5 -OK 4.773 ms
vm.spoke1.az.corp - 10.1.0.5 -OK 0.037 ms
vm.spoke2.az.corp - 10.2.0.5 -OK 5.149 ms
icanhazip.com - 104.18.115.97 -OK 4.943 ms
```

### 3. Curl DNS

This script uses curl to check reachability of web server (python Flask) on the test virtual machines. It reports HTTP response message, round trip time and IP address.

**3.1.** Run the DNS curl test

```sh
curl-dns
```

Sample output

```sh
azureuser@Hs13-spoke1-vm:~$ curl-dns

 curl dns ...

200 (0.043516s) - 10.10.0.5 - vm.branch1.corp
200 (0.020636s) - 10.11.0.5 - vm.hub1.az.corp
200 (0.022112s) - 10.11.7.4 - spoke3.p.hub1.az.corp
[ 5838.330520] cloud-init[1631]: 10.1.0.5 - - [28/Nov/2023 09:50:15] "GET / HTTP/1.1" 200 -
200 (0.010707s) - 10.1.0.5 - vm.spoke1.az.corp
200 (0.036030s) - 10.2.0.5 - vm.spoke2.az.corp
000 (2.001452s) -  - vm.spoke3.az.corp
200 (0.016014s) - 104.18.114.97 - icanhazip.com
```

We can see that curl test to spoke3 virtual machine `vm.spoke3.we.az.corp` returns a ***000*** HTTP response code. This is expected since there is no Vnet peering from ***spoke3*** to ***hub1***. However, ***spoke3*** web application is reachable via Private Link Service private endpoint in ***hub1*** `spoke3.p.hub1.we.az.corp`.

### 4. Private Link Service

**4.1.** Test access to ***spoke3*** web application using the private endpoint in ***hub1***.

```sh
curl spoke3.p.hub1.we.az.corp
```

Sample output

```sh
azureuser@Hs13-spoke1-vm:~$ curl spoke3.p.hub1.we.az.corp
{
  "Headers": {
    "Accept": "*/*",
    "Host": "spoke3.p.hub1.az.corp",
    "User-Agent": "curl/7.68.0"
  },
  "Hostname": "Hs13-spoke3-vm",
  "Local-IP": "10.3.0.5",
  "Remote-IP": "10.3.6.4"
}
```

The `Hostname` and `Local-IP` fields identify the target web server - in this case ***spoke3*** virtual machine. The `Remote-IP` field (as seen by the web server) is an IP address in the Private Link Service NAT subnet in ***spoke3***.

### 5. Private Link (App Service) Access from Public Client

An app service instance is deployed for ***spoke3***. The app service instance is a fully managed PaaS service. In this lab, the service is linked to ***spoke3***. By using [Virtual Network integration](https://learn.microsoft.com/en-us/azure/app-service/overview-vnet-integration#regional-virtual-network-integration), the app service is deployed in a dedicated ***AppServiceSubnet*** subnet in ***spoke3***. This allows the app service to access private resources in ***spoke3*** Vnet.

The app service is accessible via the private endpoint in ***hub1***. The app service is also accessible via its public endpoint. The app service application is a simple [python Flask web application](https://hub.docker.com/r/ksalawu/web) that returns the HTTP headers, hostname and IP addresses of the server running the application.

The app service uses the following naming convention:

- hs13-spoke3-AAAA-app.azurewebsites.net

Where ***AAAA*** is a randomly generated two-byte string.

**5.1.** On your local machine, get the hostname of the app service linked to ***spoke3***

```sh
spoke3_apps_url=$(az webapp list --resource-group Hs13RG --query "[?contains(name, 'hs13-spoke3')].defaultHostName" -o tsv)
```

**5.2.** Display the hostname

```sh
echo $spoke3_apps_url
```

Sample output (yours will be different)

```sh
hs13-spoke3-05e9-app.azurewebsites.net
```

**5.3.** Resolve the hostname

```sh
nslookup $spoke3_apps_url
```

Sample output (yours will be different)

```sh
3-hub-spoke-nva-single-region$ nslookup $spoke3_apps_url
Server:         172.19.64.1
Address:        172.19.64.1#53

Non-authoritative answer:
hs13-spoke3-05e9-app.azurewebsites.net  canonical name = hs13-spoke3-05e9-app.privatelink.azurewebsites.net.
hs13-spoke3-05e9-app.privatelink.azurewebsites.net      canonical name = waws-prod-am2-569.sip.azurewebsites.windows.net.
waws-prod-am2-569.sip.azurewebsites.windows.net canonical name = waws-prod-am2-569-4aa6.westeurope.cloudapp.azure.com.
Name:   waws-prod-am2-569-4aa6.westeurope.cloudapp.azure.com
Address: 20.105.216.13
```

We can see that the endpoint is a public IP address, ***20.105.216.13***. We can see the CNAME `hs13-spoke3-05e9-app.privatelink.azurewebsites.net` created for the app service which recursively resolves to the public IP address.

**5.4.** Test access to the ***spoke3*** app service via the public endpoint.

```sh
curl $spoke3_apps_url
```

Sample output

```sh
3-hub-spoke-nva-single-region$ curl $spoke3_apps_url
{
  "Headers": {
    "Accept": "*/*",
    "Client-Ip": "152.37.70.253:2314",
    "Disguised-Host": "hs13-spoke3-05e9-app.azurewebsites.net",
    "Host": "hs13-spoke3-05e9-app.azurewebsites.net",
    "Max-Forwards": "10",
    "User-Agent": "curl/7.74.0",
    "Was-Default-Hostname": "hs13-spoke3-05e9-app.azurewebsites.net",
    "X-Arr-Log-Id": "9e81de29-02b6-469b-a609-bd8e3c5ff22d",
    "X-Client-Ip": "152.37.70.253",
    "X-Client-Port": "2314",
    "X-Forwarded-For": "152.37.70.253:2314",
    "X-Original-Url": "/",
    "X-Site-Deployment-Id": "hs13-spoke3-05e9-app",
    "X-Waws-Unencoded-Url": "/"
  },
  "Hostname": "b4c2708631ae",
  "Local-IP": "169.254.129.3",
  "Remote-IP": "169.254.129.1"
}
```

Observe that we are connecting from our local client's public IP address (174.173.70.196) specified in the `X-Client-Ip`.

Let's confirm the public IP address of our local machine

```sh
curl -4 icanhazip.com
```

Sample output (yours will be different)

```sh
$ curl -4 icanhazip.com
152.37.70.253
```

**(Optional)** Repeat *Step 5.1* through *Step 5.4* for the app service linked to ***spoke6***.

### 6. Private Link (App Service) Access from On-premises

**6.1** Recall the hostname of the app service in ***spoke3*** as done in *Step 5.2*. In this lab deployment, the hostname is `hs13-spoke3-05e9-app.azurewebsites.net`.

**6.2.** Connect to the on-premises server `Hs13-branch1-vm` [using the serial console](https://learn.microsoft.com/en-us/troubleshoot/azure/virtual-machines/serial-console-overview#access-serial-console-for-virtual-machines-via-azure-portal). We will test access from `Hs13-branch1-vm` to the app service for ***spoke3*** via the private endpoint in ***hub1***.

**6.3.** Resolve the hostname DNS - which is `hs13-spoke3-05e9-app.azurewebsites.net` in this example. Use your actual hostname from *Step 6.1*.

```sh
nslookup hs13-spoke3-<AAAA>-app.azurewebsites.net
```

Sample output

```sh
azureuser@Hs13-branch1-vm:~$ nslookup hs13-spoke3-05e9-app.azurewebsites.net
Server:         127.0.0.53
Address:        127.0.0.53#53

Non-authoritative answer:
hs13-spoke3-05e9-app.azurewebsites.net  canonical name = hs13-spoke3-05e9-app.privatelink.azurewebsites.net.
Name:   hs13-spoke3-05e9-app.privatelink.azurewebsites.net
Address: 10.11.7.5
```

We can see that the app service hostname resolves to the private endpoint ***10.11.7.5*** in ***hub1***. The following is a summary of the DNS resolution from `Hs13-branch1-vm`:

- On-premises server `Hs13-branch1-vm` makes a DNS request for `hs13-spoke3-05e9-app.azurewebsites.net`
- The request is received by on-premises DNS server `Hs13-branch1-dns`
- The DNS server resolves `hs13-spoke3-05e9-app.azurewebsites.net` to the CNAME `hs13-spoke3-05e9-app.privatelink.azurewebsites.net`
- The DNS server has a conditional DNS forwarding defined in the [unbound DNS configuration file](./output/branch-unbound.sh).

  ```sh
  forward-zone:
          name: "privatelink.azurewebsites.net."
          forward-addr: 10.11.8.4
  ```

  DNS Requests matching `privatelink.azurewebsites.net` will be forwarded to the private DNS resolver inbound endpoint in ***hub1*** (10.11.8.4).
- The DNS server forwards the DNS request to the private DNS resolver inbound endpoint in ***hub1*** - which returns the IP address of the app service private endpoint in ***hub1*** (10.11.7.5)

**6.4.** From `Hs13-branch1-vm`, test access to the ***spoke3*** app service via the private endpoint. Use your actual hostname.

```sh
curl hs13-spoke3-<AAAA>-app.azurewebsites.net
```

Sample output

```sh
azureuser@Hs13-branch1-vm:~$ curl hs13-spoke3-05e9-app.azurewebsites.net
{
  "Headers": {
    "Accept": "*/*",
    "Client-Ip": "[fd40:5257:112:886d:7b12:c00:a0a:5]:46066",
    "Disguised-Host": "hs13-spoke3-05e9-app.azurewebsites.net",
    "Host": "hs13-spoke3-05e9-app.azurewebsites.net",
    "Max-Forwards": "10",
    "User-Agent": "curl/7.68.0",
    "Was-Default-Hostname": "hs13-spoke3-05e9-app.azurewebsites.net",
    "X-Arr-Log-Id": "2f3f162b-7412-475a-834e-f4a4c172365e",
    "X-Client-Ip": "10.10.0.5",
    "X-Client-Port": "0",
    "X-Forwarded-For": "10.10.0.5",
    "X-Original-Url": "/",
    "X-Site-Deployment-Id": "hs13-spoke3-05e9-app",
    "X-Waws-Unencoded-Url": "/"
  },
  "Hostname": "b4c2708631ae",
  "Local-IP": "169.254.129.3",
  "Remote-IP": "169.254.129.1"
}
```

Observe that we are connecting from the private IP address of `Hs13-branch1-vm` (10.10.0.5) specified in the `X-Client-Ip`.

### 7. Network Virtual Appliance (NVA)

Whilst still logged into the on-premises server `Hs13-branch1-vm` via the serial console, we will test connectivity to all virtual machines using a `trace-ip` script using the linux `tracepath` utility.

**7.1.** Run the `trace-ip` script

```sh
azureuser@Hs13-branch1-vm:~$ trace-ip

 trace ip ...


branch1
-------------------------------------
 1:  Hs13-branch1-vm                                       0.094ms reached
     Resume: pmtu 65535 hops 1 back 1

hub1
-------------------------------------
 1?: [LOCALHOST]                      pmtu 1500
 1:  10.10.3.9                                             1.430ms
 1:  10.10.3.9                                             3.268ms
 2:  10.10.3.9                                            10.311ms pmtu 1438
 2:  10.11.1.4                                             5.433ms
 3:  10.11.0.5                                             7.819ms reached
     Resume: pmtu 1438 hops 3 back 3

spoke1
-------------------------------------
 1?: [LOCALHOST]                      pmtu 1500
 1:  10.10.3.9                                             2.915ms
 1:  10.10.3.9                                             1.112ms
 2:  10.10.3.9                                             1.419ms pmtu 1438
 2:  10.11.1.4                                             4.916ms
 3:  10.1.0.5                                              7.337ms reached
     Resume: pmtu 1438 hops 3 back 3

spoke2
-------------------------------------
 1?: [LOCALHOST]                      pmtu 1500
 1:  10.10.3.9                                             1.917ms
 1:  10.10.3.9                                             4.157ms
 2:  10.10.3.9                                             1.415ms pmtu 1438
 2:  10.11.1.4                                             6.221ms
 3:  10.2.0.5                                              8.072ms reached
     Resume: pmtu 1438 hops 3 back 3

internet
-------------------------------------
 1?: [LOCALHOST]                      pmtu 1500
 1:  no reply
 2:  no reply
```

We can observe that traffic to ***spoke1***, ***spoke2*** and ***hub1*** flow symmetrically via the NVA in ***hub1*** (10.11.1.4).

### 8. On-premises Routes

Login to the onprem router `Hs13-branch1-nva` in order to observe its dynamic routes.

**8.1.** Login to virtual machine `Hs13-branch1-nva` via the [serial console](https://learn.microsoft.com/en-us/troubleshoot/azure/virtual-machines/serial-console-overview#access-serial-console-for-virtual-machines-via-azure-portal).

**8.2.** Enter username and password

   - username = ***azureuser***
   - password = ***Password123***

**8.3.** Enter the Cisco enable mode

```sh
enable
```

**8.4.** Display the routing table by typing `show ip route` and pressing the space bar to show the complete output.

```sh
show ip route
```

Sample output

```sh
Hs13-branch1-nva-vm#show ip route
Codes: L - local, C - connected, S - static, R - RIP, M - mobile, B - BGP
       D - EIGRP, EX - EIGRP external, O - OSPF, IA - OSPF inter area
       N1 - OSPF NSSA external type 1, N2 - OSPF NSSA external type 2
       E1 - OSPF external type 1, E2 - OSPF external type 2, m - OMP
       n - NAT, Ni - NAT inside, No - NAT outside, Nd - NAT DIA
       i - IS-IS, su - IS-IS summary, L1 - IS-IS level-1, L2 - IS-IS level-2
       ia - IS-IS inter area, * - candidate default, U - per-user static route
       H - NHRP, G - NHRP registered, g - NHRP registration summary
       o - ODR, P - periodic downloaded static route, l - LISP
       a - application route
       + - replicated route, % - next hop override, p - overrides from PfR
       & - replicated local route overrides by connected

Gateway of last resort is 10.10.1.1 to network 0.0.0.0

S*    0.0.0.0/0 [1/0] via 10.10.1.1
      10.0.0.0/8 is variably subnetted, 14 subnets, 4 masks
B        10.1.0.0/16 [20/0] via 10.11.10.4, 01:16:40
B        10.2.0.0/16 [20/0] via 10.11.10.4, 01:16:40
S        10.10.0.0/24 [1/0] via 10.10.3.1
C        10.10.1.0/24 is directly connected, GigabitEthernet1
L        10.10.1.9/32 is directly connected, GigabitEthernet1
C        10.10.3.0/24 is directly connected, GigabitEthernet2
L        10.10.3.9/32 is directly connected, GigabitEthernet2
C        10.10.10.0/30 is directly connected, Tunnel0
L        10.10.10.1/32 is directly connected, Tunnel0
C        10.10.10.4/30 is directly connected, Tunnel1
L        10.10.10.5/32 is directly connected, Tunnel1
B        10.11.0.0/16 [20/0] via 10.11.10.4, 01:16:40
S        10.11.10.4/32 is directly connected, Tunnel1
S        10.11.10.5/32 is directly connected, Tunnel0
      168.63.0.0/32 is subnetted, 1 subnets
S        168.63.129.16 [254/0] via 10.10.1.1
      169.254.0.0/32 is subnetted, 1 subnets
S        169.254.169.254 [254/0] via 10.10.1.1
      192.168.10.0/32 is subnetted, 1 subnets
C        192.168.10.10 is directly connected, Loopback0
```

We can see our hub and spoke Vnet ranges are learned dynamically via BGP.

**8.5.** Display BGP information by typing `show ip bgp`.

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
 *    10.1.0.0/16      10.11.10.5                             0 65515 i
 *>                    10.11.10.4                             0 65515 i
 *    10.2.0.0/16      10.11.10.5                             0 65515 i
 *>                    10.11.10.4                             0 65515 i
 *>   10.10.0.0/24     10.10.3.1                0         32768 i
 *    10.11.0.0/16     10.11.10.5                             0 65515 i
 *>                    10.11.10.4                             0 65515 i
```

We can see our hub and spoke Vnet ranges being learned dynamically in the BGP table.

## Cleanup

1. (Optional) Navigate back to the lab directory (if you are not already there)

   ```sh
   cd azure-network-terraform/4-general/1-er-two-edge-locations
   ```

2. Delete the resource group to remove all resources installed.

   ```sh
   az group delete -g Hs13RG --no-wait
   ```
