# Secured Virtual WAN - Single Region <!-- omit from toc -->

## Lab: Vwan23 <!-- omit from toc -->

Contents

- [Overview](#overview)
- [Prerequisites](#prerequisites)
- [Deploy the Lab](#deploy-the-lab)
- [Troubleshooting](#troubleshooting)
- [Outputs](#outputs)
- [Testing](#testing)
  - [1. Verify ExpressRoute Circuit Routes](#1-verify-expressroute-circuit-routes)
  - [2. Get the Virtual WAN Effective Routes](#2-get-the-virtual-wan-effective-routes)
  - [3. Deploy Azure Route Server (ARS) in Branch2](#3-deploy-azure-route-server-ars-in-branch2)
- [Cleanup](#cleanup)

## Overview

This lab deploys a single-region Secured Virtual WAN (Vwan) topology to test ExpressRoute Microsoft Enterprise Edge (MSEE) hairpinning. Hairpinning will be tested from **Branch2** Vnet into the virtual WAN hub **vHub1**. The lab build directly on the lab [3-vwan-sec-single-region](../../2-virtual-wan/3-vwan-sec-single-region/) by adding **Branch2** and ExpressRoute circuit using Megaport. All instructions from the previous lab apply to this lab.

**Branch2** has an Azure Route Server (ARS) which has a BGP conneciton to a Network Virtual Appliance (NVA). The NVA advertises test prefixes **5.5.5.5/32** and **6.6.6.6/32** which will be observed in the virtual WAN hub **vHub1**.

## Prerequisites

Ensure you meet all requirements in the [prerequisites](../../prerequisites/README.md) before proceeding. You will need a Megaport account to run this lab.

## Deploy the Lab

1. Clone the Git Repository for the Labs

   ```sh
   git clone https://github.com/kaysalawu/azure-network-terraform.git
   ```

2. Navigate to the lab directory

   ```sh
   cd azure-network-terraform/4-general/13-vwan-er-hairpin
   ```

3. (Optional) If you want to enable additional features such as IPv6, Vnet flow logs and logging set the following variables to `true` in the [`main.tf`](./02-main.tf) file.

   | Variable | Description | Default | Link |
   |----------|-------------|---------|------|
   | enable_diagnostics | Enable Azure Monitor diagnostics | false | [main.tf](./02-main.tf#L9) |
   | enable_ipv6 | Enable IPv6 on all supported resources | false | [main.tf](./02-main.tf#L10) |
   | enable_flow_logs | Enable Vnet flow logs in the Vnet hubs | false | [main.tf](./02-main.tf#L11) |
   ||||

4. Run the following terraform commands and type ***yes*** at the prompt:

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
| Branch1 DNS | Authoritative DNS and forwarding | [output/branch1Dns.sh](./output/branch1Dns.sh) |
| Branch2 DNS | Authoritative DNS and forwarding | [output/branch2Dns.sh](./output/branch2Dns.sh) |
| Branch1 NVA | Linux Strongswan + FRR configuration | [output/branch1Nva.sh](./output/branch1Nva.sh) |
| Hub1 NVA | Linux NVA configuration | [output/hub1-linux-nva.sh](./output/hub1-linux-nva.sh) |
| Web server | Python Flask web server, test scripts | [output/server.sh](./output/server.sh) |
||||

## Testing

Run some test to verify virtual WAN routes for **Branch2** through the ExpressRoute circuit hairpinning.

### 1. Verify ExpressRoute Circuit Routes

```sh
bash ../../scripts/vnet-gateway/get_er_route_tables.sh Lab13_Vnet_Vwan_Er_Hairpin_RG
```

Sample output:

```sh
⏳ AzurePrivatePeering (Primary): Lab13-er1
LocPrf    Network          NextHop         Path           Weight
--------  ---------------  --------------  -------------  --------
100       5.5.5.5/32       10.20.16.13*    65515 65002 I  0
100       5.5.5.5/32       10.20.16.12     65515 65002 I  0
100       6.6.6.6/32       10.20.16.13*    65515 65002 I  0
100       6.6.6.6/32       10.20.16.12     65515 65002 I  0
100       10.1.0.0/16      192.168.11.15*  65515 I        0
100       10.1.0.0/16      192.168.11.14   65515 I        0
100       10.2.0.0/16      192.168.11.15*  65515 65010 I  0
100       10.2.0.0/16      192.168.11.14   65515 65010 I  0
100       10.10.0.0/24     192.168.11.15*  65515 65001 I  0
100       10.10.0.0/24     192.168.11.14   65515 65001 I  0
100       10.11.0.0/16     192.168.11.15*  65515 I        0
100       10.11.0.0/16     192.168.11.14   65515 I        0
100       10.20.0.0/16     10.20.16.13*    65515 I        0
100       10.20.0.0/16     10.20.16.12     65515 I        0
100       192.168.11.0/24  192.168.11.15*  65515 I        0
100       192.168.11.0/24  192.168.11.14   65515 I        0

⏳ AzurePrivatePeering (Secondary): Lab13-er1
LocPrf    Network          NextHop         Path           Weight
--------  ---------------  --------------  -------------  --------
100       5.5.5.5/32       10.20.16.13*    65515 65002 I  0
100       5.5.5.5/32       10.20.16.12     65515 65002 I  0
100       6.6.6.6/32       10.20.16.13*    65515 65002 I  0
100       6.6.6.6/32       10.20.16.12     65515 65002 I  0
100       10.1.0.0/16      192.168.11.15*  65515 I        0
100       10.1.0.0/16      192.168.11.14   65515 I        0
100       10.2.0.0/16      192.168.11.14*  65515 65010 I  0
100       10.2.0.0/16      192.168.11.15   65515 65010 I  0
100       10.10.0.0/24     192.168.11.15*  65515 65001 I  0
100       10.10.0.0/24     192.168.11.14   65515 65001 I  0
100       10.11.0.0/16     192.168.11.15*  65515 I        0
100       10.11.0.0/16     192.168.11.14   65515 I        0
100       10.20.0.0/16     10.20.16.13*    65515 I        0
100       10.20.0.0/16     10.20.16.12     65515 I        0
100       192.168.11.0/24  192.168.11.15*  65515 I        0
100       192.168.11.0/24  192.168.11.14   65515 I        0
⭐ Done!
```

The ExpressRoute circuit routing table learns about the **Branch2** route (**10.20.0.0/16**) from the gateway connection.

### 2. Get the Virtual WAN Effective Routes

```sh
bash ../../scripts/_routes_vwan.sh Lab13_Vnet_Vwan_Er_Hairpin_RG
```

Sample output:

```sh
vHub:       Lab13-vhub1-hub
RouteTable: defaultRouteTable
-------------------------------------------------------

AddressPrefixes    NextHopType
-----------------  --------------
0.0.0.0/0          Azure Firewall
10.0.0.0/8         Azure Firewall
172.16.0.0/12      Azure Firewall
192.168.0.0/16     Azure Firewall


vHub:     Lab13-vhub1-hub
Firewall: Lab13-vhub1-azfw
-------------------------------------------------------

AddressPrefixes    AsPath             NextHopType
-----------------  -----------------  --------------------------
10.10.0.0/24       65001              VPN_S2S_Gateway
10.2.0.0/16        65010              HubBgpConnection
10.1.0.0/16                           Virtual Network Connection
10.11.0.0/16                          Virtual Network Connection
10.20.0.0/16       12076-12076-12076  ExpressRouteGateway
0.0.0.0/0                             Internet
```

The **Branch2** routes (**10.20.0.0/16**) are learned via the ExpressRoute gateway in the virtual WAN hub.

### 3. Deploy Azure Route Server (ARS) in Branch2

In the [03-branch2.tf](./03-branch2.tf#L39), set the variable `enable_ars = true` to deploy the Azure Route Server in **Branch2**.

Apply terraform to deploy the Azure Route Server.

```sh
terraform init
terraform plan
terraform apply -parallelism=50
```


## Cleanup

1\. (Optional) Navigate back to the lab directory (if you are not already there)

```sh
cd azure-network-terraform/2-virtual-wan/3-vwan-sec-single-region
```

2\. (Optional) This is not required if `enable_diagnostics = false` in the [`main.tf`](./02-main.tf). If you deployed the lab with `enable_diagnostics = true`, in order to avoid terraform errors when re-deploying this lab, run a cleanup script to remove diagnostic settings that are not removed after the resource group is deleted.

```sh
bash ../../scripts/_cleanup.sh Lab13_Vnet_Vwan_Er_Hairpin_RG
```

<details>

<summary>Sample output</summary>

```sh
13-vwan-er-hairpin$ bash ../../scripts/_cleanup.sh Lab13_Vnet_Vwan_Er_Hairpin_RG

Resource group: Lab13_Vnet_Vwan_Er_Hairpin_RG

⏳ Checking for diagnostic settings on resources in Lab13_Vnet_Vwan_Er_Hairpin_RG ...
➜  Checking firewall ...
➜  Checking vnet gateway ...
➜  Checking vpn gateway ...
➜  Checking er gateway ...
➜  Checking app gateway ...
➜  Checking NVA vm extensions ...
❌ Deleting: vm extension [MDE.Linux] for vm [Lab13-hub1-nva-0] ...
⏳ Checking for azure policies in Lab13_Vnet_Vwan_Er_Hairpin_RG ...
➜  Checking express route private peerings ...
Done!
```

</details>
<p>

3\. Set the local variable `deploy = false` in the file [`svc-er-vhub1-branch2.tf`](./svc-er-vhub1-branch2.tf#L3) and re-apply terraform to delete all ExpressRoute and Megaport resources.

```sh
terraform plan
terraform apply -parallelism=50
```

4\. Set the local variable `deploy = true` in the [`svc-er-vhub1-branch2.tf`](./svc-er-vhub1-branch2.tf#L3) to allow deployment on the next run.


5\. Delete the resource group to remove all resources installed.

```sh
az group delete -g Lab13_Vnet_Vwan_Er_Hairpin_RG --no-wait
```

6\. Delete terraform state files and other generated files.

```sh
rm -rf .terraform*
rm terraform.tfstate*
```
