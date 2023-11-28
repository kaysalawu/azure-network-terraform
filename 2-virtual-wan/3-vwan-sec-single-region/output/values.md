

## branch1

| Item    | Value  |
|--------|--------|
| *Subnets*|        |
| DnsServerSubnet   | 10.10.4.0/24   |
| GatewaySubnet   | 10.10.5.0/24   |
| MainSubnet   | 10.10.0.0/24   |
| ManagementSubnet   | 10.10.2.0/24   |
| TrustSubnet   | 10.10.3.0/24   |
| UntrustSubnet   | 10.10.1.0/24   |
| - | -  |
| VM_IP   | 10.10.0.5   |
| VM_NAME   | Vwan23-branch1-vm   |
| VNET_NAME   | Vwan23-branch1-vnet   |
| VNET_RANGES   | 10.10.0.0/16   |

## hub1

| Item    | Value  |
|--------|--------|
| PRIVATE_DNS_INBOUND_IP   | 10.11.8.4   |
| SPOKE3_APP_SVC_ENDPOINT_DNS   | vwan23-spoke3-00fc-app.azurewebsites.net   |
| SPOKE3_APP_SVC_ENDPOINT_IP   | 10.11.7.5   |
| SPOKE3_WEB_APP_ENDPOINT_DNS   | spoke3.p.hub1.az.corp   |
| SPOKE3_WEB_APP_ENDPOINT_IP   | 10.11.7.4   |
| *Subnets*|        |
| AppGatewaySubnet   | 10.11.4.0/24   |
| AppServiceSubnet   | 10.11.14.0/24   |
| AzureFirewallManagementSubnet   | 10.11.13.0/24   |
| AzureFirewallSubnet   | 10.11.12.0/24   |
| DnsResolverInboundSubnet   | 10.11.8.0/24   |
| DnsResolverOutboundSubnet   | 10.11.9.0/24   |
| GatewaySubnet   | 10.11.10.0/24   |
| LoadBalancerSubnet   | 10.11.5.0/24   |
| MainSubnet   | 10.11.0.0/24   |
| ManagementSubnet   | 10.11.3.0/24   |
| PrivateEndpointSubnet   | 10.11.7.0/24   |
| PrivateLinkServiceSubnet   | 10.11.6.0/24   |
| RouteServerSubnet   | 10.11.11.0/24   |
| TrustSubnet   | 10.11.1.0/24   |
| UntrustSubnet   | 10.11.2.0/24   |
| - | -  |
| VM_IP   | 10.11.0.5   |
| VM_NAME   | Vwan23-hub1-vm   |
| VNET_NAME   | Vwan23-hub1-vnet   |
| VNET_RANGES   | 10.11.0.0/16   |

## spoke1

| Item    | Value  |
|--------|--------|
| *Subnets*|        |
| AppGatewaySubnet   | 10.1.4.0/24   |
| AppServiceSubnet   | 10.1.8.0/24   |
| LoadBalancerSubnet   | 10.1.5.0/24   |
| MainSubnet   | 10.1.0.0/24   |
| ManagementSubnet   | 10.1.3.0/24   |
| PrivateEndpointSubnet   | 10.1.7.0/24   |
| PrivateLinkServiceSubnet   | 10.1.6.0/24   |
| TrustSubnet   | 10.1.1.0/24   |
| UntrustSubnet   | 10.1.2.0/24   |
| - | -  |
| VM_IP   | 10.1.0.5   |
| VM_NAME   | Vwan23-spoke1-vm   |
| VNET_NAME   | Vwan23-spoke1-vnet   |
| VNET_RANGES   | 10.1.0.0/16   |

## spoke2

| Item    | Value  |
|--------|--------|
| *Subnets*|        |
| AppGatewaySubnet   | 10.2.4.0/24   |
| AppServiceSubnet   | 10.2.8.0/24   |
| LoadBalancerSubnet   | 10.2.5.0/24   |
| MainSubnet   | 10.2.0.0/24   |
| ManagementSubnet   | 10.2.3.0/24   |
| PrivateEndpointSubnet   | 10.2.7.0/24   |
| PrivateLinkServiceSubnet   | 10.2.6.0/24   |
| TrustSubnet   | 10.2.1.0/24   |
| UntrustSubnet   | 10.2.2.0/24   |
| - | -  |
| VM_IP   | 10.2.0.5   |
| VM_NAME   | Vwan23-spoke2-vm   |
| VNET_NAME   | Vwan23-spoke2-vnet   |
| VNET_RANGES   | 10.2.0.0/16   |

## spoke3

| Item    | Value  |
|--------|--------|
| APPS_URL   | vwan23-spoke3-00fc-app.azurewebsites.net   |
| *Subnets*|        |
| AppGatewaySubnet   | 10.3.4.0/24   |
| AppServiceSubnet   | 10.3.8.0/24   |
| LoadBalancerSubnet   | 10.3.5.0/24   |
| MainSubnet   | 10.3.0.0/24   |
| ManagementSubnet   | 10.3.3.0/24   |
| PrivateEndpointSubnet   | 10.3.7.0/24   |
| PrivateLinkServiceSubnet   | 10.3.6.0/24   |
| TrustSubnet   | 10.3.1.0/24   |
| UntrustSubnet   | 10.3.2.0/24   |
| - | -  |
| VM_IP   | 10.3.0.5   |
| VM_NAME   | Vwan23-spoke3-vm   |
| VNET_NAME   | Vwan23-spoke3-vnet   |
| VNET_RANGES   | 10.3.0.0/16   |
