

## branch1

| Item    | Value  |
|--------|--------|
| *Subnets*|        |
| DnsServerSubnet   | 10.10.4.0/24   |
| GatewaySubnet   | 10.10.16.0/24   |
| MainSubnet   | 10.10.0.0/24   |
| ManagementSubnet   | 10.10.3.0/24   |
| TrustSubnet   | 10.10.2.0/24   |
| UntrustSubnet   | 10.10.1.0/24   |
| - | -  |
| VM_IP   | 10.10.0.5   |
| VM_NAME   | Vwan24-branch1Vm   |
| VNET_NAME   | Vwan24-branch1-vnet   |
| VNET_RANGES   | 10.10.0.0/20, 10.10.16.0/20   |

## branch3

| Item    | Value  |
|--------|--------|
| *Subnets*|        |
| DnsServerSubnet   | 10.30.4.0/24   |
| GatewaySubnet   | 10.30.16.0/24   |
| MainSubnet   | 10.30.0.0/24   |
| ManagementSubnet   | 10.30.3.0/24   |
| TrustSubnet   | 10.30.2.0/24   |
| UntrustSubnet   | 10.30.1.0/24   |
| - | -  |
| VM_IP   | 10.30.0.5   |
| VM_NAME   | Vwan24-branch3Vm   |
| VNET_NAME   | Vwan24-branch3-vnet   |
| VNET_RANGES   | 10.30.0.0/20, 10.30.16.0/20   |

## hub1

| Item    | Value  |
|--------|--------|
| PRIVATELINK_BLOB_ENDPOINT_DNS   | spoke3pls.hub1.az.corp   |
| PRIVATELINK_BLOB_ENDPOINT_IP   | 10.11.7.99   |
| PRIVATELINK_SERVICE_ENDPOINT_DNS   | spoke3pls.hub1.az.corp   |
| PRIVATELINK_SERVICE_ENDPOINT_IP   | 10.11.7.88   |
| PRIVATE_DNS_INBOUND_IP   | 10.11.8.4   |
| SPOKE3_BLOB_URL (Sample)   | https://vwan24spoke3sa87b5.blob.core.windows.net/spoke3/spoke3.txt   |
| *Subnets*|        |
| AppGatewaySubnet   | 10.11.4.0/24   |
| AppServiceSubnet   | 10.11.13.0/24   |
| AzureFirewallManagementSubnet   | 10.11.12.0/24   |
| AzureFirewallSubnet   | 10.11.11.0/24   |
| DnsResolverInboundSubnet   | 10.11.8.0/24   |
| DnsResolverOutboundSubnet   | 10.11.9.0/24   |
| GatewaySubnet   | 10.11.16.0/24   |
| LoadBalancerSubnet   | 10.11.5.0/24   |
| MainSubnet   | 10.11.0.0/24   |
| ManagementSubnet   | 10.11.3.0/24   |
| PrivateEndpointSubnet   | 10.11.7.0/24   |
| PrivateLinkServiceSubnet   | 10.11.6.0/24   |
| RouteServerSubnet   | 10.11.10.0/24   |
| TrustSubnet   | 10.11.2.0/24   |
| UntrustSubnet   | 10.11.1.0/24   |
| - | -  |
| VM_IP   | 10.11.0.5   |
| VM_NAME   | Vwan24-hub1Vm   |
| VNET_NAME   | Vwan24-hub1-vnet   |
| VNET_RANGES   | 10.11.0.0/20, 10.11.16.0/20   |

## hub2

| Item    | Value  |
|--------|--------|
| PRIVATELINK_BLOB_ENDPOINT_DNS   | spoke6pls.hub2.az.corp   |
| PRIVATELINK_BLOB_ENDPOINT_IP   | 10.22.7.99   |
| PRIVATELINK_SERVICE_ENDPOINT_DNS   | spoke6pls.hub2.az.corp   |
| PRIVATELINK_SERVICE_ENDPOINT_IP   | 10.22.7.88   |
| PRIVATE_DNS_INBOUND_IP   | 10.22.8.4   |
| SPOKE6_BLOB_URL (Sample)   | https://vwan24spoke6sa87b5.blob.core.windows.net/spoke6/spoke6.txt   |
| *Subnets*|        |
| AppGatewaySubnet   | 10.22.4.0/24   |
| AppServiceSubnet   | 10.22.13.0/24   |
| AzureFirewallManagementSubnet   | 10.22.12.0/24   |
| AzureFirewallSubnet   | 10.22.11.0/24   |
| DnsResolverInboundSubnet   | 10.22.8.0/24   |
| DnsResolverOutboundSubnet   | 10.22.9.0/24   |
| GatewaySubnet   | 10.22.16.0/24   |
| LoadBalancerSubnet   | 10.22.5.0/24   |
| MainSubnet   | 10.22.0.0/24   |
| ManagementSubnet   | 10.22.3.0/24   |
| PrivateEndpointSubnet   | 10.22.7.0/24   |
| PrivateLinkServiceSubnet   | 10.22.6.0/24   |
| RouteServerSubnet   | 10.22.10.0/24   |
| TrustSubnet   | 10.22.2.0/24   |
| UntrustSubnet   | 10.22.1.0/24   |
| - | -  |
| VM_IP   | 10.22.0.5   |
| VM_NAME   | Vwan24-hub2Vm   |
| VNET_NAME   | Vwan24-hub2-vnet   |
| VNET_RANGES   | 10.22.0.0/20, 10.22.16.0/20   |

## spoke1

| Item    | Value  |
|--------|--------|
| *Subnets*|        |
| AppGatewaySubnet   | 10.1.4.0/24   |
| AppServiceSubnet   | 10.1.8.0/24   |
| GatewaySubnet   | 10.1.9.0/24   |
| LoadBalancerSubnet   | 10.1.5.0/24   |
| MainSubnet   | 10.1.0.0/24   |
| ManagementSubnet   | 10.1.3.0/24   |
| PrivateEndpointSubnet   | 10.1.7.0/24   |
| PrivateLinkServiceSubnet   | 10.1.6.0/24   |
| TrustSubnet   | 10.1.2.0/24   |
| UntrustSubnet   | 10.1.1.0/24   |
| - | -  |
| VM_IP   | 10.1.0.5   |
| VM_NAME   | Vwan24-spoke1Vm   |
| VNET_NAME   | Vwan24-spoke1-vnet   |
| VNET_RANGES   | 10.1.0.0/20   |

## spoke2

| Item    | Value  |
|--------|--------|
| *Subnets*|        |
| AppGatewaySubnet   | 10.2.4.0/24   |
| AppServiceSubnet   | 10.2.8.0/24   |
| GatewaySubnet   | 10.2.9.0/24   |
| LoadBalancerSubnet   | 10.2.5.0/24   |
| MainSubnet   | 10.2.0.0/24   |
| ManagementSubnet   | 10.2.3.0/24   |
| PrivateEndpointSubnet   | 10.2.7.0/24   |
| PrivateLinkServiceSubnet   | 10.2.6.0/24   |
| TrustSubnet   | 10.2.2.0/24   |
| UntrustSubnet   | 10.2.1.0/24   |
| - | -  |
| VM_IP   | 10.2.0.5   |
| VM_NAME   | Vwan24-spoke2Vm   |
| VNET_NAME   | Vwan24-spoke2-vnet   |
| VNET_RANGES   | 10.2.0.0/20   |

## spoke3

| Item    | Value  |
|--------|--------|
| *Subnets*|        |
| AppGatewaySubnet   | 10.3.4.0/24   |
| AppServiceSubnet   | 10.3.8.0/24   |
| GatewaySubnet   | 10.3.9.0/24   |
| LoadBalancerSubnet   | 10.3.5.0/24   |
| MainSubnet   | 10.3.0.0/24   |
| ManagementSubnet   | 10.3.3.0/24   |
| PrivateEndpointSubnet   | 10.3.7.0/24   |
| PrivateLinkServiceSubnet   | 10.3.6.0/24   |
| TrustSubnet   | 10.3.2.0/24   |
| UntrustSubnet   | 10.3.1.0/24   |
| - | -  |
| VM_IP   | 10.3.0.5   |
| VM_NAME   | Vwan24-spoke3Vm   |
| VNET_NAME   | Vwan24-spoke3-vnet   |
| VNET_RANGES   | 10.3.0.0/20   |

## spoke4

| Item    | Value  |
|--------|--------|
| *Subnets*|        |
| AppGatewaySubnet   | 10.4.4.0/24   |
| AppServiceSubnet   | 10.4.8.0/24   |
| GatewaySubnet   | 10.4.9.0/24   |
| LoadBalancerSubnet   | 10.4.5.0/24   |
| MainSubnet   | 10.4.0.0/24   |
| ManagementSubnet   | 10.4.3.0/24   |
| PrivateEndpointSubnet   | 10.4.7.0/24   |
| PrivateLinkServiceSubnet   | 10.4.6.0/24   |
| TrustSubnet   | 10.4.2.0/24   |
| UntrustSubnet   | 10.4.1.0/24   |
| - | -  |
| VM_IP   | 10.4.0.5   |
| VM_NAME   | Vwan24-spoke4Vm   |
| VNET_NAME   | Vwan24-spoke4-vnet   |
| VNET_RANGES   | 10.4.0.0/20   |

## spoke5

| Item    | Value  |
|--------|--------|
| *Subnets*|        |
| AppGatewaySubnet   | 10.5.4.0/24   |
| AppServiceSubnet   | 10.5.8.0/24   |
| GatewaySubnet   | 10.5.9.0/24   |
| LoadBalancerSubnet   | 10.5.5.0/24   |
| MainSubnet   | 10.5.0.0/24   |
| ManagementSubnet   | 10.5.3.0/24   |
| PrivateEndpointSubnet   | 10.5.7.0/24   |
| PrivateLinkServiceSubnet   | 10.5.6.0/24   |
| TrustSubnet   | 10.5.2.0/24   |
| UntrustSubnet   | 10.5.1.0/24   |
| - | -  |
| VM_IP   | 10.5.0.5   |
| VM_NAME   | Vwan24-spoke5Vm   |
| VNET_NAME   | Vwan24-spoke5-vnet   |
| VNET_RANGES   | 10.5.0.0/20   |

## spoke6

| Item    | Value  |
|--------|--------|
| *Subnets*|        |
| AppGatewaySubnet   | 10.6.4.0/24   |
| AppServiceSubnet   | 10.6.8.0/24   |
| GatewaySubnet   | 10.6.9.0/24   |
| LoadBalancerSubnet   | 10.6.5.0/24   |
| MainSubnet   | 10.6.0.0/24   |
| ManagementSubnet   | 10.6.3.0/24   |
| PrivateEndpointSubnet   | 10.6.7.0/24   |
| PrivateLinkServiceSubnet   | 10.6.6.0/24   |
| TrustSubnet   | 10.6.2.0/24   |
| UntrustSubnet   | 10.6.1.0/24   |
| - | -  |
| VM_IP   | 10.6.0.5   |
| VM_NAME   | Vwan24-spoke6Vm   |
| VNET_NAME   | Vwan24-spoke6-vnet   |
| VNET_RANGES   | 10.6.0.0/20   |
