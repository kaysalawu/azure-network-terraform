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
  - [6. Private Link (App Service) Access from On-premises](#6-private-link-app-service-access-from-on-premises)
  - [7. Virtual WAN Routes](#7-virtual-wan-routes)
  - [8. On-premises Routes](#8-on-premises-routes)
  - [9. Azure Firewall](#9-azure-firewall)
- [Cleanup](#cleanup)

## Overview

Deploy a dual-region Secured Virtual WAN (Vwan) topology to observe traffic routing patterns. [Routing Intent](https://learn.microsoft.com/en-us/azure/virtual-wan/how-to-routing-policies) feature is enabled to allow traffic inspection through the Azure firewalls in the virtual hubs. Learn about multi-region traffic routing patterns, routing intent [security policies](https://learn.microsoft.com/en-us/azure/virtual-wan/how-to-routing-policies), [hybrid DNS](https://learn.microsoft.com/en-us/azure/dns/private-resolver-hybrid-dns) resolution, [connecting NVA](https://learn.microsoft.com/en-us/azure/virtual-wan/scenario-bgp-peering-hub) into the virtual hubs, and [PrivateLink Services](https://learn.microsoft.com/en-us/azure/private-link/private-link-service-overview) access to IaaS, [PrivateLink](https://learn.microsoft.com/en-us/azure/private-link/private-link-overview) access to PaaS services.

![Secured Virtual WAN - Dual Region](../../images/scenarios/2-4-vwan-sec-dual-region.png)

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
| Branch DNS Server | Unbound DNS server configuration showing on-premises authoritative zones and conditional forwarding to hub private DNS resolver endpoint | [output/branch-unbound.sh](./output/branch-unbound.sh) |
| Branch1 NVA | Cisco IOS commands for IPsec VPN, BGP, route maps etc. | [output/branch1-nva.sh](./output/branch1-nva.sh) |
| Branch3 NVA | Cisco IOS commands for IPsec VPN, BGP, route maps etc. | [output/branch3-nva.sh](./output/branch3-nva.sh) |
| Web server for workload VMs | Python Flask web server and various test and debug scripts | [output/server.sh](./output/server.sh) |
||||

## Dashboards (Optional)

This lab contains a number of pre-configured dashboards for monitoring and troubleshooting network gateways, VPN gateways, and Azure Firewall. If you have set `enable_diagnostics = true` in the `main.tf` file, then the dashboards will be created.

To view the dashboards, follow the steps below:

1. From the Azure portal menu, select **Dashboard hub**.

2. Under **Browse**, select **Shared dashboards**.

3. Select the dashboard you want to view.

   ![Shared dashboards](../../images/demos/virtual-wan/vwan24-shared-dashboards.png)

4. Click on the dashboard name.

5. Click on **Go to dashboard**.

   Sample dashboard for VPN gateway in ***hub1***.

    ![Go to dashboard](../../images/demos/virtual-wan/vwan24-vhub1-vpngw-db.png)

    Sample dashboard for Azure Firewall in ***hub1***.

   ![Go to dashboard](../../images/demos/virtual-wan/vwan24-vhub1-azfw-db.png)

## Testing

Each virtual machine is pre-configured with a shell [script](../../scripts/server.sh) to run various types of network reachability tests. Serial console access has been configured for all virtual machines. You can [access the serial console](https://learn.microsoft.com/en-us/troubleshoot/azure/virtual-machines/serial-console-overview#access-serial-console-for-virtual-machines-via-azure-portal) of a virtual machine from the Azure portal.

Login to virtual machine `Vwan24-spoke1-vm` via the serial console:

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
azureuser@Vwan24-spoke1-vm:~$ ping-ip

 ping ip ...

branch1 - 10.10.0.5 -OK 7.386 ms
hub1    - 10.11.0.5 -OK 5.000 ms
spoke1  - 10.1.0.5 -OK 0.024 ms
spoke2  - 10.2.0.5 -OK 7.032 ms
branch3 - 10.30.0.5 -OK 23.405 ms
hub2    - 10.22.0.5 -OK 23.352 ms
spoke4  - 10.4.0.5 -OK 19.402 ms
spoke5  - 10.5.0.5 -OK 20.471 ms
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
azureuser@Vwan24-spoke1-vm:~$ ping-dns

 ping dns ...

vm.branch1.corp - 10.10.0.5 -OK 7.942 ms
vm.hub1.we.az.corp - 10.11.0.5 -OK 5.715 ms
vm.spoke1.we.az.corp - 10.1.0.5 -OK 0.035 ms
vm.spoke2.we.az.corp - 10.2.0.5 -OK 5.908 ms
vm.branch3.corp - 10.30.0.5 -OK 22.737 ms
vm.hub2.ne.az.corp - 10.22.0.5 -OK 21.738 ms
vm.spoke4.ne.az.corp - 10.4.0.5 -OK 21.164 ms
vm.spoke5.ne.az.corp - 10.5.0.5 -OK 21.403 ms
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
azureuser@Vwan24-spoke1-vm:~$ curl-dns

 curl dns ...

200 (0.058916s) - 10.10.0.5 - vm.branch1.corp
200 (0.029715s) - 10.11.0.5 - vm.hub1.we.az.corp
200 (0.021327s) - 10.11.7.4 - spoke3.p.hub1.we.az.corp
200 (0.010701s) - 10.1.0.5 - vm.spoke1.we.az.corp
200 (0.031434s) - 10.2.0.5 - vm.spoke2.we.az.corp
000 (2.000205s) -  - vm.spoke3.we.az.corp
200 (0.103006s) - 10.30.0.5 - vm.branch3.corp
200 (0.077312s) - 10.22.0.5 - vm.hub2.ne.az.corp
200 (0.076840s) - 10.22.7.4 - spoke6.p.hub2.ne.az.corp
200 (0.082892s) - 10.4.0.5 - vm.spoke4.ne.az.corp
200 (0.093531s) - 10.5.0.5 - vm.spoke5.ne.az.corp
000 (2.001372s) -  - vm.spoke6.ne.az.corp
200 (0.021990s) - 104.18.115.97 - icanhazip.com
200 (0.036351s) - 10.11.7.5 - vwan24-spoke3-0425.azurewebsites.net
200 (0.064745s) - 10.22.7.5 - vwan24-spoke6-0425.azurewebsites.net
```

We can see that curl test to spoke3 virtual machine `vm.spoke3.we.az.corp` returns a ***000*** HTTP response code. This is expected since there is no Vnet peering from ***spoke3*** to ***hub1***. However, ***spoke3*** web application is reachable via Private Link Service private endpoint in ***hub1*** `spoke3.p.hub1.we.az.corp`. The same explanation applies to ***spoke6*** virtual machine `vm.spoke6.ne.az.corp`

### 4. Private Link Service

**4.1.** Test access to ***spoke3*** web application using the private endpoint in ***hub1***.

```sh
curl spoke3.p.hub1.we.az.corp
```

Sample output

```sh
azureuser@Vwan24-spoke1-vm:~$ curl spoke3.p.hub1.we.az.corp
{
  "Headers": {
    "Accept": "*/*",
    "Host": "spoke3.p.hub1.we.az.corp",
    "User-Agent": "curl/7.68.0"
  },
  "Hostname": "Vwan24-spoke3-vm",
  "Local-IP": "10.3.0.5",
  "Remote-IP": "10.3.6.4"
}
```

**4.2.** Test access to ***spoke6*** web application using the private endpoint in ***hub2***.

```sh
curl spoke6.p.hub2.ne.az.corp
```

Sample output

```sh
azureuser@Vwan24-spoke1-vm:~$ curl spoke6.p.hub2.ne.az.corp
{
  "Headers": {
    "Accept": "*/*",
    "Host": "spoke6.p.hub2.ne.az.corp",
    "User-Agent": "curl/7.68.0"
  },
  "Hostname": "Vwan24-spoke6-vm",
  "Local-IP": "10.6.0.5",
  "Remote-IP": "10.6.6.4"
}
```

The `Hostname` and `Local-IP` fields identifies the actual web servers - in this case ***spoke3*** and ***spoke6*** virtual machines. The `Remote-IP` fields (as seen by the web servers) are IP addresses in the Private Link Service NAT subnets in ***spoke3*** and ***spoke6*** respectively.

### 5. Private Link (App Service) Access from Public Client

App service instances are deployed for ***spoke3*** and ***spoke6***. The app service instance is a fully managed PaaS service. In this lab, the services are linked to ***spoke3*** and ***spoke6***. By using [Virtual Network integration](https://learn.microsoft.com/en-us/azure/app-service/overview-vnet-integration#regional-virtual-network-integration), the app services are deployed in dedicated ***AppServiceSubnet*** subnets in ***spoke3*** and ***spoke6***. This allows each app service to access private resources through their linked spoke Vnet.

The app services are accessible via the private endpoints in ***hub1*** and ***hub2*** respectively. The app services are also accessible via their public endpoints. The app service application is a simple [python Flask web application](https://hub.docker.com/r/ksalawu/web) that returns the HTTP headers, hostname and IP addresses of the server running the application.

The app services have the following naming convention:

- vwan24-spoke3-AAAA.azurewebsites.net
- vwan24-spoke6-BBBB.azurewebsites.net

Where ***AAAA*** and ***BBBB*** are randomly generated two-byte strings.

**5.1.** On your local machine, get the hostname of the app service linked to ***spoke3***

```sh
spoke3_apps_url=$(az webapp list --resource-group Vwan24RG --query "[?contains(name, 'vwan24-spoke3')].defaultHostName" -o tsv)
```

**5.2.** Display the hostname

```sh
echo $spoke3_apps_url
```

Sample output (yours will be different)

```sh
vwan24-spoke3-0425.azurewebsites.net
```

**5.3.** Resolve the hostname

```sh
nslookup $spoke3_apps_url
```

Sample output (yours will be different)

```sh
4-vwan-sec-dual-region$ nslookup $spoke3_apps_url
Server:         172.29.160.1
Address:        172.29.160.1#53

Non-authoritative answer:
vwan24-spoke3-0425.azurewebsites.net        canonical name = vwan24-spoke3-0425-app.privatelink.azurewebsites.net.
vwan24-spoke3-0425-app.privatelink.azurewebsites.net    canonical name = waws-prod-am2-715.sip.azurewebsites.windows.net.
waws-prod-am2-715.sip.azurewebsites.windows.net canonical name = waws-prod-am2-715-a929.westeurope.cloudapp.azure.com.
Name:   waws-prod-am2-715-a929.westeurope.cloudapp.azure.com
Address: 20.105.232.40
```

We can see that the endpoint is a public IP address, ***20.105.232.40***. We can see the CNAME `vwan24-spoke3-0425-app.privatelink.azurewebsites.net` created for the app service which recursively resolves to the public IP address.

**5.4.** Test access to the ***spoke3*** app service via the public endpoint.

```sh
curl $spoke3_apps_url
```

Sample output

```sh
4-vwan-sec-dual-region$ curl $spoke3_apps_url
{
  "Headers": {
    "Accept": "*/*",
    "Client-Ip": "140.228.48.45:31852",
    "Disguised-Host": "vwan24-spoke3-0425.azurewebsites.net",
    "Host": "vwan24-spoke3-0425.azurewebsites.net",
    "Max-Forwards": "10",
    "User-Agent": "curl/7.74.0",
    "Was-Default-Hostname": "vwan24-spoke3-0425.azurewebsites.net",
    "X-Arr-Log-Id": "989dea2e-5406-41f9-99ee-89d77deba7ad",
    "X-Client-Ip": "140.228.48.45",
    "X-Client-Port": "31852",
    "X-Forwarded-For": "140.228.48.45:31852",
    "X-Original-Url": "/",
    "X-Site-Deployment-Id": "vwan24-spoke3-0425-app",
    "X-Waws-Unencoded-Url": "/"
  },
  "Hostname": "7772894a7bd7",
  "Local-IP": "169.254.129.3",
  "Remote-IP": "169.254.129.1"
}
```

Observe that we are connecting from our local client's public IP address specified in the `X-Client-Ip`.

**(Optional)** Repeat *Step 5.1* through *Step 5.4* for the app service linked to ***spoke6***.

### 6. Private Link (App Service) Access from On-premises

**6.1** Recall the hostname of the app service in ***spoke3*** as done in *Step 5.2*. In this lab deployment, the hostname is `vwan24-spoke3-0425.azurewebsites.net`.

**6.2.** Connect to the on-premises server `Vwan24-branch1-vm` [using the serial console](https://learn.microsoft.com/en-us/troubleshoot/azure/virtual-machines/serial-console-overview#access-serial-console-for-virtual-machines-via-azure-portal). We will test access from `Vwan24-branch1-vm` to the app service for ***spoke3*** via the private endpoint in ***hub1***.

**6.3.** Resolve the hostname DNS - which is `vwan24-spoke3-0425.azurewebsites.net` in this example. Use your actual hostname from *Step 6.1*.

```sh
nslookup vwan24-spoke3-<AAAA>.azurewebsites.net
```

Sample output

```sh
azureuser@Vwan24-branch1-vm:~$ nslookup vwan24-spoke3-0425.azurewebsites.net

Server:         127.0.0.53
Address:        127.0.0.53#53

Non-authoritative answer:
vwan24-spoke3-0425.azurewebsites.net        canonical name = vwan24-spoke3-0425-app.privatelink.azurewebsites.net.
Name:   vwan24-spoke3-0425-app.privatelink.azurewebsites.net
Address: 10.11.7.5
```

We can see that the app service hostname resolves to the private endpoint ***10.11.7.5*** in ***hub1***. The following is a summary of the DNS resolution from `Vwan24-branch1-vm`:

- On-premises server `Vwan24-branch1-vm` makes a DNS request for `vwan24-spoke3-0425.azurewebsites.net`
- The request is received by on-premises DNS server `Vwan24-branch1-dns`
- The DNS server resolves `vwan24-spoke3-0425.azurewebsites.net` to the CNAME `vwan24-spoke3-0425-app.privatelink.azurewebsites.net`
- The DNS server has a conditional DNS forwarding defined in the [unbound DNS configuration file](./output/branch-unbound.sh).

  ```sh
  forward-zone:
          name: "privatelink.azurewebsites.net."
          forward-addr: 10.11.8.4
          forward-addr: 10.22.8.4
  ```

  DNS Requests matching `privatelink.azurewebsites.net` will be forwarded to the private DNS resolver inbound endpoint in ***hub1*** (10.11.8.4). The DNS resolver inbound endpoint for ***hub2*** (10.22.8.4) is also included for redundancy.
- The DNS server forwards the DNS request to the private DNS resolver inbound endpoint in ***hub1*** - which returns the IP address of the app service private endpoint in ***hub1*** (10.11.7.5)

**6.4.** From `Vwan24-branch1-vm`, test access to the ***spoke3*** app service via the private endpoint. Use your actual hostname.

```sh
curl vwan24-spoke3-<AAAA>.azurewebsites.net
```

Sample output

```sh
azureuser@Vwan24-branch1-vm:~$ curl vwan24-spoke3-0425.azurewebsites.net
{
  "Headers": {
    "Accept": "*/*",
    "Client-Ip": "[fd40:a472:112:22a7:7712:100:a0a:5]:38994",
    "Disguised-Host": "vwan24-spoke3-0425.azurewebsites.net",
    "Host": "vwan24-spoke3-0425.azurewebsites.net",
    "Max-Forwards": "10",
    "User-Agent": "curl/7.68.0",
    "Was-Default-Hostname": "vwan24-spoke3-0425.azurewebsites.net",
    "X-Arr-Log-Id": "27a12e19-4239-472e-8207-da0be85cebaa",
    "X-Client-Ip": "10.10.0.5",
    "X-Client-Port": "0",
    "X-Forwarded-For": "10.10.0.5",
    "X-Original-Url": "/",
    "X-Site-Deployment-Id": "vwan24-spoke3-0425-app",
    "X-Waws-Unencoded-Url": "/"
  },
  "Hostname": "7772894a7bd7",
  "Local-IP": "169.254.129.3",
  "Remote-IP": "169.254.129.1"
}
```

Observe that we are connecting from the private IP address of `Vwan24-branch1-vm` (10.10.0.5) specified in the `X-Client-Ip`.

### 7. Virtual WAN Routes

**7.1.** Ensure you are in the lab directory `azure-network-terraform/2-virtual-wan/4-vwan-sec-dual-region`

**7.2.** Display the virtual WAN routing table(s)

```sh
sh ../../scripts/_routes.sh Vwan24RG
```

Sample output

```sh
4-vwan-sec-dual-region$ sh ../../scripts/_routes.sh Vwan24RG

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

AddressPrefixes    AsPath             NextHopType
-----------------  -----------------  --------------------------
10.30.0.0/24       65003              VPN_S2S_Gateway
10.22.0.0/16                          Virtual Network Connection
10.4.0.0/16                           Virtual Network Connection
10.5.0.0/16        65020              HubBgpConnection
10.1.0.0/16        65520-65520        Remote Hub
10.10.0.0/24       65520-65520-65001  Remote Hub
10.2.0.0/16        65520-65520-65010  Remote Hub
10.11.0.0/16       65520-65520        Remote Hub
0.0.0.0/0                             Internet

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

AddressPrefixes    AsPath             NextHopType
-----------------  -----------------  --------------------------
10.10.0.0/24       65001              VPN_S2S_Gateway
10.5.0.0/16        65520-65520-65020  Remote Hub
10.30.0.0/24       65520-65520-65003  Remote Hub
10.22.0.0/16       65520-65520        Remote Hub
10.4.0.0/16        65520-65520        Remote Hub
10.11.0.0/16                          Virtual Network Connection
10.1.0.0/16                           Virtual Network Connection
10.2.0.0/16        65010              HubBgpConnection
0.0.0.0/0                             Internet
```

### 8. On-premises Routes

Login to the onprem router `Vwan24-branch1-nva` in order to observe its dynamic routes.

**8.1.** Login to virtual machine `Vwan24-branch1-nva` via the [serial console](https://learn.microsoft.com/en-us/troubleshoot/azure/virtual-machines/serial-console-overview#access-serial-console-for-virtual-machines-via-azure-portal).

**8.2.** Enter username and password

   - username = ***azureuser***
   - password = ***Password123***

**8.3.** Enter the Cisco ***enable*** mode

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
      10.0.0.0/8 is variably subnetted, 16 subnets, 4 masks
B        10.1.0.0/16 [20/0] via 192.168.11.12, 01:00:25
B        10.2.0.0/16 [20/0] via 192.168.11.12, 00:40:41
B        10.4.0.0/16 [20/0] via 192.168.11.12, 01:00:25
B        10.5.0.0/16 [20/0] via 192.168.11.13, 00:41:08
S        10.10.0.0/24 [1/0] via 10.10.3.1
C        10.10.1.0/24 is directly connected, GigabitEthernet1
L        10.10.1.9/32 is directly connected, GigabitEthernet1
C        10.10.3.0/24 is directly connected, GigabitEthernet2
L        10.10.3.9/32 is directly connected, GigabitEthernet2
C        10.10.10.0/30 is directly connected, Tunnel0
L        10.10.10.1/32 is directly connected, Tunnel0
C        10.10.10.4/30 is directly connected, Tunnel1
L        10.10.10.5/32 is directly connected, Tunnel1
B        10.11.0.0/16 [20/0] via 192.168.11.12, 00:43:27
B        10.22.0.0/16 [20/0] via 192.168.11.13, 00:42:37
B        10.30.0.0/24 [20/0] via 192.168.11.13, 00:56:15
      168.63.0.0/32 is subnetted, 1 subnets
S        168.63.129.16 [254/0] via 10.10.1.1
      169.254.0.0/32 is subnetted, 1 subnets
S        169.254.169.254 [254/0] via 10.10.1.1
      192.168.10.0/32 is subnetted, 1 subnets
C        192.168.10.10 is directly connected, Loopback0
      192.168.11.0/24 is variably subnetted, 3 subnets, 2 masks
B        192.168.11.0/24 [20/0] via 192.168.11.12, 01:00:25
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
Vwan24-branch1-nva-vm#show ip bgp
BGP table version is 11, local router ID is 192.168.10.10
Status codes: s suppressed, d damped, h history, * valid, > best, i - internal,
              r RIB-failure, S Stale, m multipath, b backup-path, f RT-Filter,
              x best-external, a additional-path, c RIB-compressed,
              t secondary path, L long-lived-stale,
Origin codes: i - IGP, e - EGP, ? - incomplete
RPKI validation codes: V valid, I invalid, N Not found

     Network          Next Hop            Metric LocPrf Weight Path
 r    0.0.0.0          192.168.11.13                          0 65515 i
 r>                    192.168.11.12                          0 65515 i
 *    10.1.0.0/16      192.168.11.13                          0 65515 i
 *>                    192.168.11.12                          0 65515 i
 *    10.2.0.0/16      192.168.11.13            0             0 65515 65010 i
 *>                    192.168.11.12            0             0 65515 65010 i
 *    10.4.0.0/16      192.168.11.13                          0 65515 65520 65520 e
 *>                    192.168.11.12                          0 65515 65520 65520 e
 *    10.5.0.0/16      192.168.11.12                          0 65515 65520 65520 65020 e
 *>                    192.168.11.13                          0 65515 65520 65520 65020 e
     Network          Next Hop            Metric LocPrf Weight Path
 *>   10.10.0.0/24     10.10.3.1                0         32768 i
 *    10.11.0.0/16     192.168.11.13                          0 65515 i
 *>                    192.168.11.12                          0 65515 i
 *    10.22.0.0/16     192.168.11.12                          0 65515 65520 65520 e
 *>                    192.168.11.13                          0 65515 65520 65520 e
 *    10.30.0.0/24     192.168.11.12                          0 65515 65520 65520 65003 e
 *>                    192.168.11.13                          0 65515 65520 65520 65003 e
 *    192.168.11.0     192.168.11.13                          0 65515 i
 *>                    192.168.11.12                          0 65515 i
```

We can see our hub and spoke Vnet ranges being learned dynamically in the BGP table.

### 9. Azure Firewall

**9.1.** Check the Azure Firewall logs to observe the traffic flow.

- Select the Azure Firewall resource `Vwan24-hub1-azfw` in the Azure portal.
- Click on **Logs** in the left navigation pane.
- Click on **Firewall Logs (Resource Specific Tables)**.
- Click on **Run** in the log category *Network rule logs*.

![Vwan24-hub1-azfw-network-rule-log](../../images/demos/virtual-wan/vwan24-hub1-net-rule-log.png)

Observe the firewall logs based on traffic flows generated from our tests.

![Vwan24-hub1-azfw-network-rule-log-data](../../images/demos/virtual-wan/vwan24-hub1-net-rule-log-detail.png)

**9.2** Repeat the same steps for the Azure Firewall resource `Vwan24-hub2-azfw`.

## Cleanup

1. (Optional) Navigate back to the lab directory (if you are not already there)

   ```sh
   cd azure-network-terraform/2-virtual-wan/4-vwan-sec-dual-region
   ```

2. In order to avoid terraform errors when re-deploying this lab, run a cleanup script to remove diagnostic settings that may not be removed after the resource group is deleted.

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
