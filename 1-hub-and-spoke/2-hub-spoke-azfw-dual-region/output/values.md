

## branch1

| Item    | Value  |
|--------|--------|
| *Subnets*|        |
| GatewaySubnet   | 10.10.4.0/24   |
| Hs12-branch1-dns   | 10.10.3.0/24   |
| Hs12-branch1-ext   | 10.10.1.0/24   |
| Hs12-branch1-int   | 10.10.2.0/24   |
| Hs12-branch1-main   | 10.10.0.0/24   |
| - | -  |
| VM_IP   | 10.10.0.5   |
| VM_NAME   | Hs12-branch1-vm   |
| VNET_NAME   | Hs12-branch1-vnet   |
| VNET_RANGES   | 10.10.0.0/16   |

## branch3

| Item    | Value  |
|--------|--------|
| *Subnets*|        |
| GatewaySubnet   | 10.30.4.0/24   |
| Hs12-branch3-dns   | 10.30.3.0/24   |
| Hs12-branch3-ext   | 10.30.1.0/24   |
| Hs12-branch3-int   | 10.30.2.0/24   |
| Hs12-branch3-main   | 10.30.0.0/24   |
| - | -  |
| VM_IP   | 10.30.0.5   |
| VM_NAME   | Hs12-branch3-vm   |
| VNET_NAME   | Hs12-branch3-vnet   |
| VNET_RANGES   | 10.30.0.0/16   |

## hub1

| Item    | Value  |
|--------|--------|
| DNS_IN_IP   | 10.11.5.4   |
| SPOKE3_APP_SVC_ENDPOINT_DNS   | hs12-spoke3-3578-app.azurewebsites.net   |
| SPOKE3_APP_SVC_ENDPOINT_IP   | 10.11.4.4   |
| SPOKE3_WEB_APP_ENDPOINT_DNS   | spoke3.p   |
| SPOKE3_WEB_APP_ENDPOINT_IP   | 10.11.4.5   |
| *Subnets*|        |
| AzureFirewallManagementSubnet   | 10.11.10.0/24   |
| AzureFirewallSubnet   | 10.11.9.0/24   |
| GatewaySubnet   | 10.11.7.0/24   |
| Hs12-hub1-apps   | 10.11.11.0/24   |
| Hs12-hub1-dns-in   | 10.11.5.0/24   |
| Hs12-hub1-dns-out   | 10.11.6.0/24   |
| Hs12-hub1-ilb   | 10.11.2.0/24   |
| Hs12-hub1-main   | 10.11.0.0/24   |
| Hs12-hub1-nva   | 10.11.1.0/24   |
| Hs12-hub1-pep   | 10.11.4.0/24   |
| Hs12-hub1-pls   | 10.11.3.0/24   |
| RouteServerSubnet   | 10.11.8.0/24   |
| - | -  |
| VM_IP   | 10.11.0.5   |
| VM_NAME   | Hs12-hub1-vm   |
| VNET_NAME   | Hs12-hub1-vnet   |
| VNET_RANGES   | 10.11.0.0/16   |

## hub2

| Item    | Value  |
|--------|--------|
| DNS_IN_IP   | 10.22.5.4   |
| SPOKE6_APP_SVC_ENDPOINT_DNS   | hs12-spoke6-f8a9-app.azurewebsites.net   |
| SPOKE6_APP_SVC_ENDPOINT_IP   | 10.22.4.4   |
| SPOKE6_WEB_APP_ENDPOINT_DNS   | spoke6.p   |
| SPOKE6_WEB_APP_ENDPOINT_IP   | 10.11.4.5   |
| *Subnets*|        |
| AzureFirewallManagementSubnet   | 10.22.10.0/24   |
| AzureFirewallSubnet   | 10.22.9.0/24   |
| GatewaySubnet   | 10.22.7.0/24   |
| Hs12-hub2-apps   | 10.22.11.0/24   |
| Hs12-hub2-dns-in   | 10.22.5.0/24   |
| Hs12-hub2-dns-out   | 10.22.6.0/24   |
| Hs12-hub2-ilb   | 10.22.2.0/24   |
| Hs12-hub2-main   | 10.22.0.0/24   |
| Hs12-hub2-nva   | 10.22.1.0/24   |
| Hs12-hub2-pep   | 10.22.4.0/24   |
| Hs12-hub2-pls   | 10.22.3.0/24   |
| RouteServerSubnet   | 10.22.8.0/24   |
| - | -  |
| VM_IP   | 10.22.0.5   |
| VM_NAME   | Hs12-hub2-vm   |
| VNET_NAME   | Hs12-hub2-vnet   |
| VNET_RANGES   | 10.22.0.0/16   |

## spoke1

| Item    | Value  |
|--------|--------|
| *Subnets*|        |
| Hs12-spoke1-appgw   | 10.1.1.0/24   |
| Hs12-spoke1-apps   | 10.1.5.0/24   |
| Hs12-spoke1-ilb   | 10.1.2.0/24   |
| Hs12-spoke1-main   | 10.1.0.0/24   |
| Hs12-spoke1-pep   | 10.1.4.0/24   |
| Hs12-spoke1-pls   | 10.1.3.0/24   |
| - | -  |
| VM_IP   | 10.1.0.5   |
| VM_NAME   | Hs12-spoke1-vm   |
| VNET_NAME   | Hs12-spoke1-vnet   |
| VNET_RANGES   | 10.1.0.0/16   |

## spoke2

| Item    | Value  |
|--------|--------|
| *Subnets*|        |
| Hs12-spoke2-appgw   | 10.2.1.0/24   |
| Hs12-spoke2-apps   | 10.2.5.0/24   |
| Hs12-spoke2-ilb   | 10.2.2.0/24   |
| Hs12-spoke2-main   | 10.2.0.0/24   |
| Hs12-spoke2-pep   | 10.2.4.0/24   |
| Hs12-spoke2-pls   | 10.2.3.0/24   |
| - | -  |
| VM_IP   | 10.2.0.5   |
| VM_NAME   | Hs12-spoke2-vm   |
| VNET_NAME   | Hs12-spoke2-vnet   |
| VNET_RANGES   | 10.2.0.0/16   |

## spoke3

| Item    | Value  |
|--------|--------|
| APPS_URL   | hs12-spoke3-3578-app.azurewebsites.net   |
| *Subnets*|        |
| Hs12-spoke3-appgw   | 10.3.1.0/24   |
| Hs12-spoke3-apps   | 10.3.5.0/24   |
| Hs12-spoke3-ilb   | 10.3.2.0/24   |
| Hs12-spoke3-main   | 10.3.0.0/24   |
| Hs12-spoke3-pep   | 10.3.4.0/24   |
| Hs12-spoke3-pls   | 10.3.3.0/24   |
| - | -  |
| VM_IP   | 10.3.0.5   |
| VM_NAME   | Hs12-spoke3-vm   |
| VNET_NAME   | Hs12-spoke3-vnet   |
| VNET_RANGES   | 10.3.0.0/16   |

## spoke4

| Item    | Value  |
|--------|--------|
| *Subnets*|        |
| Hs12-spoke4-appgw   | 10.4.1.0/24   |
| Hs12-spoke4-apps   | 10.4.5.0/24   |
| Hs12-spoke4-ilb   | 10.4.2.0/24   |
| Hs12-spoke4-main   | 10.4.0.0/24   |
| Hs12-spoke4-pep   | 10.4.4.0/24   |
| Hs12-spoke4-pls   | 10.4.3.0/24   |
| - | -  |
| VM_IP   | 10.4.0.5   |
| VM_NAME   | Hs12-spoke4-vm   |
| VNET_NAME   | Hs12-spoke4-vnet   |
| VNET_RANGES   | 10.4.0.0/16   |

## spoke5

| Item    | Value  |
|--------|--------|
| *Subnets*|        |
| Hs12-spoke5-appgw   | 10.5.1.0/24   |
| Hs12-spoke5-apps   | 10.5.5.0/24   |
| Hs12-spoke5-ilb   | 10.5.2.0/24   |
| Hs12-spoke5-main   | 10.5.0.0/24   |
| Hs12-spoke5-pep   | 10.5.4.0/24   |
| Hs12-spoke5-pls   | 10.5.3.0/24   |
| - | -  |
| VM_IP   | 10.5.0.5   |
| VM_NAME   | Hs12-spoke5-vm   |
| VNET_NAME   | Hs12-spoke5-vnet   |
| VNET_RANGES   | 10.5.0.0/16   |

## spoke6

| Item    | Value  |
|--------|--------|
| *Subnets*|        |
| Hs12-spoke6-appgw   | 10.6.1.0/24   |
| Hs12-spoke6-apps   | 10.6.5.0/24   |
| Hs12-spoke6-ilb   | 10.6.2.0/24   |
| Hs12-spoke6-main   | 10.6.0.0/24   |
| Hs12-spoke6-pep   | 10.6.4.0/24   |
| Hs12-spoke6-pls   | 10.6.3.0/24   |
| - | -  |
| VM_IP   | 10.6.0.5   |
| VM_NAME   | Hs12-spoke6-vm   |
| VNET_NAME   | Hs12-spoke6-vnet   |
| VNET_RANGES   | 10.6.0.0/16   |
