# Hub and Spoke - Dual Region (NVA) <!-- omit from toc -->

## Lab: Hs14 <!-- omit from toc -->

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

Deploy a dual-region Hub and Spoke Vnet topology using Virtual Network Appliances (NVA) for traffic inspection. Learn about multi-region traffic routing patterns, [hybrid DNS](https://learn.microsoft.com/en-us/azure/dns/private-resolver-hybrid-dns) resolution, NVA deployment, and [PrivateLink Services](https://learn.microsoft.com/en-us/azure/private-link/private-link-service-overview) access to IaaS, [PrivateLink](https://learn.microsoft.com/en-us/azure/private-link/private-link-overview) access to PaaS services.

![Hub and Spoke (Dual region)](../../images/scenarios/1-4-hub-spoke-nva-dual-region.png)

***Hub1*** is a Vnet hub that has a Virtual Network Appliance (NVA) used for inspection of traffic between an on-premises branch and Vnet spokes. User-Defined Routes (UDR) are used to influence the hub Vnet data plane to route traffic between the branch and spokes via the NVA. An isolated spoke ***spoke3*** does not have Vnet peering to ***hub1***, but is reachable from the hub via [Private Link Service](https://learn.microsoft.com/en-us/azure/private-link/private-link-service-overview).

Similarly, ***hub2*** has an NVA used for inspection of traffic between branch and spokes. ***Spoke6*** does not have Vnet peering to ***hub2***, but is reachable from the hub via Private Link Service.

The hubs are connected together via Vnet peering to allow inter-hub network reachability.

***Branch1*** and ***branch3*** are on-premises networks simulated using Vnets. Multi-NIC Cisco-CSR-1000V NVA appliances connect to the hubs using IPsec VPN connections with dynamic (BGP) routing. A simulated on-premises Wide Area Network (WAN) is created using Vnet peering between ***branch1*** and ***branch3*** as the underlay connectivity, and IPsec with BGP as the overlay connection.

Each branch connects to Vnet spokes in their local regions through the directly connected hub. However, each branch connects to spokes in the remote region via the on-premises WAN network. For example, ***branch1*** only receives dynamic routes for ***spoke1***, ***spoke2*** and ***hub1*** through the VPN to ***hub1***. ***Branch1*** uses the simulated on-premises network via ***branch3*** to reach ***spoke4***, ***spoke5*** and ***hub2*** through the VPN from ***branch3*** to ***hub2***.

> ***_NOTE:_*** It is possible to route all Azure traffic from a branch through a single hub, but that is not the focus of this lab.

## Prerequisites

1. Ensure you meet all requirements in the [prerequisites](../../prerequisites/) before proceeding.

2. (Optional) In case you have run this lab previously, you need to delete diagnostic settings that may not be removed after the resource group was previously deleted. Navigate back to the lab directory (if you are not already there)

   ```sh
   cd azure-network-terraform/1-hub-and-spoke/4-hub-spoke-nva-dual-region
   ```

   Run the following script to delete pre-existing diagnostic settings.

   ```sh
   sh ../../scripts/_cleanup.sh Hs14RG
   ```

   Sample output

   ```sh
   4-hub-spoke-nva-dual-region$ sh ../../scripts/_cleanup.sh Hs14RG

   Resource group: Hs14RG

   Checking for diagnostic settings on firewalls ...
   Checking for diagnostic settings on vnet gateway ...
   Deleting: diag setting [Hs14-hub2-vpngw-diag] for vnetgw [Hs14-hub2-vpngw] ...
   Deleting: diag setting [Hs14-hub1-vpngw-diag] for vnetgw [Hs14-hub1-vpngw] ...
   Checking for diagnostic settings on vpn gateway ...
   Checking for diagnostic settings on er gateway ...
   Done!
   ```

## Deploy the Lab

1. Clone the Git Repository for the Labs

   ```sh
   git clone https://github.com/kaysalawu/azure-network-terraform.git
   ```

2. Navigate to the lab directory

   ```sh
   cd azure-network-terraform/1-hub-and-spoke/4-hub-spoke-nva-dual-region
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
| Branch3 NVA | Cisco IOS commands for IPsec VPN, BGP, route maps etc. | [output/branch3-nva.sh](./output/branch3-nva.sh) |
| Hub1 NVA | Linux NVA configuration. | [output/hub1-linux-nva.sh](./output/hub1-linux-nva.sh) |
| Hub2 NVA | Linux NVA configuration. | [output/hub2-linux-nva.sh](./output/hub2-linux-nva.sh) |
| Web server for workload VMs | Python Flask web server and various test and debug scripts | [output/server.sh](./output/server.sh) |
||||

## Testing

Each virtual machine is pre-configured with a shell [script](../../scripts/server.sh) to run various types of network reachability tests. Serial console access has been configured for all virtual machines. You can [access the serial console](https://learn.microsoft.com/en-us/troubleshoot/azure/virtual-machines/serial-console-overview#access-serial-console-for-virtual-machines-via-azure-portal) of a virtual machine from the Azure portal.

Login to virtual machine `Hs14-spoke1-vm` via the serial console:

- On Azure portal select *Virtual machines*
- Select the virtual machine `Hs14-spoke1-vm`
- Under ***Help*** section, select ***Serial console*** and wait for a login prompt
- Enter the login credentials
  - username = ***azureuser***
  - password = ***Password123***
- You should now be in a shell session `azureuser@Hs14-spoke1-vm:~$`

Run the following tests from inside the serial console session.

### 1. Ping IP

This script pings the IP addresses of some test virtual machines and reports reachability and round trip time.

**1.1.** Run the IP ping test

```sh
ping-ip
```

Sample output

```sh
azureuser@Hs14-spoke1-vm:~$ ping-ip

 ping ip ...

branch1 - 10.10.0.5 -OK 9.470 ms
hub1    - 10.11.0.5 -OK 3.564 ms
spoke1  - 10.1.0.5 -OK 0.033 ms
spoke2  - 10.2.0.5 -OK 4.756 ms
branch3 - 10.30.0.5 -OK 24.244 ms
hub2    - 10.22.0.5 -OK 20.842 ms
spoke4  - 10.4.0.5 -OK 22.122 ms
spoke5  - 10.5.0.5 -OK 20.468 ms
internet - icanhazip.com -OK 5.333 ms
```

### 2. Ping DNS

This script pings the DNS name of some test virtual machines and reports reachability and round trip time. This tests hybrid DNS resolution between on-premises and Azure.

**2.1.** Run the DNS ping test

```sh
ping-dns
```

Sample output

```sh
azureuser@Hs14-spoke1-vm:~$ ping-dns

 ping dns ...

vm.branch1.corp - 10.10.0.5 -OK 8.657 ms
vm.hub1.we.az.corp - 10.11.0.5 -OK 3.567 ms
vm.spoke1.we.az.corp - 10.1.0.5 -OK 0.031 ms
vm.spoke2.we.az.corp - 10.2.0.5 -OK 5.761 ms
vm.branch3.corp - 10.30.0.5 -OK 24.832 ms
vm.hub2.ne.az.corp - 10.22.0.5 -OK 20.770 ms
vm.spoke4.ne.az.corp - 10.4.0.5 -OK 24.512 ms
vm.spoke5.ne.az.corp - 10.5.0.5 -OK 21.137 ms
icanhazip.com - 104.18.114.97 -OK 4.711 ms
```

### 3. Curl DNS

This script uses curl to check reachability of web server (python Flask) on the test virtual machines. It reports HTTP response message, round trip time and IP address.

**3.1.** Run the DNS curl test

```sh
curl-dns
```

Sample output

```sh
azureuser@Hs14-spoke1-vm:~$ curl-dns

 curl dns ...

200 (0.048563s) - 10.10.0.5 - vm.branch1.corp
200 (0.027247s) - 10.11.0.5 - vm.hub1.we.az.corp
200 (0.024343s) - 10.11.7.4 - spoke3.p.hub1.we.az.corp
200 (0.012318s) - 10.1.0.5 - vm.spoke1.we.az.corp
200 (0.038658s) - 10.2.0.5 - vm.spoke2.we.az.corp
000 (2.001238s) -  - vm.spoke3.we.az.corp
200 (0.090154s) - 10.30.0.5 - vm.branch3.corp
200 (0.082816s) - 10.22.0.5 - vm.hub2.ne.az.corp
200 (0.084757s) - 10.22.7.4 - spoke6.p.hub2.ne.az.corp
200 (0.085554s) - 10.4.0.5 - vm.spoke4.ne.az.corp
200 (0.083624s) - 10.5.0.5 - vm.spoke5.ne.az.corp
000 (2.000216s) -  - vm.spoke6.ne.az.corp
200 (0.016200s) - 104.18.115.97 - icanhazip.com
200 (0.040601s) - 10.11.7.5 - hs14-spoke3-575a-app.azurewebsites.net
200 (0.073502s) - 10.22.7.5 - hs14-spoke6-575a-app.azurewebsites.net
```

We can see that curl test to spoke3 virtual machine `vm.spoke3.we.az.corp` returns a ***000*** HTTP response code. This is expected since there is no Vnet peering from ***spoke3*** to ***hub1***. However, ***spoke3*** web application is reachable via Private Link Service private endpoint in ***hub1*** `spoke3.p.hub1.we.az.corp`. The same explanation applies to ***spoke6*** virtual machine `vm.spoke6.ne.az.corp`

### 4. Private Link Service

**4.1.** Test access to ***spoke3*** web application using the private endpoint in ***hub1***.

```sh
curl spoke3.p.hub1.we.az.corp
```

Sample output

```sh
azureuser@Hs14-spoke1-vm:~$ curl spoke3.p.hub1.we.az.corp
{
  "Headers": {
    "Accept": "*/*",
    "Host": "spoke3.p.hub1.we.az.corp",
    "User-Agent": "curl/7.68.0"
  },
  "Hostname": "Hs14-spoke3-vm",
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
azureuser@Hs14-spoke1-vm:~$ curl spoke6.p.hub2.ne.az.corp
{
  "Headers": {
    "Accept": "*/*",
    "Host": "spoke6.p.hub2.ne.az.corp",
    "User-Agent": "curl/7.68.0"
  },
  "Hostname": "Hs14-spoke6-vm",
  "Local-IP": "10.6.0.5",
  "Remote-IP": "10.6.6.4"
}
```

The `Hostname` and `Local-IP` fields identifies the actual web servers - in this case ***spoke3*** and ***spoke6*** virtual machines. The `Remote-IP` fields (as seen by the web servers) are IP addresses in the Private Link Service NAT subnets in ***spoke3*** and ***spoke6*** respectively.

### 5. Private Link (App Service) Access from Public Client

App service instances are deployed for ***spoke3*** and ***spoke6***. The app service instance is a fully managed PaaS service. In this lab, the services are linked to ***spoke3*** and ***spoke6***. By using [Virtual Network integration](https://learn.microsoft.com/en-us/azure/app-service/overview-vnet-integration#regional-virtual-network-integration), the app services are deployed in dedicated ***AppServiceSubnet*** subnets in ***spoke3*** and ***spoke6***. This allows each app service to access private resources through their linked spoke Vnet.

The app services are accessible via the private endpoints in ***hub1*** and ***hub2*** respectively. The app services are also accessible via their public endpoints. The app service application is a simple [python Flask web application](https://hub.docker.com/r/ksalawu/web) that returns the HTTP headers, hostname and IP addresses of the server running the application.

The app services have the following naming convention:

- hs14-spoke3-AAAA-app.azurewebsites.net
- hs14-spoke6-BBBB-app.azurewebsites.net

Where ***AAAA*** and ***BBBB*** are randomly generated two-byte strings.

**5.1.** On your local machine, get the hostname of the app service linked to ***spoke3***

```sh
spoke3_apps_url=$(az webapp list --resource-group Hs14RG --query "[?contains(name, 'hs14-spoke3')].defaultHostName" -o tsv)
```

**5.2.** Display the hostname

```sh
echo $spoke3_apps_url
```

Sample output (yours will be different)

```sh
hs14-spoke3-575a-app.azurewebsites.net
```

**5.3.** Resolve the hostname

```sh
nslookup $spoke3_apps_url
```

Sample output (yours will be different)

```sh
4-hub-spoke-nva-dual-region$ nslookup $spoke3_apps_url
Server:         172.24.64.1
Address:        172.24.64.1#53

Non-authoritative answer:
hs14-spoke3-575a-app.azurewebsites.net  canonical name = hs14-spoke3-575a-app.privatelink.azurewebsites.net.
hs14-spoke3-575a-app.privatelink.azurewebsites.net      canonical name = waws-prod-am2-733.sip.azurewebsites.windows.net.
waws-prod-am2-733.sip.azurewebsites.windows.net canonical name = waws-prod-am2-733-a958.westeurope.cloudapp.azure.com.
Name:   waws-prod-am2-733-a958.westeurope.cloudapp.azure.com
Address: 20.105.232.44
```

We can see that the endpoint is a public IP address, ***20.105.232.44***. We can see the CNAME `hs14-spoke3-575a-app.privatelink.azurewebsites.net` created for the app service which recursively resolves to the public IP address.

**5.4.** Test access to the ***spoke3*** app service via the public endpoint.

```sh
curl $spoke3_apps_url
```

Sample output

```sh
4-hub-spoke-nva-dual-region$ curl $spoke3_apps_url
{
  "Headers": {
    "Accept": "*/*",
    "Client-Ip": "140.228.48.45:31938",
    "Disguised-Host": "hs14-spoke3-575a-app.azurewebsites.net",
    "Host": "hs14-spoke3-575a-app.azurewebsites.net",
    "Max-Forwards": "10",
    "User-Agent": "curl/7.74.0",
    "Was-Default-Hostname": "hs14-spoke3-575a-app.azurewebsites.net",
    "X-Arr-Log-Id": "1471ad3f-f8c6-4d9e-b36e-ada61942c284",
    "X-Client-Ip": "140.228.48.45",
    "X-Client-Port": "31938",
    "X-Forwarded-For": "140.228.48.45:31938",
    "X-Original-Url": "/",
    "X-Site-Deployment-Id": "hs14-spoke3-575a-app",
    "X-Waws-Unencoded-Url": "/"
  },
  "Hostname": "d28353f8c1ab",
  "Local-IP": "169.254.129.3",
  "Remote-IP": "169.254.129.1"
}
```

Observe that we are connecting from our local client's public IP address (140.228.48.45) specified in the `X-Client-Ip`.

**(Optional)** Repeat *Step 5.1* through *Step 5.4* for the app service linked to ***spoke6***.

### 6. Private Link (App Service) Access from On-premises

**6.1** Recall the hostname of the app service in ***spoke3*** as done in *Step 5.2*. In this lab deployment, the hostname is `hs14-spoke3-575a-app.azurewebsites.net`.

**6.2.** Connect to the on-premises server `Hs14-branch1-vm` [using the serial console](https://learn.microsoft.com/en-us/troubleshoot/azure/virtual-machines/serial-console-overview#access-serial-console-for-virtual-machines-via-azure-portal). We will test access from `Hs14-branch1-vm` to the app service for ***spoke3*** via the private endpoint in ***hub1***.

**6.3.** Resolve the hostname DNS - which is `hs14-spoke3-575a-app.azurewebsites.net` in this example. Use your actual hostname from *Step 6.1*.

```sh
nslookup hs14-spoke3-<AAAA>-app.azurewebsites.net
```

Sample output

```sh
azureuser@Hs14-branch1-vm:~$ nslookup hs14-spoke3-575a-app.azurewebsites.net
Server:         127.0.0.53
Address:        127.0.0.53#53

Non-authoritative answer:
hs14-spoke3-575a-app.azurewebsites.net  canonical name = hs14-spoke3-575a-app.privatelink.azurewebsites.net.
Name:   hs14-spoke3-575a-app.privatelink.azurewebsites.net
Address: 10.11.7.5
```

We can see that the app service hostname resolves to the private endpoint ***10.11.7.5*** in ***hub1***. The following is a summary of the DNS resolution from `Hs14-branch1-vm`:

- On-premises server `Hs14-branch1-vm` makes a DNS request for `hs14-spoke3-575a-app.azurewebsites.net`
- The request is received by on-premises DNS server `Hs14-branch1-dns`
- The DNS server resolves `hs14-spoke3-575a-app.azurewebsites.net` to the CNAME `hs14-spoke3-575a-app.privatelink.azurewebsites.net`
- The DNS server has a conditional DNS forwarding defined in the [unbound DNS configuration file](./output/branch-unbound.sh).

  ```sh
  forward-zone:
          name: "privatelink.azurewebsites.net."
          forward-addr: 10.11.8.4
          forward-addr: 10.22.8.4
  ```

  DNS Requests matching `privatelink.azurewebsites.net` will be forwarded to the private DNS resolver inbound endpoint in ***hub1*** (10.11.8.4). The DNS resolver inbound endpoint for ***hub2*** (10.22.8.4) is also included for redundancy.
- The DNS server forwards the DNS request to the private DNS resolver inbound endpoint in ***hub1*** - which returns the IP address of the app service private endpoint in ***hub1*** (10.11.7.5)

**6.4.** From `Hs14-branch1-vm`, test access to the ***spoke3*** app service via the private endpoint. Use your actual hostname.

```sh
curl hs14-spoke3-<AAAA>-app.azurewebsites.net
```

Sample output

```sh
azureuser@Hs14-branch1-vm:~$ curl hs14-spoke3-575a-app.azurewebsites.net
{
  "Headers": {
    "Accept": "*/*",
    "Client-Ip": "[fd40:517:12:875d:7912:f00:a0a:5]:37972",
    "Disguised-Host": "hs14-spoke3-575a-app.azurewebsites.net",
    "Host": "hs14-spoke3-575a-app.azurewebsites.net",
    "Max-Forwards": "10",
    "User-Agent": "curl/7.68.0",
    "Was-Default-Hostname": "hs14-spoke3-575a-app.azurewebsites.net",
    "X-Arr-Log-Id": "c96941b6-6419-43ce-832d-18978ab68d72",
    "X-Client-Ip": "10.10.0.5",
    "X-Client-Port": "0",
    "X-Forwarded-For": "10.10.0.5",
    "X-Original-Url": "/",
    "X-Site-Deployment-Id": "hs14-spoke3-575a-app",
    "X-Waws-Unencoded-Url": "/"
  },
  "Hostname": "d28353f8c1ab",
  "Local-IP": "169.254.129.3",
  "Remote-IP": "169.254.129.1"
}
```

Observe that we are connecting from the private IP address of `Hs14-branch1-vm` (10.10.0.5) specified in the `X-Client-Ip`.

### 7. Network Virtual Appliance (NVA)

Whilst still logged into the on-premises server `Hs14-branch1-vm` via the serial console, we will test connectivity to all virtual machines using a `trace-ip` script using the linux `tracepath` utility.

**7.1.** Run the `trace-ip` script

```sh
azureuser@Hs14-branch1-vm:~$ trace-ip

 trace ip ...


branch1
-------------------------------------
 1:  Hs14-branch1-vm                                       0.076ms reached
     Resume: pmtu 65535 hops 1 back 1

hub1
-------------------------------------
 1?: [LOCALHOST]                      pmtu 1500
 1:  10.10.3.9                                             1.071ms
 1:  10.10.3.9                                             6.093ms
 2:  10.10.3.9                                             9.006ms pmtu 1438
 2:  10.11.1.4                                             5.308ms
 3:  10.11.0.5                                             6.554ms reached
     Resume: pmtu 1438 hops 3 back 3

spoke1
-------------------------------------
 1?: [LOCALHOST]                      pmtu 1500
 1:  10.10.3.9                                             2.345ms
 1:  10.10.3.9                                             2.652ms
 2:  10.10.3.9                                             1.152ms pmtu 1438
 2:  10.11.1.4                                             5.894ms
 3:  10.1.0.5                                              7.419ms reached
     Resume: pmtu 1438 hops 3 back 3

spoke2
-------------------------------------
 1?: [LOCALHOST]                      pmtu 1500
 1:  10.10.3.9                                             2.496ms
 1:  10.10.3.9                                             1.520ms
 2:  10.10.3.9                                             1.327ms pmtu 1438
 2:  10.11.1.4                                             5.527ms
 3:  10.2.0.5                                              7.771ms reached
     Resume: pmtu 1438 hops 3 back 3

branch3
-------------------------------------
 1?: [LOCALHOST]                      pmtu 1500
 1:  10.30.0.5                                            16.522ms reached
 1:  10.30.0.5                                            16.293ms reached
     Resume: pmtu 1500 hops 1 back 1

hub2
-------------------------------------
 1?: [LOCALHOST]                      pmtu 1500
 1:  10.10.3.9                                             5.347ms
 1:  10.10.3.9                                             0.855ms
 2:  10.10.3.9                                             1.348ms pmtu 1446
 2:  10.30.30.9                                           18.339ms
 3:  10.30.30.9                                           28.940ms pmtu 1438
 3:  10.22.1.4                                            25.142ms
 4:  10.22.0.5                                            20.850ms reached
     Resume: pmtu 1438 hops 4 back 4

spoke4
-------------------------------------
 1?: [LOCALHOST]                      pmtu 1500
 1:  10.10.3.9                                             1.703ms
 1:  10.10.3.9                                             1.402ms
 2:  10.10.3.9                                             2.887ms pmtu 1446
 2:  10.30.30.9                                           17.337ms
 3:  10.30.30.9                                           18.058ms pmtu 1438
 3:  10.22.1.4                                            19.370ms
 4:  10.4.0.5                                             21.252ms reached
     Resume: pmtu 1438 hops 4 back 4

spoke5
-------------------------------------
 1?: [LOCALHOST]                      pmtu 1500
 1:  10.10.3.9                                             2.804ms
 1:  10.10.3.9                                             0.974ms
 2:  10.10.3.9                                             1.307ms pmtu 1446
 2:  10.30.30.9                                           18.127ms
 3:  10.30.30.9                                           17.671ms pmtu 1438
 3:  10.22.1.4                                            19.177ms
 4:  10.5.0.5                                             19.881ms reached
     Resume: pmtu 1438 hops 4 back 4

internet
-------------------------------------
 1?: [LOCALHOST]                      pmtu 1500
 1:  no reply
 2:  no reply
```

We can observe that traffic to ***spoke1***, ***spoke2*** and ***hub1*** flow symmetrically via the NVA in ***hub1*** (10.11.1.4). However, traffic to ***spoke4***, ***spoke5*** and ***hub2*** flow asymmetrically via the NVA in ***hub2*** (10.22.1.4).

### 8. On-premises Routes

Login to the onprem router `Hs14-branch1-nva` in order to observe its dynamic routes.

**8.1.** Login to virtual machine `Hs14-branch1-nva` via the [serial console](https://learn.microsoft.com/en-us/troubleshoot/azure/virtual-machines/serial-console-overview#access-serial-console-for-virtual-machines-via-azure-portal).

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
Hs14-branch1-nva-vm#show ip route
...
[Truncated for brevity]
...
Gateway of last resort is 10.10.1.1 to network 0.0.0.0

S*    0.0.0.0/0 [1/0] via 10.10.1.1
      10.0.0.0/8 is variably subnetted, 20 subnets, 4 masks
B        10.1.0.0/16 [20/0] via 10.11.10.4, 01:50:17
B        10.2.0.0/16 [20/0] via 10.11.10.4, 01:50:17
B        10.4.0.0/16 [20/0] via 192.168.30.30, 01:50:17
B        10.5.0.0/16 [20/0] via 192.168.30.30, 01:50:17
S        10.10.0.0/24 [1/0] via 10.10.3.1
C        10.10.1.0/24 is directly connected, GigabitEthernet1
L        10.10.1.9/32 is directly connected, GigabitEthernet1
C        10.10.3.0/24 is directly connected, GigabitEthernet2
L        10.10.3.9/32 is directly connected, GigabitEthernet2
C        10.10.10.0/30 is directly connected, Tunnel0
L        10.10.10.1/32 is directly connected, Tunnel0
C        10.10.10.4/30 is directly connected, Tunnel1
L        10.10.10.5/32 is directly connected, Tunnel1
C        10.10.10.8/30 is directly connected, Tunnel2
L        10.10.10.9/32 is directly connected, Tunnel2
B        10.11.0.0/16 [20/0] via 10.11.10.4, 01:50:17
S        10.11.10.4/32 is directly connected, Tunnel1
S        10.11.10.5/32 is directly connected, Tunnel0
B        10.22.0.0/16 [20/0] via 192.168.30.30, 01:50:17
B        10.30.0.0/24 [20/0] via 192.168.30.30, 01:50:17
      168.63.0.0/32 is subnetted, 1 subnets
S        168.63.129.16 [254/0] via 10.10.1.1
      169.254.0.0/32 is subnetted, 1 subnets
S        169.254.169.254 [254/0] via 10.10.1.1
      192.168.10.0/32 is subnetted, 1 subnets
C        192.168.10.10 is directly connected, Loopback0
      192.168.30.0/32 is subnetted, 1 subnets
S        192.168.30.30 is directly connected, Tunnel2
```

We can see our hub and spoke Vnet ranges are learned dynamically via BGP.

**8.5.** Display BGP information by typing `show ip bgp`.

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
 *    10.1.0.0/16      10.11.10.5                             0 65515 i
 *>                    10.11.10.4                             0 65515 i
 *    10.2.0.0/16      10.11.10.5                             0 65515 i
 *>                    10.11.10.4                             0 65515 i
 *>   10.4.0.0/16      192.168.30.30                          0 65003 65003 65003 65003 65515 i
 *>   10.5.0.0/16      192.168.30.30                          0 65003 65003 65003 65003 65515 i
 *>   10.10.0.0/24     10.10.3.1                0         32768 i
 *    10.11.0.0/16     10.11.10.5                             0 65515 i
 *>                    10.11.10.4                             0 65515 i
 *>   10.22.0.0/16     192.168.30.30                          0 65003 65003 65003 65003 65515 i
 *>   10.30.0.0/24     192.168.30.30            0             0 65003 65003 65003 65003 i
```

We can see our hub and spoke Vnet ranges being learned dynamically in the BGP table.

## Cleanup

1. (Optional) Navigate back to the lab directory (if you are not already there)

   ```sh
   cd azure-network-terraform/1-hub-and-spoke/4-hub-spoke-nva-dual-region
   ```

2. In order to avoid terraform errors when re-deploying this lab, run a cleanup script to remove diagnostic settings that may not be removed after the resource group is deleted.

   ```sh
   sh ../../scripts/_cleanup.sh Hs14RG
   ```

   Sample output

   ```sh
   4-hub-spoke-nva-dual-region$ sh ../../scripts/_cleanup.sh Hs14RG

   Resource group: Hs14RG

   Checking for diagnostic settings on firewalls ...
   Checking for diagnostic settings on vnet gateway ...
   Deleting: diag setting [Hs14-hub2-vpngw-diag] for vnetgw [Hs14-hub2-vpngw] ...
   Deleting: diag setting [Hs14-hub1-vpngw-diag] for vnetgw [Hs14-hub1-vpngw] ...
   Checking for diagnostic settings on vpn gateway ...
   Checking for diagnostic settings on er gateway ...
   Done!
   ```

3. Delete the resource group to remove all resources installed.

   ```sh
   az group delete -g Hs14RG --no-wait
   ```
