
# hub1
#----------------------------------------
vnet_name = Hs11-hub1-vnet
vnet_ranges = 10.11.0.0/16
vm_name = Hs11-hub1-vm
vm_ip = 10.11.0.5
AzureFirewallManagementSubnet = 10.11.10.0/24
AzureFirewallSubnet = 10.11.9.0/24
GatewaySubnet = 10.11.7.0/24
Hs11-hub1-dns-in = 10.11.5.0/24
Hs11-hub1-dns-out = 10.11.6.0/24
Hs11-hub1-ilb = 10.11.2.0/24
Hs11-hub1-main = 10.11.0.0/24
Hs11-hub1-nva = 10.11.1.0/24
Hs11-hub1-pep = 10.11.4.0/24
Hs11-hub1-pls = 10.11.3.0/24
RouteServerSubnet = 10.11.8.0/24

# hub2
#----------------------------------------
vnet_name = Hs11-hub2-vnet
vnet_ranges = 10.22.0.0/16
vm_name = Hs11-hub2-vm
vm_ip = 10.22.0.5
AzureFirewallManagementSubnet = 10.22.10.0/24
AzureFirewallSubnet = 10.22.9.0/24
GatewaySubnet = 10.22.7.0/24
Hs11-hub2-dns-in = 10.22.5.0/24
Hs11-hub2-dns-out = 10.22.6.0/24
Hs11-hub2-ilb = 10.22.2.0/24
Hs11-hub2-main = 10.22.0.0/24
Hs11-hub2-nva = 10.22.1.0/24
Hs11-hub2-pep = 10.22.4.0/24
Hs11-hub2-pls = 10.22.3.0/24
RouteServerSubnet = 10.22.8.0/24

# Spoke1
#----------------------------------------
vnet_name = Hs11-spoke1-vnet
vnet_ranges = 10.1.0.0/16
vm_name = Hs11-spoke1-vm
vm_ip = 10.1.0.5
Hs11-spoke1-appgw = 10.1.1.0/24
Hs11-spoke1-ilb = 10.1.2.0/24
Hs11-spoke1-main = 10.1.0.0/24
Hs11-spoke1-pep = 10.1.4.0/24
Hs11-spoke1-pls = 10.1.3.0/24

# spoke2
#----------------------------------------
vnet_name = Hs11-spoke2-vnet
vnet_ranges = 10.2.0.0/16
vm_name = Hs11-spoke2-vm
vm_ip = 10.2.0.5
Hs11-spoke2-appgw = 10.2.1.0/24
Hs11-spoke2-ilb = 10.2.2.0/24
Hs11-spoke2-main = 10.2.0.0/24
Hs11-spoke2-pep = 10.2.4.0/24
Hs11-spoke2-pls = 10.2.3.0/24

# spoke3
#----------------------------------------
vnet_name = Hs11-spoke3-vnet
vnet_ranges = 10.3.0.0/16
vm_name = Hs11-spoke3-vm
vm_ip = 10.3.0.5
Hs11-spoke3-appgw = 10.3.1.0/24
Hs11-spoke3-ilb = 10.3.2.0/24
Hs11-spoke3-main = 10.3.0.0/24
Hs11-spoke3-pep = 10.3.4.0/24
Hs11-spoke3-pls = 10.3.3.0/24

# branch1
#----------------------------------------
vnet_name = Hs11-branch1-vnet
vnet_ranges = 10.10.0.0/16
vm_name = Hs11-branch1-vm
vm_ip = 10.10.0.5
GatewaySubnet = 10.10.3.0/24
Hs11-branch1-ext = 10.10.1.0/24
Hs11-branch1-int = 10.10.2.0/24
Hs11-branch1-main = 10.10.0.0/24
