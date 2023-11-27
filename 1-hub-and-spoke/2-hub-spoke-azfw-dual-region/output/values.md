

## branch1

| Item    | Value  |
|--------|--------|
| *Subnets*|        |
| DnsServerSubnet   | 10.10.3.0/24   |
| GatewaySubnet   | 10.10.4.0/24   |
| MainSubnet   | 10.10.0.0/24   |
| NvaExternalSubnet   | 10.10.1.0/24   |
| NvaInternalSubnet   | 10.10.2.0/24   |
| - | -  |
| VM_IP   | 10.10.0.5   |
| VM_NAME   | Hs12-branch1-vm   |
| VNET_NAME   | Hs12-branch1-vnet   |
| VNET_RANGES   | 10.10.0.0/16   |

## branch3

| Item    | Value  |
|--------|--------|
| *Subnets*|        |
| DnsServerSubnet   | 10.30.3.0/24   |
| GatewaySubnet   | 10.30.4.0/24   |
| MainSubnet   | 10.30.0.0/24   |
| NvaExternalSubnet   | 10.30.1.0/24   |
| NvaInternalSubnet   | 10.30.2.0/24   |
| - | -  |
| VM_IP   | 10.30.0.5   |
| VM_NAME   | Hs12-branch3-vm   |
| VNET_NAME   | Hs12-branch3-vnet   |
| VNET_RANGES   | 10.30.0.0/16   |

## hub1

| Item    | Value  |
|--------|--------|
| PRIVATE_DNS_INBOUND_IP   | 10.11.5.4   |
| SPOKE3_APP_SVC_ENDPOINT_DNS   | hs12-spoke3-6111-app.azurewebsites.net   |
| SPOKE3_APP_SVC_ENDPOINT_IP   | 10.11.4.5   |
| SPOKE3_WEB_APP_ENDPOINT_DNS   | spoke3.p.hub1.az.corp   |
| SPOKE3_WEB_APP_ENDPOINT_IP   | 10.11.4.4   |
| *Subnets*|        |
| AppServiceSubnet   | 10.11.11.0/24   |
| AzureFirewallManagementSubnet   | 10.11.10.0/24   |
| AzureFirewallSubnet   | 10.11.9.0/24   |
| DnsResolverInboundSubnet   | 10.11.5.0/24   |
| DnsResolverOutboundSubnet   | 10.11.6.0/24   |
| GatewaySubnet   | 10.11.7.0/24   |
| LoadBalancerSubnet   | 10.11.2.0/24   |
| MainSubnet   | 10.11.0.0/24   |
| Managementsubnet   | 10.11.14.0/24   |
| PrivateEndpointSubnet   | 10.11.4.0/24   |
| PrivateLinkServiceSubnet   | 10.11.3.0/24   |
| RouteServerSubnet   | 10.11.8.0/24   |
| TestSubnet   | 10.11.1.0/24   |
| TrustSubnet   | 10.11.12.0/24   |
| UntrustSubnet   | 10.11.13.0/24   |
| - | -  |
| VM_IP   | 10.11.0.5   |
| VM_NAME   | Hs12-hub1-vm   |
| VNET_NAME   | Hs12-hub1-vnet   |
| VNET_RANGES   | 10.11.0.0/16   |

## hub2

| Item    | Value  |
|--------|--------|
| PRIVATE_DNS_INBOUND_IP   | 10.22.5.4   |
| SPOKE6_APP_SVC_ENDPOINT_DNS   | hs12-spoke6-6111-app.azurewebsites.net   |
| SPOKE6_APP_SVC_ENDPOINT_IP   | 10.22.4.5   |
| SPOKE6_WEB_APP_ENDPOINT_DNS   | spoke6.p.hub2.az.corp   |
| SPOKE6_WEB_APP_ENDPOINT_IP   | 10.22.4.4   |
| *Subnets*|        |
| AppServiceSubnet   | 10.22.11.0/24   |
| AzureFirewallManagementSubnet   | 10.22.10.0/24   |
| AzureFirewallSubnet   | 10.22.9.0/24   |
| DnsResolverInboundSubnet   | 10.22.5.0/24   |
| DnsResolverOutboundSubnet   | 10.22.6.0/24   |
| GatewaySubnet   | 10.22.7.0/24   |
| LoadBalancerSubnet   | 10.22.2.0/24   |
| MainSubnet   | 10.22.0.0/24   |
| ManagementSubnet   | 10.22.14.0/24   |
| PrivateEndpointSubnet   | 10.22.4.0/24   |
| PrivateLinkServiceSubnet   | 10.22.3.0/24   |
| RouteServerSubnet   | 10.22.8.0/24   |
| TestSubnet   | 10.22.1.0/24   |
| TrustSubnet   | 10.22.12.0/24   |
| UntrustSubnet   | 10.22.13.0/24   |
| - | -  |
| VM_IP   | 10.22.0.5   |
| VM_NAME   | Hs12-hub2-vm   |
| VNET_NAME   | Hs12-hub2-vnet   |
| VNET_RANGES   | 10.22.0.0/16   |

## spoke1

| Item    | Value  |
|--------|--------|
| *Subnets*|        |
| AppGatewaySubnet   | 10.1.1.0/24   |
| AppServiceSubnet   | 10.1.5.0/24   |
| LoadBalancerSubnet   | 10.1.2.0/24   |
| MainSubnet   | 10.1.0.0/24   |
| PrivateEndpointSubnet   | 10.1.4.0/24   |
| PrivateLinkServiceSubnet   | 10.1.3.0/24   |
| - | -  |
| VM_IP   | 10.1.0.5   |
| VM_NAME   | Hs12-spoke1-vm   |
| VNET_NAME   | Hs12-spoke1-vnet   |
| VNET_RANGES   | 10.1.0.0/16   |

## spoke2

| Item    | Value  |
|--------|--------|
| *Subnets*|        |
| AppGatewaySubnet   | 10.2.1.0/24   |
| AppServiceSubnet   | 10.2.5.0/24   |
| LoadBalancerSubnet   | 10.2.2.0/24   |
| MainSubnet   | 10.2.0.0/24   |
| PrivateEndpointSubnet   | 10.2.4.0/24   |
| PrivateLinkServiceSubnet   | 10.2.3.0/24   |
| - | -  |
| VM_IP   | 10.2.0.5   |
| VM_NAME   | Hs12-spoke2-vm   |
| VNET_NAME   | Hs12-spoke2-vnet   |
| VNET_RANGES   | 10.2.0.0/16   |

## spoke3

| Item    | Value  |
|--------|--------|
| APPS_URL   | hs12-spoke3-6111-app.azurewebsites.net   |
| *Subnets*|        |
| AppGatewaySubnet   | 10.3.1.0/24   |
| AppServiceSubnet   | 10.3.5.0/24   |
| LoadBalancerSubnet   | 10.3.2.0/24   |
| MainSubnet   | 10.3.0.0/24   |
| PrivateEndpointSubnet   | 10.3.4.0/24   |
| PrivateLinkServiceSubnet   | 10.3.3.0/24   |
| - | -  |
| VM_IP   | 10.3.0.5   |
| VM_NAME   | Hs12-spoke3-vm   |
| VNET_NAME   | Hs12-spoke3-vnet   |
| VNET_RANGES   | 10.3.0.0/16   |

## spoke4

| Item    | Value  |
|--------|--------|
| *Subnets*|        |
| AppGatewaySubnet   | 10.4.1.0/24   |
| AppServiceSubnet   | 10.4.5.0/24   |
| LoadBalancerSubnet   | 10.4.2.0/24   |
| MainSubnet   | 10.4.0.0/24   |
| PrivateEndpointSubnet   | 10.4.4.0/24   |
| PrivateLinkServiceSubnet   | 10.4.3.0/24   |
| - | -  |
| VM_IP   | 10.4.0.5   |
| VM_NAME   | Hs12-spoke4-vm   |
| VNET_NAME   | Hs12-spoke4-vnet   |
| VNET_RANGES   | 10.4.0.0/16   |

## spoke5

| Item    | Value  |
|--------|--------|
| *Subnets*|        |
| AppGatewaySubnet   | 10.5.1.0/24   |
| AppServiceSubnet   | 10.5.5.0/24   |
| LoadBalancerSubnet   | 10.5.2.0/24   |
| MainSubnet   | 10.5.0.0/24   |
| PrivateEndpointSubnet   | 10.5.4.0/24   |
| PrivateLinkServiceSubnet   | 10.5.3.0/24   |
| - | -  |
| VM_IP   | 10.5.0.5   |
| VM_NAME   | Hs12-spoke5-vm   |
| VNET_NAME   | Hs12-spoke5-vnet   |
| VNET_RANGES   | 10.5.0.0/16   |

## spoke6

| Item    | Value  |
|--------|--------|
| *Subnets*|        |
| AppGatewaySubnet   | 10.6.1.0/24   |
| AppServiceSubnet   | 10.6.5.0/24   |
| LoadBalancerSubnet   | 10.6.2.0/24   |
| MainSubnet   | 10.6.0.0/24   |
| PrivateEndpointSubnet   | 10.6.4.0/24   |
| PrivateLinkServiceSubnet   | 10.6.3.0/24   |
| - | -  |
| VM_IP   | 10.6.0.5   |
| VM_NAME   | Hs12-spoke6-vm   |
| VNET_NAME   | Hs12-spoke6-vnet   |
| VNET_RANGES   | 10.6.0.0/16   |
