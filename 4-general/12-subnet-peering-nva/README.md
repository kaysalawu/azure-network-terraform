# Hub and Spoke - Dual Region (NVA) <!-- omit from toc -->

## Lab: Lab12 <!-- omit from toc -->

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
  - [4. Network Virtual Appliance (NVA)](#4-network-virtual-appliance-nva)
  - [5. On-premises Routes](#5-on-premises-routes)
  - [6. Subnet Peering of NVA Subnets](#6-subnet-peering-of-nva-subnets)
- [Cleanup](#cleanup)

## Overview

The lab demonstrates how subnet peering can be used to filter prefixes reachable by the VNets to create a more secure network architecture. In this scenario, we have two VNet hubs routing traffic via network virtual appliances (NVA). Subnet peering is used to expose only the NVA subnets in both VNets to each other. This keeps the network architecture more secure as we do not expose all Vnet prefixes but only the NVA subnets which contain the next hop IP for all traffic forwarding on both hubs.

<img src="./images/architecture.png" alt="Hub and Spoke (Dual region)" width="1000">
<p>

***Hub1*** represents a service provider-managed Vnet hub that has a Virtual Network Appliance (NVA) used for inspection of traffic between an on-premises branch and customer Vnets (***hub2*** and ***spoke4***). User-Defined Routes (UDR) are used to influence the hub Vnet data plane to route traffic between the branch and spokes via the NVA.

Similarly, ***hub2*** represents a customer hub that an NVA used for inspection of traffic between customer spokes. In this example we only have one spoke ***spoke4*** that needs to communicate with resources in the provider hub ***hub1***.

The hubs are connected together via subnet peering to allow inter-hub network reachability.

***Branch1*** is an on-premises network simulated using a VNet. A Multi-NIC Linux NVA appliance connects to the service-provider managed network using IPsec VPN connections with dynamic (BGP) routing.

## Prerequisites

Ensure you meet all requirements in the [prerequisites](../../prerequisites/README.md) before proceeding.

## Deploy the Lab

1. Clone the Git Repository for the Labs

   ```sh
   git clone https://github.com/kaysalawu/azure-network-terraform.git
   ```

2. Navigate to the lab directory

   ```sh
   cd azure-network-terraform/4-general/12-subnet-peering-nva
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

The table below shows the auto-generated output files from the lab. They are located in the [**output**](./output/) directory.

| Item    | Description  | Location |
|--------|--------|--------|
| IP ranges and DNS | IP ranges and DNS hostname values | [output/values.md](./output/values.md) |
| Branch1 DNS | Authoritative DNS and forwarding | [output/branch1Dns.sh](./output/branch1Dns.sh) |
| Branch1 NVA | Linux Strongswan + FRR configuration | [output/branch1Nva.sh](./output/branch1Nva.sh) |
| (Optional) Hub1 Linux NVA | Linux NVA configuration | [output/hub1-linux-nva.sh](./output/hub1-linux-nva.sh) |
| (Optional) Hub2 Linux NVA | Linux NVA configuration | [output/hub2-linux-nva.sh](./output/hub2-linux-nva.sh) |
| Web server | Python Flask web server, test scripts | [output/server.sh](./output/server.sh) |
||||

## Testing

Each virtual machine is pre-configured with a shell [script](../../scripts/server.sh) to run various types of network reachability tests. Serial console access has been configured for all virtual machines.

Login to virtual machine `Lab12-spoke4Vm` via the [serial console](https://learn.microsoft.com/en-us/troubleshoot/azure/virtual-machines/serial-console-overview#access-serial-console-for-virtual-machines-via-azure-portal):

- On Azure portal select *Virtual machines*
- Select the virtual machine `Lab12-spoke4Vm`
- Under ***Help*** section, select ***Serial console*** and wait for a login prompt
- Enter the login credentials
  - username = ***azureuser***
  - password = ***Password123***
- You should now be in a shell session `azureuser@Lab12-spoke4Vm:~$`

</details>
<p>

Run the following tests from inside the serial console session.

### 1. Ping IP

This script pings the IP addresses of some test virtual machines and reports reachability and round trip time.

**1.1.** Run the IP ping tests

```sh
ping-ipv4
```

<details>

<summary>Sample output</summary>

```sh

```

```sh

```

**Branch1** is not reachable via IPv6 as Azure firewall and VPN gateway currently do not support IPv6.

</details>
<p>

### 2. Ping DNS

This script pings the DNS name of some test virtual machines and reports reachability and round trip time. This tests hybrid DNS resolution between on-premises and Azure.

**2.1.** Run the DNS ping tests

```sh
ping-dns4
```

<details>

<summary>Sample output</summary>

```sh

```

```sh

```

</details>
<p>

### 3. Curl DNS

This script uses curl to check reachability of web server (python Flask) on the test virtual machines. It reports HTTP response message, round trip time and IP address.

**3.1.** Run the DNS curl test

```sh
curl-dns4
```

<details>

<summary>Sample output</summary>

```sh

```

```sh

```

</details>
<p>

### 4. Network Virtual Appliance (NVA)

Whilst still logged into the on-premises server `Lab12-branch1Vm` via the serial console, we will test connectivity to all virtual machines using a `trace-ip` script using the linux `tracepath` utility.

**4.1.** Run the `trace-ip` script

```sh
trace-ip
```

<details>

<summary>Sample output</summary>

```sh

```

</details>
<p>

We can observe that traffic to ***spoke1***, ***spoke2*** and ***hub1*** flow symmetrically via the NVA in ***hub1*** (10.11.1.4).
Similarly, traffic to ***spoke4***, ***spoke5*** and ***hub2*** flow symmetrically via the NVA in ***hub2*** (10.22.1.4).

### 5. On-premises Routes

**5.1** Login to on-premises virtual machine `Lab12-branch1Nva` via the [serial console](https://learn.microsoft.com/en-us/troubleshoot/azure/virtual-machines/serial-console-overview#access-serial-console-for-virtual-machines-via-azure-portal):
  - username = ***azureuser***
  - password = ***Password123***

**5.2.** Enter the VTY shell for the FRRouting daemon.

```sh
sudo vtysh
```

<details>

<summary>Sample output</summary>

```sh
azureuser@branch1Nva:~$ sudo vtysh

Hello, this is FRRouting (version 7.2.1).
Copyright 1996-2005 Kunihiro Ishiguro, et al.
```

</details>
<p>

**5.3.** Display the routing table by typing `show ip route` and pressing the space bar to show the complete output.

```sh
show ip route
```

<details>

<summary>Sample output</summary>

```sh

```

We can see the Vnet ranges learned dynamically via BGP.

```sh

```

IPv6 is not yet configured for BGP but we can see static and connected IPv6 routes.

</details>
<p>

**5.4.** Display BGP information by typing `show ip bgp` and pressing the space bar to show the complete output.

```sh
show ip bgp
```

<details>

<summary>Sample output</summary>

```sh

```

We can see the hub and spoke Vnet ranges being learned dynamically in the BGP table.

</details>
<p>

**5.5.** Exit the vtysh shell by typing `exit` and pressing `Enter`.

```sh
exit
```

### 6. Subnet Peering of NVA Subnets

We will set up subnet peering to allow only the NVA subnets (`TrustSubnet`) of the remote hub Vnet is exposed to the other hub Vnet. In particular,`Lab12-hub2-vnet` should only be able to reach `TrustSubnet` of `Lab12-hub1-vnet`. Similarly, `Lab12-hub1-vnet` should only be able to reach `TrustSubnet` of `Lab12-hub2-vnet`.

The script [subnet-peering.sh](../../scripts/subnet-peering.sh) contains the functions to create the subnet peerings.

**2.1** Create hub and spoke subnet peerings for only the **NvaSubnet** in ***hub1*** and ***hub2***.

```sh
source subnet-peering.sh
create_subnet_peering Lab12_Subnet_Peering_RG Lab12-hub1-vnet Lab12-hub2-vnet NvaSubnet
create_subnet_peering Lab12_Subnet_Peering_RG Lab12-hub2-vnet Lab12-hub1-vnet NvaSubnet
```

<details>

<summary>API Response</summary>

Subnet peering from `Lab12-hub1-vnet` to `Lab12-hub2-vnet`

```sh
12-subnet-peering-nva$ create_subnet_peering Lab12_Subnet_Peering_RG Lab12-hub1-vnet Lab12-hub2-vnet NvaSubnet
{
  "name": "sub--Lab12-hub1-vnet--Lab12-hub2-vnet",
  "id": "/subscriptions/b120edff-2b3e-4896-adb7-55d2918f337f/resourceGroups/Lab12_Subnet_Peering_RG/providers/Microsoft.Network/virtualNetworks/Lab12-hub1-vnet/virtualNetworkPeerings/sub--Lab12-hub1-vnet--Lab12-hub2-vnet",
  "etag": "W/\"cdfd08c4-ab4a-40e5-ab2b-aaef69b5e0fc\"",
  "properties": {
    "provisioningState": "Updating",
    "resourceGuid": "71d295f1-c84f-0354-3d8c-e18edeae7bd0",
    "localSubnetNames": [
      "UntrustSubnet"
    ],
    "remoteSubnetNames": [
      "UntrustSubnet"
    ],
    "peeringState": "Initiated",
    "peeringSyncLevel": "RemoteNotInSync",
    "remoteVirtualNetwork": {
      "id": "/subscriptions/b120edff-2b3e-4896-adb7-55d2918f337f/resourceGroups/Lab12_Subnet_Peering_RG/providers/Microsoft.Network/virtualNetworks/Lab12-hub2-vnet"
    },
    "allowVirtualNetworkAccess": true,
    "allowForwardedTraffic": true,
    "allowGatewayTransit": false,
    "useRemoteGateways": false,
    "doNotVerifyRemoteGateways": false,
    "peerCompleteVnets": false,
    "enableOnlyIPv6Peering": false,
    "remoteAddressSpace": {
      "addressPrefixes": [
        "10.22.1.0/24"
      ]
    },
    "localAddressSpace": {
      "addressPrefixes": [
        "192.168.4.0/24"
      ]
    },
    "localVirtualNetworkAddressSpace": {
      "addressPrefixes": [
        "192.168.4.0/24"
      ]
    },
    "remoteVirtualNetworkAddressSpace": {
      "addressPrefixes": [
        "10.22.1.0/24"
      ]
    },
    "remoteBgpCommunities": {
      "virtualNetworkCommunity": "12076:20022",
      "regionalCommunity": "12076:50003"
    },
    "routeServiceVips": {}
  },
  "type": "Microsoft.Network/virtualNetworks/virtualNetworkPeerings"
}
```

Subnet peering from `Lab12-hub2-vnet` to `Lab12-hub1-vnet`

```sh
12-subnet-peering-nva$ create_subnet_peering Lab12_Subnet_Peering_RG Lab12-hub2-vnet Lab12-hub1-vnet NvaSubnet
{
  "name": "sub--Lab12-hub2-vnet--Lab12-hub1-vnet",
  "id": "/subscriptions/b120edff-2b3e-4896-adb7-55d2918f337f/resourceGroups/Lab12_Subnet_Peering_RG/providers/Microsoft.Network/virtualNetworks/Lab12-hub2-vnet/virtualNetworkPeerings/sub--Lab12-hub2-vnet--Lab12-hub1-vnet",
  "etag": "W/\"1b5c2a7b-8ba7-49d9-8df2-3f92a688e185\"",
  "properties": {
    "provisioningState": "Updating",
    "resourceGuid": "71d295f1-c84f-0354-3d8c-e18edeae7bd0",
    "localSubnetNames": [
      "UntrustSubnet"
    ],
    "remoteSubnetNames": [
      "UntrustSubnet"
    ],
    "peeringState": "Connected",
    "peeringSyncLevel": "FullyInSync",
    "remoteVirtualNetwork": {
      "id": "/subscriptions/b120edff-2b3e-4896-adb7-55d2918f337f/resourceGroups/Lab12_Subnet_Peering_RG/providers/Microsoft.Network/virtualNetworks/Lab12-hub1-vnet"
    },
    "allowVirtualNetworkAccess": true,
    "allowForwardedTraffic": true,
    "allowGatewayTransit": false,
    "useRemoteGateways": false,
    "doNotVerifyRemoteGateways": false,
    "peerCompleteVnets": false,
    "enableOnlyIPv6Peering": false,
    "remoteAddressSpace": {
      "addressPrefixes": [
        "192.168.4.0/24"
      ]
    },
    "localAddressSpace": {
      "addressPrefixes": [
        "10.22.1.0/24"
      ]
    },
    "localVirtualNetworkAddressSpace": {
      "addressPrefixes": [
        "10.22.1.0/24"
      ]
    },
    "remoteVirtualNetworkAddressSpace": {
      "addressPrefixes": [
        "192.168.4.0/24"
      ]
    },
    "remoteBgpCommunities": {
      "virtualNetworkCommunity": "12076:20011",
      "regionalCommunity": "12076:50003"
    },
    "routeServiceVips": {}
  },
  "type": "Microsoft.Network/virtualNetworks/virtualNetworkPeerings"
}
```

</details>
<p>

**2.2** Check effective routes in **`hub1`**.

```sh
bash ../../scripts/_routes_nic.sh Lab12_Subnet_Peering_RG
```

```sh
12-subnet-peering-nva$ bash ../../scripts/_routes_nic.sh Lab12_Subnet_Peering_RG

Resource group: Lab12_Subnet_Peering_RG

Available NICs:
1. Lab12-branch1-dns-main
2. Lab12-branch1-nva-trust-nic
3. Lab12-branch1-nva-untrust-nic
4. Lab12-branch1-vm-main-nic
5. Lab12-hub1-cgs1-nic
6. Lab12-hub1-cgs2-nic
7. Lab12-hub1-nafvm-nic
8. Lab12-hub1-nonprodvm-nic
9. Lab12-hub1-nva-trust-nic
10. Lab12-hub1-nva-untrust-nic
11. Lab12-hub1-prodhavm-nic
12. Lab12-hub1-prodvm-nic
13. Lab12-hub2-nva-trust-nic
14. Lab12-hub2-nva-untrust-nic
15. Lab12-spoke4-vm-main-nic

Select NIC to view effective routes (enter the number)

Selection: 9

Effective routes for Lab12-hub1-nva-trust-nic

Source                 Prefix           State    NextHopType            NextHopIP
---------------------  ---------------  -------  ---------------------  -----------
Default                192.168.0.0/16   Active   VnetLocal
Default                10.22.2.0/24     Active   VNetPeering
VirtualNetworkGateway  10.10.0.0/24     Active   VirtualNetworkGateway  192.168.8.6
VirtualNetworkGateway  10.10.0.0/24     Active   VirtualNetworkGateway  192.168.8.7
VirtualNetworkGateway  172.16.10.10/32  Active   VirtualNetworkGateway  192.168.8.6
VirtualNetworkGateway  172.16.10.10/32  Active   VirtualNetworkGateway  192.168.8.7
Default                0.0.0.0/0        Active   Internet
```

We can see that the effective routes for `Lab12-hub1-nva-trust-nic` now only includes the NVA subnet of ***hub1*** (**10.22.2.0/24**) learned via subnet peering.

**2.3** Check effective routes in **`hub2`**.

```sh
bash ../../scripts/_routes_nic.sh Lab12_Subnet_Peering_RG
```

```sh
12-subnet-peering-nva$ bash ../../scripts/_routes_nic.sh Lab12_Subnet_Peering_RG

Resource group: Lab12_Subnet_Peering_RG

Available NICs:
1. Lab12-branch1-dns-main
2. Lab12-branch1-nva-trust-nic
3. Lab12-branch1-nva-untrust-nic
4. Lab12-branch1-vm-main-nic
5. Lab12-hub1-cgs1-nic
6. Lab12-hub1-cgs2-nic
7. Lab12-hub1-nafvm-nic
8. Lab12-hub1-nonprodvm-nic
9. Lab12-hub1-nva-trust-nic
10. Lab12-hub1-nva-untrust-nic
11. Lab12-hub1-prodhavm-nic
12. Lab12-hub1-prodvm-nic
13. Lab12-hub2-nva-trust-nic
14. Lab12-hub2-nva-untrust-nic
15. Lab12-spoke4-vm-main-nic

Select NIC to view effective routes (enter the number)

Selection: 13

Effective routes for Lab12-hub2-nva-trust-nic

Source    Prefix          State    NextHopType
--------  --------------  -------  -------------
Default   10.22.0.0/16    Active   VnetLocal
Default   10.4.0.0/16     Active   VNetPeering
Default   192.168.5.0/24  Active   VNetPeering
Default   0.0.0.0/0       Active   Internet
```

We can see that the effective routes for `Lab12-hub2-nva-trust-nic` now only includes the NVA subnet of ***hub2*** (**192.168.5.0/24**) learned via subnet peering. In contrast, the peering to ***spoke4*** is a standard Vnet peering that shows the entire Vnet CIDR prefix (**10.4.0.0/16**) of **spoke4**.

## Cleanup

1\. (Optional) Navigate back to the lab directory (if you are not already there)

```sh
cd azure-network-terraform/4-general/12-subnet-peering-nva
```

2\. (Optional) This is not required if `enable_diagnostics = false` in the [`main.tf`](./02-main.tf). If you deployed the lab with `enable_diagnostics = true`, in order to avoid terraform errors when re-deploying this lab, run a cleanup script to remove diagnostic settings that are not removed after the resource group is deleted.

```sh
bash ../../scripts/_cleanup.sh Lab12_Subnet_Peering_RG
```

<details>

<summary>Sample output</summary>

```sh
cking for azure policies in Lab12_Subnet_Peering_RG ...
Done!
```

</details>
<p>

3\. Delete the subnet peerings

```sh
source subnet-peering.sh
delete_subnet_peering Lab12_Subnet_Peering_RG Lab12-hub1-vnet Lab12-hub2-vnet NvaSubnet
delete_subnet_peering Lab12_Subnet_Peering_RG Lab12-hub2-vnet Lab12-hub1-vnet NvaSubnet
```

4\. Delete the resource group to remove all resources installed.

```sh
az group delete -g Lab12_Subnet_Peering_RG --no-wait
```

5\. Delete terraform state files and other generated files.

```sh
rm -rf .terraform*
rm terraform.tfstate*
```
