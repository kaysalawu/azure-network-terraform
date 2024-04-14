

## branch1

| Item    | Value  |
|--------|--------|
| *Subnets*|        |
| DnsServerSubnet   | 10.10.4.0/24, fd00:db8:10:4::/64   |
| GatewaySubnet   | 10.10.16.0/24, fd00:db8:10:aa16::/64   |
| MainSubnet   | 10.10.0.0/24, fd00:db8:10::/64   |
| ManagementSubnet   | 10.10.3.0/24, fd00:db8:10:3::/64   |
| TestSubnet   | 10.10.17.0/24, fd00:db8:10:aa17::/64   |
| TrustSubnet   | 10.10.2.0/24, fd00:db8:10:2::/64   |
| UntrustSubnet   | 10.10.1.0/24, fd00:db8:10:1::/64   |
| - | -  |
| VM_IP   | 10.10.0.5   |
| VM_NAME   | Hs13-branch1Vm   |
| VNET_NAME   | Hs13-branch1-vnet   |
| VNET_RANGES   | 10.10.0.0/20, 10.10.16.0/20, fd00:db8:10::/56, fd00:db8:10:aa00::/56   |

## branch2

| Item    | Value  |
|--------|--------|
| *Subnets*|        |
| DnsServerSubnet   | 10.20.4.0/24, fd00:db8:20:4::/64   |
| GatewaySubnet   | 10.20.16.0/24, fd00:db8:20:aa16::/64   |
| MainSubnet   | 10.20.0.0/24, fd00:db8:20::/64   |
| ManagementSubnet   | 10.20.3.0/24, fd00:db8:20:3::/64   |
| TestSubnet   | 10.20.17.0/24, fd00:db8:20:aa17::/64   |
| TrustSubnet   | 10.20.2.0/24, fd00:db8:20:2::/64   |
| UntrustSubnet   | 10.20.1.0/24, fd00:db8:20:1::/64   |
| - | -  |
| VM_IP   | 10.20.0.5   |
| VM_NAME   | Hs13-branch2Vm   |
| VNET_NAME   | Hs13-branch2-vnet   |
| VNET_RANGES   | 10.20.0.0/20, 10.20.16.0/20, fd00:db8:20::/56, fd00:db8:20:aa00::/56   |

## hub1

| Item    | Value  |
|--------|--------|
| PRIVATELINK_BLOB_ENDPOINT_DNS   | spoke3pls.hub1.az.corp   |
| PRIVATELINK_BLOB_ENDPOINT_IP   | 10.11.7.99   |
| PRIVATELINK_SERVICE_ENDPOINT_DNS   | spoke3pls.hub1.az.corp   |
| PRIVATELINK_SERVICE_ENDPOINT_IP   | 10.11.7.88   |
| PRIVATE_DNS_INBOUND_IP   | 10.11.8.4   |
| SPOKE3_BLOB_URL (Sample)   | https://hs13spoke3sa5466.blob.core.windows.net/spoke3/spoke3.txt   |
| *Subnets*|        |
| AppGatewaySubnet   | 10.11.4.0/24, fd00:db8:11:4::/64   |
| AppServiceSubnet   | 10.11.13.0/24, fd00:db8:11:13::/64   |
| AzureFirewallManagementSubnet   | 10.11.12.0/24, fd00:db8:11:12::/64   |
| AzureFirewallSubnet   | 10.11.11.0/24, fd00:db8:11:11::/64   |
| DnsResolverInboundSubnet   | 10.11.8.0/24   |
| DnsResolverOutboundSubnet   | 10.11.9.0/24   |
| GatewaySubnet   | 10.11.16.0/24, fd00:db8:11:aa16::/64   |
| LoadBalancerSubnet   | 10.11.5.0/24, fd00:db8:11:5::/64   |
| MainSubnet   | 10.11.0.0/24, fd00:db8:11::/64   |
| ManagementSubnet   | 10.11.3.0/24, fd00:db8:11:3::/64   |
| PrivateEndpointSubnet   | 10.11.7.0/24, fd00:db8:11:7::/64   |
| PrivateLinkServiceSubnet   | 10.11.6.0/24, fd00:db8:11:6::/64   |
| RouteServerSubnet   | 10.11.10.0/24, fd00:db8:11:10::/64   |
| TestSubnet   | 10.11.17.0/24, fd00:db8:11:aa17::/64   |
| TrustSubnet   | 10.11.2.0/24, fd00:db8:11:2::/64   |
| UntrustSubnet   | 10.11.1.0/24, fd00:db8:11:1::/64   |
| - | -  |
| VM_IP   | 10.11.0.5   |
| VM_NAME   | Hs13-hub1Vm   |
| VNET_NAME   | Hs13-hub1-vnet   |
| VNET_RANGES   | 10.11.0.0/20, 10.11.16.0/20, fd00:db8:11::/56, fd00:db8:11:aa00::/56   |

## spoke1

| Item    | Value  |
|--------|--------|
| *Subnets*|        |
| AppGatewaySubnet   | 10.1.4.0/24, fd00:db8:1:4::/64   |
| AppServiceSubnet   | 10.1.8.0/24, fd00:db8:1:8::/64   |
| GatewaySubnet   | 10.1.9.0/24, fd00:db8:1:9::/64   |
| LoadBalancerSubnet   | 10.1.5.0/24, fd00:db8:1:5::/64   |
| MainSubnet   | 10.1.0.0/24, fd00:db8:1::/64   |
| ManagementSubnet   | 10.1.3.0/24, fd00:db8:1:3::/64   |
| PrivateEndpointSubnet   | 10.1.7.0/24, fd00:db8:1:7::/64   |
| PrivateLinkServiceSubnet   | 10.1.6.0/24, fd00:db8:1:6::/64   |
| TestSubnet   | 10.1.10.0/24   |
| TrustSubnet   | 10.1.2.0/24, fd00:db8:1:2::/64   |
| UntrustSubnet   | 10.1.1.0/24, fd00:db8:1:1::/64   |
| - | -  |
| VM_IP   | 10.1.0.5   |
| VM_NAME   | Hs13-spoke1Vm   |
| VNET_NAME   | Hs13-spoke1-vnet   |
| VNET_RANGES   | 10.1.0.0/20, fd00:db8:1::/56   |

## spoke2

| Item    | Value  |
|--------|--------|
| *Subnets*|        |
| AppGatewaySubnet   | 10.2.4.0/24, fd00:db8:2:4::/64   |
| AppServiceSubnet   | 10.2.8.0/24, fd00:db8:2:8::/64   |
| GatewaySubnet   | 10.2.9.0/24, fd00:db8:2:9::/64   |
| LoadBalancerSubnet   | 10.2.5.0/24, fd00:db8:2:5::/64   |
| MainSubnet   | 10.2.0.0/24, fd00:db8:2::/64   |
| ManagementSubnet   | 10.2.3.0/24, fd00:db8:2:3::/64   |
| PrivateEndpointSubnet   | 10.2.7.0/24, fd00:db8:2:7::/64   |
| PrivateLinkServiceSubnet   | 10.2.6.0/24, fd00:db8:2:6::/64   |
| TestSubnet   | 10.2.10.0/24   |
| TrustSubnet   | 10.2.2.0/24, fd00:db8:2:2::/64   |
| UntrustSubnet   | 10.2.1.0/24, fd00:db8:2:1::/64   |
| - | -  |
| VM_IP   | 10.2.0.5   |
| VM_NAME   | Hs13-spoke2Vm   |
| VNET_NAME   | Hs13-spoke2-vnet   |
| VNET_RANGES   | 10.2.0.0/20, fd00:db8:2::/56   |

## spoke3

| Item    | Value  |
|--------|--------|
| *Subnets*|        |
| AppGatewaySubnet   | 10.3.4.0/24, fd00:db8:3:4::/64   |
| AppServiceSubnet   | 10.3.8.0/24, fd00:db8:3:8::/64   |
| GatewaySubnet   | 10.3.9.0/24, fd00:db8:3:9::/64   |
| LoadBalancerSubnet   | 10.3.5.0/24, fd00:db8:3:5::/64   |
| MainSubnet   | 10.3.0.0/24, fd00:db8:3::/64   |
| ManagementSubnet   | 10.3.3.0/24, fd00:db8:3:3::/64   |
| PrivateEndpointSubnet   | 10.3.7.0/24, fd00:db8:3:7::/64   |
| PrivateLinkServiceSubnet   | 10.3.6.0/24, fd00:db8:3:6::/64   |
| TestSubnet   | 10.3.10.0/24   |
| TrustSubnet   | 10.3.2.0/24, fd00:db8:3:2::/64   |
| UntrustSubnet   | 10.3.1.0/24, fd00:db8:3:1::/64   |
| - | -  |
| VM_IP   | 10.3.0.5   |
| VM_NAME   | Hs13-spoke3Vm   |
| VNET_NAME   | Hs13-spoke3-vnet   |
| VNET_RANGES   | 10.3.0.0/20, fd00:db8:3::/56   |
