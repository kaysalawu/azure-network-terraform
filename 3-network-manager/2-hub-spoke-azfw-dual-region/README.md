# Secured Hub and Spoke - Dual Region (Virtual Network Manager) <!-- omit from toc -->

## Lab: Ne32 <!-- omit from toc -->

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
  - [7. On-premises Routes](#7-on-premises-routes)
  - [8. Azure Firewall](#8-azure-firewall)
- [Cleanup](#cleanup)

## Overview

Deploy a dual-region Hub and Spoke Secured Virtual Network (Vnet) topology using the [Azure Virtual Network Manager](https://learn.microsoft.com/en-us/azure/virtual-network-manager/concept-connectivity-configuration#hub-and-spoke-topology) (AVNM) service. Learn about traffic routing patterns, [hybrid DNS](https://learn.microsoft.com/en-us/azure/dns/private-resolver-hybrid-dns) resolution, firewall security policies, and [PrivateLink Services](https://learn.microsoft.com/en-us/azure/private-link/private-link-service-overview) access to IaaS, [PrivateLink](https://learn.microsoft.com/en-us/azure/private-link/private-link-overview) access to PaaS services.

![Secured Hub and Spoke (Dual region)](../../images/scenarios/3-2-hub-spoke-nm-azfw-dual-region.png)

***Hub1*** is a Vnet hub that has an Azure firewall used for inspection of traffic between an on-premises branch and Vnet spokes. User-Defined Routes (UDR) are used to influence the hub Vnet data plane to route traffic between the branch and spokes via the firewall. An isolated spoke ***spoke3*** does not have Vnet peering to ***hub1***, but is reachable from the hub via [Private Link Service](https://learn.microsoft.com/en-us/azure/private-link/private-link-service-overview). AVNM is used to create a hub and spoke topology that connects ***spoke1*** and ***spoke2*** to ***hub1***. The spokes are not directly connected to each other but use the hub Azure firewall for inter-spoke traffic.

Similarly, ***hub2*** has an Azure firewall used for inspection of traffic between branch and spokes. ***Spoke6*** does not have Vnet peering to ***hub2***, but is reachable from the hub via Private Link Service. AVNM creates a hub and spoke topology that connects ***spoke4*** and ***spoke5*** to ***hub2***.

The hubs are connected together via Vnet peering to allow inter-hub network reachability.

***Branch1*** and ***branch3*** are on-premises networks simulated using Vnets. Multi-NIC Linux NVA appliances connect to the hubs using IPsec VPN connections with dynamic (BGP) routing. A simulated on-premises Wide Area Network (WAN) is created using Vnet peering between ***branch1*** and ***branch3*** as the underlay connectivity, and IPsec with BGP as the overlay connection.

Each branch connects to Vnet spokes in their local regions through the directly connected hub. However, each branch connects to spokes in the remote region via the on-premises WAN network. For example, ***branch1*** only receives dynamic routes for ***spoke1***, ***spoke2*** and ***hub1*** through the VPN to ***hub1***. ***Branch1*** uses the simulated on-premises network via ***branch3*** to reach ***spoke4***, ***spoke5*** and ***hub2*** through the VPN from ***branch3*** to ***hub2***.

> ***_NOTE:_*** It is possible for a branch to use a single hub to reach all Azure destinations, but that is not the focus of this lab.

## Prerequisites

Ensure you meet all requirements in the [prerequisites](../../prerequisites/README.md) before proceeding.

## Deploy the Lab

1. Clone the Git Repository for the Labs

   ```sh
   git clone https://github.com/kaysalawu/azure-network-terraform.git
   ```

2. Navigate to the lab directory

   ```sh
   cd azure-network-terraform/3-network-manager/2-hub-spoke-azfw-dual-region
   ```

3. Run the following terraform commands and type ***yes*** at the prompt:

   ```sh
   terraform init
   terraform plan
   terraform apply -parallelism=50
   ```

## Troubleshooting

See the [troubleshooting](../../troubleshooting/README.md) section for tips on how to resolve common issues that may occur during the deployment of the lab.

## Outputs

The table below shows the auto-generated output files from the lab. They are located in the `output` directory.

| Item    | Description  | Location |
|--------|--------|--------|
| IP ranges and DNS | IP ranges and DNS hostname values | [output/values.md](./output/values.md) |
| Branch DNS Server | Unbound DNS server configuration showing on-premises authoritative zones and conditional forwarding to hub private DNS resolver endpoint | [output/branch-unbound.sh](./output/branch-unbound.sh) |
| Branch1 NVA | Cisco IOS commands for IPsec VPN, BGP, route maps etc. | [output/branch1Nva.sh](./output/branch1Nva.sh) |
| Branch3 NVA | Cisco IOS commands for IPsec VPN, BGP, route maps etc. | [output/branch3Nva.sh](./output/branch3Nva.sh) |
| Web server for workload VMs | Python Flask web server and various test and debug scripts | [output/server.sh](./output/server.sh) |
| Azure policies | Azure policies for Virtual Network Manager network groups | [output/policies.json](./output/policies/pol-ng-spokes.json) |
||||

## Dashboards (Optional)

This lab contains a number of pre-configured dashboards for monitoring and troubleshooting network gateways, VPN gateways, and Azure Firewall. If you have set `enable_diagnostics = true` in the `main.tf` file, then the dashboards will be created.

To view the dashboards, follow the steps below:

1. From the Azure portal menu, select **Dashboard hub**.

2. Under **Browse**, select **Shared dashboards**.

3. Select the dashboard you want to view.

   ![Shared dashboards](../../images/demos/network-manager/ne32-shared-dashboards.png)

4. Click on a dashboard under **Go to dashboard** column.

   Sample dashboard for VPN gateway in ***hub1***.

    ![Go to dashboard](../../images/demos/network-manager/ne32-hub1-vpngw-db.png)

    Sample dashboard for Azure Firewall in ***hub1***.

   ![Go to dashboard](../../images/demos/network-manager/ne32-hub1-azfw-db.png)

## Testing

Each virtual machine is pre-configured with a shell [script](../../scripts/server.sh) to run various types of network reachability tests. Serial console access has been configured for all virtual machines. You can [access the serial console](https://learn.microsoft.com/en-us/troubleshoot/azure/virtual-machines/serial-console-overview#access-serial-console-for-virtual-machines-via-azure-portal) of a virtual machine from the Azure portal.

Login to virtual machine `Ne32-spoke1Vm` via the serial console:

- On Azure portal select *Virtual machines*
- Select the virtual machine `Ne32-spoke1Vm`
- Under ***Help*** section, select ***Serial console*** and wait for a login prompt
- Enter the login credentials
  - username = ***azureuser***
  - password = ***Password123***
- You should now be in a shell session `azureuser@Ne32-spoke1Vm:~$`

Run the following tests from inside the serial console session.

### 1. Ping IP

This script pings the IP addresses of some test virtual machines and reports reachability and round trip time.

**1.1.** Run the IP ping test

```sh
ping-ip
```

Sample output

```sh
azureuser@Ne32-spoke1Vm:~$ ping-ip

 ping ip ...

branch1 - 10.10.0.5 -OK 13.724 ms
hub1    - 10.11.0.5 -OK 5.474 ms
spoke1  - 10.1.0.5 -OK 0.030 ms
spoke2  - 10.2.0.5 -OK 9.856 ms
branch3 - 10.30.0.5 -OK 24.962 ms
hub2    - 10.22.0.5 -OK 19.793 ms
spoke4  - 10.4.0.5 -OK 21.291 ms
spoke5  - 10.5.0.5 -OK 21.642 ms
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
azureuser@Ne32-spoke1Vm:~$ ping-dns

 ping dns ...

vm.branch1.corp - 10.10.0.5 -OK 9.304 ms
vm.hub1.az.corp - 10.11.0.5 -OK 5.012 ms
vm.spoke1.az.corp - 10.1.0.5 -OK 0.031 ms
vm.spoke2.az.corp - 10.2.0.5 -OK 5.547 ms
vm.branch3.corp - 10.30.0.5 -OK 29.216 ms
vm.hub2.az.corp - 10.22.0.5 -OK 18.886 ms
vm.spoke4.az.corp - 10.4.0.5 -OK 21.373 ms
vm.spoke5.az.corp - 10.5.0.5 -OK 21.178 ms
icanhazip.com - 104.18.114.97 -NA
```

### 3. Curl DNS

This script uses curl to check reachability of the web servers (python Flask) on the test virtual machines. It reports HTTP response message, round trip time and IP address.

**3.1.** Run the DNS curl test

```sh
curl-dns
```

Sample output

```sh
azureuser@Ne32-spoke1Vm:~$ curl-dns

 curl dns ...

200 (0.041713s) - 10.10.0.5 - vm.branch1.corp
200 (0.024691s) - 10.11.0.5 - vm.hub1.az.corp
200 (0.016803s) - 10.11.7.4 - spoke3.p.hub1.az.corp
[ 2781.033692] cloud-init[1639]: 10.1.0.5 - - [27/Nov/2023 16:45:15] "GET / HTTP/1.1" 200 -
200 (0.008289s) - 10.1.0.5 - vm.spoke1.az.corp
200 (0.076840s) - 10.2.0.5 - vm.spoke2.az.corp
000 (2.001678s) -  - vm.spoke3.az.corp
200 (0.076715s) - 10.30.0.5 - vm.branch3.corp
200 (0.080706s) - 10.22.0.5 - vm.hub2.az.corp
200 (0.081588s) - 10.22.7.4 - spoke6.p.hub2.az.corp
200 (0.086362s) - 10.4.0.5 - vm.spoke4.az.corp
200 (0.081490s) - 10.5.0.5 - vm.spoke5.az.corp
000 (2.001136s) -  - vm.spoke6.az.corp
200 (0.033479s) - 104.18.115.97 - icanhazip.com
```

We can see that curl test to spoke3 virtual machine `vm.spoke3.we.az.corp` returns a ***000*** HTTP response code. This is expected since there is no Vnet peering from ***spoke3*** to ***hub1***. However, ***spoke3*** web application is reachable via Private Link Service private endpoint in ***hub1*** `spoke3pls.eu.az.corp`. The same explanation applies to ***spoke6*** virtual machine `vm.spoke6.ne.az.corp`

### 4. Private Link Service

**4.1.** Test access to ***spoke3*** web application using the private endpoint in ***hub1***.

```sh
curl spoke3pls.eu.az.corp
```

Sample output

```sh
azureuser@Ne32-spoke1Vm:~$ curl spoke3pls.eu.az.corp
{
  "Headers": {
    "Accept": "*/*",
    "Host": "spoke3.p.hub1.az.corp",
    "User-Agent": "curl/7.68.0"
  },
  "Hostname": "Ne32-spoke3-vm",
  "Local-IP": "10.3.0.5",
  "Remote-IP": "10.3.6.4"
}
```

**4.2.** Test access to ***spoke6*** web application using the private endpoint in ***hub2***.

```sh
curl spoke6pls.us.az.corp
```

Sample output

```sh
azureuser@Ne32-spoke1Vm:~$ curl spoke6pls.us.az.corp
{
  "Headers": {
    "Accept": "*/*",
    "Host": "spoke6.p.hub2.az.corp",
    "User-Agent": "curl/7.68.0"
  },
  "Hostname": "Ne32-spoke6-vm",
  "Local-IP": "10.6.0.5",
  "Remote-IP": "10.6.6.4"
}
```

The `Hostname` and `Local-IP` fields identifies the actual web servers - in this case ***spoke3*** and ***spoke6*** virtual machines. The `Remote-IP` fields (as seen by the web servers) are IP addresses in the Private Link Service NAT subnets in ***spoke3*** and ***spoke6*** respectively.

### 5. Private Link (App Service) Access from Public Client

App service instances are deployed for ***spoke3*** and ***spoke6***. The app service instance is a fully managed PaaS service. In this lab, the services are linked to ***spoke3*** and ***spoke6***. By using [Virtual Network integration](https://learn.microsoft.com/en-us/azure/app-service/overview-vnet-integration#regional-virtual-network-integration), the app services are deployed in dedicated ***AppServiceSubnet*** subnets in ***spoke3*** and ***spoke6***. This allows each app service to access private resources through their linked spoke Vnet.

The app services are accessible via the private endpoints in ***hub1*** and ***hub2*** respectively. The app services are also accessible via their public endpoints. The app service application is a simple [python Flask web application](https://hub.docker.com/r/ksalawu/web) that returns the HTTP headers, hostname and IP addresses of the server running the application.

The app services have the following naming convention:

- ne32-spoke3-AAAA.azurewebsites.net
- ne32-spoke6-BBBB.azurewebsites.net

Where ***AAAA*** and ***BBBB*** are randomly generated two-byte strings.

**5.1.** On your Cloudshell (or local machine), get the hostname of the app service linked to ***spoke3***

```sh
spoke3_apps_url=$(az webapp list --resource-group Ne32RG --query "[?contains(name, 'ne32-spoke3')].defaultHostName" -o tsv)
```

**5.2.** Display the hostname
```sh
echo $spoke3_apps_url
```

Sample output (your result will be different)

```sh
ne32-spoke3-12bd.azurewebsites.net
```

**5.3.** Resolve the hostname

```sh
nslookup $spoke3_apps_url
```

Sample output (your result will be different)

```sh
2-hub-spoke-azfw-dual-region$ nslookup $spoke3_apps_url
Server:         172.19.64.1
Address:        172.19.64.1#53

Non-authoritative answer:
ne32-spoke3-12bd.azurewebsites.net  canonical name = ne32-spoke3-12bd-app.privatelink.azurewebsites.net.
ne32-spoke3-12bd-app.privatelink.azurewebsites.net      canonical name = waws-prod-am2-603.sip.azurewebsites.windows.net.
waws-prod-am2-603.sip.azurewebsites.windows.net canonical name = waws-prod-am2-603-2ca0.westeurope.cloudapp.azure.com.
Name:   waws-prod-am2-603-2ca0.westeurope.cloudapp.azure.com
Address: 20.105.224.16
```

We can see that the endpoint is a public IP address, ***20.105.224.16***. We can see the CNAME `ne32-spoke3-12bd-app.privatelink.azurewebsites.net` created for the app service which recursively resolves to the public IP address.

**5.4.** Test access to the ***spoke3*** app service via the public endpoint.

```sh
curl $spoke3_apps_url
```

Sample output

```sh
2-hub-spoke-azfw-dual-region$ curl $spoke3_apps_url
{
  "Headers": {
    "Accept": "*/*",
    "Client-Ip": "152.37.70.253:4796",
    "Disguised-Host": "ne32-spoke3-12bd.azurewebsites.net",
    "Host": "ne32-spoke3-12bd.azurewebsites.net",
    "Max-Forwards": "10",
    "User-Agent": "curl/7.74.0",
    "Was-Default-Hostname": "ne32-spoke3-12bd.azurewebsites.net",
    "X-Arr-Log-Id": "081cb271-2ad7-48c6-b1e3-5a8cccd8cbc5",
    "X-Client-Ip": "152.37.70.253",
    "X-Client-Port": "4796",
    "X-Forwarded-For": "152.37.70.253:4796",
    "X-Original-Url": "/",
    "X-Site-Deployment-Id": "ne32-spoke3-12bd-app",
    "X-Waws-Unencoded-Url": "/"
  },
  "Hostname": "d8f64fa4d4c5",
  "Local-IP": "169.254.129.2",
  "Remote-IP": "169.254.129.1"
}
```

Observe that we are connecting from our local client's public IP address specified in the `X-Client-Ip`.

**(Optional)** Repeat *Step 5.1* through *Step 5.4* for the app service linked to ***spoke6***.

### 6. Private Link (App Service) Access from On-premises

**6.1** Recall the hostname of the app service in ***spoke3*** as done in *Step 5.2*. In this lab deployment, the hostname is `ne32-spoke3-12bd.azurewebsites.net`.

**6.2.** Connect to the on-premises server `Ne32-branch1Vm` [using the serial console](https://learn.microsoft.com/en-us/troubleshoot/azure/virtual-machines/serial-console-overview#access-serial-console-for-virtual-machines-via-azure-portal). We will test access from `Ne32-branch1Vm` to the app service for ***spoke3*** via the private endpoint in ***hub1***.

**6.3.** Resolve the hostname DNS - which is `ne32-spoke3-12bd.azurewebsites.net` in this example. Use your actual hostname from *Step 6.1*.

```sh
nslookup ne32-spoke3-<AAAA>.azurewebsites.net
```

Sample output

```sh
azureuser@Ne32-branch1Vm:~$ nslookup ne32-spoke3-12bd.azurewebsites.net
Server:         127.0.0.53
Address:        127.0.0.53#53

Non-authoritative answer:
ne32-spoke3-12bd.azurewebsites.net  canonical name = ne32-spoke3-12bd-app.privatelink.azurewebsites.net.
Name:   ne32-spoke3-12bd-app.privatelink.azurewebsites.net
Address: 10.11.7.5
```

We can see that the app service hostname resolves to the private endpoint ***10.11.7.5*** in ***hub1***. The following is a summary of the DNS resolution from `Ne32-branch1Vm`:

- On-premises server `Ne32-branch1Vm` makes a DNS request for `ne32-spoke3-12bd.azurewebsites.net`
- The request is received by on-premises DNS server `Ne32-branch1-dns`
- The DNS server resolves `ne32-spoke3-12bd.azurewebsites.net` to the CNAME `ne32-spoke3-12bd-app.privatelink.azurewebsites.net`
- The DNS server has a conditional DNS forwarding defined in the [unbound DNS configuration file](./output/branch-unbound.sh).

  ```sh
  forward-zone:
          name: "privatelink.azurewebsites.net."
          forward-addr: 10.11.8.4
          forward-addr: 10.22.8.4
  ```

  DNS Requests matching `privatelink.azurewebsites.net` will be forwarded to the private DNS resolver inbound endpoint in ***hub1*** (10.11.8.4). The DNS resolver inbound endpoint for ***hub2*** (10.22.8.4) is also included for redundancy.
- The DNS server forwards the DNS request to the private DNS resolver inbound endpoint in ***hub1*** - which returns the IP address of the app service private endpoint in ***hub1*** (10.11.7.5)

**6.4.** From `Ne32-branch1Vm`, test access to the ***spoke3*** app service via the private endpoint. Use your actual hostname.

```sh
curl ne32-spoke3-<AAAA>.azurewebsites.net
```

Sample output

```sh
azureuser@Ne32-branch1Vm:~$ curl ne32-spoke3-12bd.azurewebsites.net
{
  "Headers": {
    "Accept": "*/*",
    "Client-Ip": "[fd40:8400:12:2717:7512:900:a0a:5]:36948",
    "Disguised-Host": "ne32-spoke3-12bd.azurewebsites.net",
    "Host": "ne32-spoke3-12bd.azurewebsites.net",
    "Max-Forwards": "10",
    "User-Agent": "curl/7.68.0",
    "Was-Default-Hostname": "ne32-spoke3-12bd.azurewebsites.net",
    "X-Arr-Log-Id": "1c8fba21-cc70-43b5-bca7-551531920b04",
    "X-Client-Ip": "10.10.0.5",
    "X-Client-Port": "0",
    "X-Forwarded-For": "10.10.0.5",
    "X-Original-Url": "/",
    "X-Site-Deployment-Id": "ne32-spoke3-12bd-app",
    "X-Waws-Unencoded-Url": "/"
  },
  "Hostname": "d8f64fa4d4c5",
  "Local-IP": "169.254.129.2",
  "Remote-IP": "169.254.129.1"
}
```

Observe that we are connecting from the private IP address of `Ne32-branch1Vm` (10.10.0.5) specified in the `X-Client-Ip`.

### 7. On-premises Routes

Login to the onprem router `Ne32-branch1Nva` in order to observe its dynamic routes.

**7.1.** Login to virtual machine `Ne32-branch1Nva` via the [serial console](https://learn.microsoft.com/en-us/troubleshoot/azure/virtual-machines/serial-console-overview#access-serial-console-for-virtual-machines-via-azure-portal).

**7.2.** Enter username and password

   - username = ***azureuser***
   - password = ***Password123***

**7.3.** Enter the Cisco enable mode

```sh
enable
```

**7.4.** Display the routing table by typing `show ip route` and pressing the space bar to show the complete output.

```sh
show ip route
```

Sample output

```sh
Ne32-branch1Nva#show ip route
...
[Truncated for brevity]
...
Gateway of last resort is 10.10.1.1 to network 0.0.0.0

S*    0.0.0.0/0 [1/0] via 10.10.1.1
      10.0.0.0/8 is variably subnetted, 20 subnets, 4 masks
B        10.1.0.0/16 [20/0] via 10.11.10.4, 00:29:26
B        10.2.0.0/16 [20/0] via 10.11.10.4, 00:29:26
B        10.4.0.0/16 [20/0] via 192.168.30.30, 00:29:16
B        10.5.0.0/16 [20/0] via 192.168.30.30, 00:29:16
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
B        10.11.0.0/16 [20/0] via 10.11.10.4, 00:29:26
S        10.11.10.4/32 is directly connected, Tunnel0
S        10.11.10.5/32 is directly connected, Tunnel1
B        10.22.0.0/16 [20/0] via 192.168.30.30, 00:29:16
B        10.30.0.0/24 [20/0] via 192.168.30.30, 00:29:16
      168.63.0.0/32 is subnetted, 1 subnets
S        168.63.129.16 [254/0] via 10.10.1.1
      169.254.0.0/32 is subnetted, 1 subnets
S        169.254.169.254 [254/0] via 10.10.1.1
      192.168.10.0/32 is subnetted, 1 subnets
C        192.168.10.10 is directly connected, Loopback0
      192.168.30.0/32 is subnetted, 1 subnets
S        192.168.30.30 is directly connected, Tunnel2
```

We can see the hub and spoke Vnet ranges are learned dynamically via BGP.

**7.5.** Display BGP information by typing `show ip bgp`.

```sh
show ip bgp
```

Sample output

```sh
Ne32-branch1Nva#show ip bgp
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

We can see the hub and spoke Vnet ranges being learned dynamically in the BGP table.

### 8. Azure Firewall

**8.1.** Check the Azure Firewall logs to observe the traffic flow.

- Select the Azure Firewall resource `Ne32-hub1-azfw` in the Azure portal.
- Click on **Logs** in the left navigation pane.
- Click on **Firewall Logs (Resource Specific Tables)**.
- Click on **Run** in the log category *Network rule logs*.

![Ne32-hub1-azfw-network-rule-log](../../images/demos/ne32-hub1-net-rule-log.png)

Observe the firewall logs based on traffic flows generated from our tests.

![Ne32-hub1-azfw-network-rule-log-data](../../images/demos/ne32-hub1-net-rule-log-detail.png)

**8.2** Repeat the same steps for the Azure Firewall resource `Ne32-hub2-azfw`.

## Cleanup

1. (Optional) Navigate back to the lab directory (if you are not already there)

   ```sh
   cd azure-network-terraform/3-network-manager/2-hub-spoke-azfw-dual-region
   ```

2. In order to avoid terraform errors when re-deploying this lab, run a cleanup script to remove diagnostic settings that may not be removed after the resource group is deleted.

   ```sh
   bash ../../scripts/_cleanup.sh Ne32
   ```

   Sample output

   ```sh
   2-hub-spoke-azfw-dual-region$    bash ../../scripts/_cleanup.sh Ne32

   Resource group: Ne32RG

   ⏳ Checking for diagnostic settings on resources in Ne32RG ...
   ➜  Checking firewall ...
       ❌ Deleting: diag setting [Ne32-hub1-azfw-diag] for firewall [Ne32-hub1-azfw] ...
       ❌ Deleting: diag setting [Ne32-hub2-azfw-diag] for firewall [Ne32-hub2-azfw] ...
   ➜  Checking vnet gateway ...
       ❌ Deleting: diag setting [Ne32-hub1-vpngw-diag] for vnet gateway [Ne32-hub1-vpngw] ...
       ❌ Deleting: diag setting [Ne32-hub2-vpngw-diag] for vnet gateway [Ne32-hub2-vpngw] ...
   ➜  Checking vpn gateway ...
   ➜  Checking er gateway ...
   ➜  Checking app gateway ...
   ⏳ Checking for azure policies in Ne32RG ...
       ❌ Deleting: policy assignment [Ne32-ng-spokes-prod-region1] ...
       ❌ Deleting: policy definition [Ne32-ng-spokes-prod-region1] ...
       ❌ Deleting: policy assignment [Ne32-ng-spokes-prod-region2] ...
       ❌ Deleting: policy definition [Ne32-ng-spokes-prod-region2] ...
   Done!
   ```

3. Delete the resource group to remove all resources installed.

   ```sh
   az group delete -g Ne32RG --no-wait
   ```

4. Delete terraform state files and other generated files.

   ```sh
   rm -rf .terraform*
   rm terraform.tfstate*
   ```
