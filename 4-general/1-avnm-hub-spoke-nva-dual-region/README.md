
# Virtual Network Manager (Hub and Spoke) - Dual Region <!-- omit from toc -->
## Poc1 <!-- omit from toc -->

This POC deploys a dual region hub and spoke architecture using Azure Virtual Network Manager.

![POC1)](./images/scenarios/../../../../images/poc/poc1-avnm-hub-spoke-nva-dual-regions.png)

### DNS
- Private DNS Zone per region

### Spokes
- Spoke1, Spoke2, Spoke4 and Spoke5 use  UDR (0.0.0.0/0)  NVA in the Hub
- Spoke3 and Spoke6 are isolated Vnets with PrivateLink services


### Hubs
- NVA for inspecting spoke and branch traffic
- UDR on Hub gateway subnet to direct traffic coming from on-premises to the NVA
- Private DNS resolver with rulesets for onprem DNS resolution
- Private Link Endpoint (consumer)


### Onprem
- Cisco router running IPsec VPN + BGP routing
- DNS server with conditional forwarding to Azure
