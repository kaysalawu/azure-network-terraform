

## branch1

| Item    | Value  |
|--------|--------|
| *Subnets*|        |
| GatewaySubnet   | 10.10.4.0/24   |
| Hs11-branch1-dns   | 10.10.3.0/24   |
| Hs11-branch1-ext   | 10.10.1.0/24   |
| Hs11-branch1-int   | 10.10.2.0/24   |
| Hs11-branch1-main   | 10.10.0.0/24   |
| - | -  |
| VM_IP   | 10.10.0.5   |
| VM_NAME   | Hs11-branch1-vm   |
| VNET_NAME   | Hs11-branch1-vnet   |
| VNET_RANGES   | 10.10.0.0/16   |

## hub1

| Item    | Value  |
|--------|--------|
| DNS_IN_IP   | 10.11.5.4   |
| *Subnets*|        |
| AzureFirewallManagementSubnet   | 10.11.10.0/24   |
| AzureFirewallSubnet   | 10.11.9.0/24   |
| GatewaySubnet   | 10.11.7.0/24   |
| Hs11-hub1-apps   | 10.11.11.0/24   |
| Hs11-hub1-dns-in   | 10.11.5.0/24   |
| Hs11-hub1-dns-out   | 10.11.6.0/24   |
| Hs11-hub1-ilb   | 10.11.2.0/24   |
| Hs11-hub1-main   | 10.11.0.0/24   |
| Hs11-hub1-nva   | 10.11.1.0/24   |
| Hs11-hub1-pep   | 10.11.4.0/24   |
| Hs11-hub1-pls   | 10.11.3.0/24   |
| RouteServerSubnet   | 10.11.8.0/24   |
| - | -  |
| VM_IP   | 10.11.0.5   |
| VM_NAME   | Hs11-hub1-vm   |
| VNET_NAME   | Hs11-hub1-vnet   |
| VNET_RANGES   | 10.11.0.0/16   |

## spoke1

| Item    | Value  |
|--------|--------|
| *Subnets*|        |
| Hs11-spoke1-appgw   | 10.1.1.0/24   |
| Hs11-spoke1-apps   | 10.1.5.0/24   |
| Hs11-spoke1-ilb   | 10.1.2.0/24   |
| Hs11-spoke1-main   | 10.1.0.0/24   |
| Hs11-spoke1-pep   | 10.1.4.0/24   |
| Hs11-spoke1-pls   | 10.1.3.0/24   |
| - | -  |
| VM_IP   | 10.1.0.5   |
| VM_NAME   | Hs11-spoke1-vm   |
| VNET_NAME   | Hs11-spoke1-vnet   |
| VNET_RANGES   | 10.1.0.0/16   |

## spoke2

| Item    | Value  |
|--------|--------|
| *Subnets*|        |
| Hs11-spoke2-appgw   | 10.2.1.0/24   |
| Hs11-spoke2-apps   | 10.2.5.0/24   |
| Hs11-spoke2-ilb   | 10.2.2.0/24   |
| Hs11-spoke2-main   | 10.2.0.0/24   |
| Hs11-spoke2-pep   | 10.2.4.0/24   |
| Hs11-spoke2-pls   | 10.2.3.0/24   |
| - | -  |
| VM_IP   | 10.2.0.5   |
| VM_NAME   | Hs11-spoke2-vm   |
| VNET_NAME   | Hs11-spoke2-vnet   |
| VNET_RANGES   | 10.2.0.0/16   |

## spoke3

| Item    | Value  |
|--------|--------|
| APPS_URL   | hs11-spoke3-f8d3-app.azurewebsites.net   |
| *Subnets*|        |
| Hs11-spoke3-appgw   | 10.3.1.0/24   |
| Hs11-spoke3-apps   | 10.3.5.0/24   |
| Hs11-spoke3-ilb   | 10.3.2.0/24   |
| Hs11-spoke3-main   | 10.3.0.0/24   |
| Hs11-spoke3-pep   | 10.3.4.0/24   |
| Hs11-spoke3-pls   | 10.3.3.0/24   |
| - | -  |
| VM_IP   | 10.3.0.5   |
| VM_NAME   | Hs11-spoke3-vm   |
| VNET_NAME   | Hs11-spoke3-vnet   |
| VNET_RANGES   | 10.3.0.0/16   |
