

## branch1

| Item    | Value  |
|--------|--------|
| *Subnets*|        |
| DnsServerSubnet   | 10.10.4.0/24   |
| GatewaySubnet   | 10.10.16.0/24   |
| MainSubnet   | 10.10.0.0/24   |
| ManagementSubnet   | 10.10.3.0/24   |
| RouteServerSubnet   | 10.10.18.0/24   |
| TestSubnet   | 10.10.17.0/24   |
| TrustSubnet   | 10.10.2.0/24   |
| UntrustSubnet   | 10.10.1.0/24   |
| - | -  |
| VM_IP   | 10.10.0.5   |
| VM_NAME   | Hs12-branch1Vm   |
| VNET_NAME   | Hs12-branch1-vnet   |
| VNET_RANGES   | 10.10.0.0/20, 10.10.16.0/20, fd00:db8:10::/56, fd00:db8:10:aa00::/56   |

## branch3

| Item    | Value  |
|--------|--------|
| *Subnets*|        |
| DnsServerSubnet   | 10.30.4.0/24   |
| GatewaySubnet   | 10.30.16.0/24   |
| MainSubnet   | 10.30.0.0/24   |
| ManagementSubnet   | 10.30.3.0/24   |
| RouteServerSubnet   | 10.30.17.0/24   |
| TestSubnet   | 10.30.18.0/24   |
| TrustSubnet   | 10.30.2.0/24   |
| UntrustSubnet   | 10.30.1.0/24   |
| - | -  |
| VM_IP   | 10.30.0.5   |
| VM_NAME   | Hs12-branch3Vm   |
| VNET_NAME   | Hs12-branch3-vnet   |
| VNET_RANGES   | 10.30.0.0/20, 10.30.16.0/20, fd00:db8:30::/56, fd00:db8:30:aa00::/56   |

## hub1

| Item    | Value  |
|--------|--------|
| PRIVATELINK_BLOB_ENDPOINT_DNS   | spoke3pls.hub1.az.corp   |
| PRIVATELINK_BLOB_ENDPOINT_IP   | 10.11.7.99   |
| PRIVATELINK_SERVICE_ENDPOINT_DNS   | spoke3pls.hub1.az.corp   |
| PRIVATELINK_SERVICE_ENDPOINT_IP   | 10.11.7.88   |
| PRIVATE_DNS_INBOUND_IP   | 10.11.8.4   |
| SPOKE3_BLOB_URL (Sample)   | https://hs12spoke3sa2e9f.blob.core.windows.net/spoke3/spoke3.txt   |
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
| TestSubnet   | 10.11.17.0/24   |
| TrustSubnet   | 10.11.2.0/24   |
| UntrustSubnet   | 10.11.1.0/24   |
| - | -  |
| VM_IP   | 10.11.0.5   |
| VM_NAME   | Hs12-hub1Vm   |
| VNET_NAME   | Hs12-hub1-vnet   |
| VNET_RANGES   | 10.11.0.0/20, 10.11.16.0/20, fd00:db8:11::/56, fd00:db8:11:aa00::/56   |

## hub2

| Item    | Value  |
|--------|--------|
| PRIVATELINK_BLOB_ENDPOINT_DNS   | spoke6pls.hub2.az.corp   |
| PRIVATELINK_BLOB_ENDPOINT_IP   | 10.22.7.99   |
| PRIVATELINK_SERVICE_ENDPOINT_DNS   | spoke6pls.hub2.az.corp   |
| PRIVATELINK_SERVICE_ENDPOINT_IP   | 10.22.7.88   |
| PRIVATE_DNS_INBOUND_IP   | 10.22.8.4   |
| SPOKE6_BLOB_URL (Sample)   | https://hs12spoke6sa2e9f.blob.core.windows.net/spoke6/spoke6.txt   |
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
| TestSubnet   | 10.22.17.0/24   |
| TrustSubnet   | 10.22.2.0/24   |
| UntrustSubnet   | 10.22.1.0/24   |
| - | -  |
| VM_IP   | 10.22.0.5   |
| VM_NAME   | Hs12-hub2Vm   |
| VNET_NAME   | Hs12-hub2-vnet   |
| VNET_RANGES   | 10.22.0.0/20, 10.22.16.0/20, fd00:db8:22::/56, fd00:db8:22:aa00::/56   |

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
| TestSubnet   | 10.1.10.0/24   |
| TrustSubnet   | 10.1.2.0/24   |
| UntrustSubnet   | 10.1.1.0/24   |
| - | -  |
| VM_IP   | 10.1.0.5   |
| VM_NAME   | Hs12-spoke1Vm   |
| VNET_NAME   | Hs12-spoke1-vnet   |
| VNET_RANGES   | 10.1.0.0/20, fd00:db8:1::/56   |

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
| TestSubnet   | 10.2.10.0/24   |
| TrustSubnet   | 10.2.2.0/24   |
| UntrustSubnet   | 10.2.1.0/24   |
| - | -  |
| VM_IP   | 10.2.0.5   |
| VM_NAME   | Hs12-spoke2Vm   |
| VNET_NAME   | Hs12-spoke2-vnet   |
| VNET_RANGES   | 10.2.0.0/20, fd00:db8:2::/56   |

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
| TestSubnet   | 10.3.10.0/24   |
| TrustSubnet   | 10.3.2.0/24   |
| UntrustSubnet   | 10.3.1.0/24   |
| - | -  |
| VM_IP   | 10.3.0.5   |
| VM_NAME   | Hs12-spoke3Vm   |
| VNET_NAME   | Hs12-spoke3-vnet   |
| VNET_RANGES   | 10.3.0.0/20, fd00:db8:3::/56   |

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
| TestSubnet   | 10.4.10.0/24   |
| TrustSubnet   | 10.4.2.0/24   |
| UntrustSubnet   | 10.4.1.0/24   |
| - | -  |
| VM_IP   | 10.4.0.5   |
| VM_NAME   | Hs12-spoke4Vm   |
| VNET_NAME   | Hs12-spoke4-vnet   |
| VNET_RANGES   | 10.4.0.0/20, fd00:db8:4::/56   |

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
| TestSubnet   | 10.5.10.0/24   |
| TrustSubnet   | 10.5.2.0/24   |
| UntrustSubnet   | 10.5.1.0/24   |
| - | -  |
| VM_IP   | 10.5.0.5   |
| VM_NAME   | Hs12-spoke5Vm   |
| VNET_NAME   | Hs12-spoke5-vnet   |
| VNET_RANGES   | 10.5.0.0/20, fd00:db8:5::/56   |

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
| TestSubnet   | 10.6.10.0/24   |
| TrustSubnet   | 10.6.2.0/24   |
| UntrustSubnet   | 10.6.1.0/24   |
| - | -  |
| VM_IP   | 10.6.0.5   |
| VM_NAME   | Hs12-spoke6Vm   |
| VNET_NAME   | Hs12-spoke6-vnet   |
| VNET_RANGES   | 10.6.0.0/20, fd00:db8:6::/56   |
