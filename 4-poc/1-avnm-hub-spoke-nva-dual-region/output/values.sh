
# hub1
#----------------------------------------
vnet_name = Poc1-hub1-vnet
vnet_ranges = 53.200.112.0/20
vm_name = Poc1-hub1-vm
vm_ip = 53.200.112.5
AzureFirewallManagementSubnet = 53.200.122.0/24
AzureFirewallSubnet = 53.200.121.0/24
GatewaySubnet = 53.200.119.0/24
Poc1-hub1-dns-in = 53.200.117.0/24
Poc1-hub1-dns-out = 53.200.118.0/24
Poc1-hub1-ilb = 53.200.114.0/24
Poc1-hub1-main = 53.200.112.0/24
Poc1-hub1-nva = 53.200.113.0/24
Poc1-hub1-pep = 53.200.116.0/24
Poc1-hub1-pls = 53.200.115.0/24
RouteServerSubnet = 53.200.120.0/24

# hub2
#----------------------------------------
vnet_name = Poc1-hub2-vnet
vnet_ranges = 53.200.224.0/20
vm_name = Poc1-hub2-vm
vm_ip = 53.200.224.5
AzureFirewallManagementSubnet = 53.200.234.0/24
AzureFirewallSubnet = 53.200.233.0/24
GatewaySubnet = 53.200.231.0/24
Poc1-hub2-dns-in = 53.200.229.0/24
Poc1-hub2-dns-out = 53.200.230.0/24
Poc1-hub2-ilb = 53.200.226.0/24
Poc1-hub2-main = 53.200.224.0/24
Poc1-hub2-nva = 53.200.225.0/24
Poc1-hub2-pep = 53.200.228.0/24
Poc1-hub2-pls = 53.200.227.0/24
RouteServerSubnet = 53.200.232.0/24

# Spoke1
#----------------------------------------
vnet_name = Poc1-spoke1-vnet
vnet_ranges = 53.200.16.0/21, 172.16.16.0/21
vm_name = Poc1-spoke1-vm
vm_ip = 53.200.16.5
Poc1-spoke1-appgw = 53.200.17.0/24
Poc1-spoke1-ilb = 53.200.18.0/24
Poc1-spoke1-main = 53.200.16.0/24
Poc1-spoke1-pep = 53.200.20.0/24
Poc1-spoke1-pls = 53.200.19.0/24

# spoke2
#----------------------------------------
vnet_name = Poc1-spoke2-vnet
vnet_ranges = 53.200.24.0/21, 172.16.24.0/21
vm_name = Poc1-spoke2-vm
vm_ip = 53.200.24.5
Poc1-spoke2-appgw = 53.200.25.0/24
Poc1-spoke2-ilb = 53.200.26.0/24
Poc1-spoke2-main = 53.200.24.0/24
Poc1-spoke2-pep = 53.200.28.0/24
Poc1-spoke2-pls = 53.200.27.0/24

# spoke3
#----------------------------------------
vnet_name = Poc1-spoke3-vnet
vnet_ranges = 10.3.0.0/16, 172.16.32.0/21
vm_name = Poc1-spoke3-vm
vm_ip = 10.3.0.5
Poc1-spoke3-appgw = 10.3.1.0/24
Poc1-spoke3-ilb = 10.3.2.0/24
Poc1-spoke3-main = 10.3.0.0/24
Poc1-spoke3-pep = 10.3.4.0/24
Poc1-spoke3-pls = 10.3.3.0/24

# spoke4
#----------------------------------------
vnet_name = Poc1-spoke4-vnet
vnet_ranges = 53.200.40.0/21, 172.16.40.0/21
vm_name = Poc1-spoke4-vm
vm_ip = 53.200.40.5
Poc1-spoke4-appgw = 53.200.41.0/24
Poc1-spoke4-ilb = 53.200.42.0/24
Poc1-spoke4-main = 53.200.40.0/24
Poc1-spoke4-pep = 53.200.44.0/24
Poc1-spoke4-pls = 53.200.43.0/24

# spoke5
#----------------------------------------
vnet_name = Poc1-spoke5-vnet
vnet_ranges = 53.200.56.0/21, 172.16.56.0/21
vm_name = Poc1-spoke5-vm
vm_ip = 53.200.56.5
Poc1-spoke5-appgw = 53.200.57.0/24
Poc1-spoke5-ilb = 53.200.58.0/24
Poc1-spoke5-main = 53.200.56.0/24
Poc1-spoke5-pep = 53.200.60.0/24
Poc1-spoke5-pls = 53.200.59.0/24

# spoke6
#----------------------------------------
vnet_name = Poc1-spoke6-vnet
vnet_ranges = 10.6.0.0/16, 172.16.64.0/21
vm_name = Poc1-spoke6-vm
vm_ip = 10.6.0.5
Poc1-spoke6-appgw = 10.6.1.0/24
Poc1-spoke6-ilb = 10.6.2.0/24
Poc1-spoke6-main = 10.6.0.0/24
Poc1-spoke6-pep = 10.6.4.0/24
Poc1-spoke6-pls = 10.6.3.0/24

# branch1
#----------------------------------------
vnet_name = Poc1-branch1-vnet
vnet_ranges = 10.10.0.0/16
vm_name = Poc1-branch1-vm
vm_ip = 10.10.0.5
GatewaySubnet = 10.10.3.0/24
Poc1-branch1-ext = 10.10.1.0/24
Poc1-branch1-int = 10.10.2.0/24
Poc1-branch1-main = 10.10.0.0/24

# branch3
#----------------------------------------
vnet_name = Poc1-branch3-vnet
vnet_ranges = 10.30.0.0/16
vm_name = Poc1-branch3-vm
vm_ip = 10.30.0.5
GatewaySubnet = 10.30.3.0/24
Poc1-branch3-ext = 10.30.1.0/24
Poc1-branch3-int = 10.30.2.0/24
Poc1-branch3-main = 10.30.0.0/24
