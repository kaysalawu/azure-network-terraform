locals {
  hub1_bgp_asn       = module.hub1.vpngw.bgp_settings[0].asn
  hub1_vpngw_bgp_ip0 = module.hub1.vpngw.bgp_settings[0].peering_addresses[0].default_addresses[0]
  hub1_vpngw_bgp_ip1 = module.hub1.vpngw.bgp_settings[0].peering_addresses[1].default_addresses[0]
  hub1_firewall_ip   = module.hub1.firewall.ip_configuration[0].private_ip_address
}

####################################################
# spoke1
####################################################

# udr
#----------------------------

module "spoke1_udr_main" {
  source                 = "../../modules/udr"
  resource_group         = azurerm_resource_group.rg.name
  prefix                 = "${local.spoke1_prefix}main"
  location               = local.spoke1_location
  subnet_id              = module.spoke1.subnets["MainSubnet"].id
  next_hop_type          = "VirtualAppliance"
  next_hop_in_ip_address = module.hub1.firewall_private_ip
  destinations           = local.main_udr_destinations
  depends_on             = [module.hub1]
}

####################################################
# spoke2
####################################################

# udr
#----------------------------

module "spoke2_udr_main" {
  source                 = "../../modules/udr"
  resource_group         = azurerm_resource_group.rg.name
  prefix                 = "${local.spoke2_prefix}main"
  location               = local.spoke2_location
  subnet_id              = module.spoke2.subnets["MainSubnet"].id
  next_hop_type          = "VirtualAppliance"
  next_hop_in_ip_address = module.hub1.firewall_private_ip
  destinations           = local.main_udr_destinations
  depends_on             = [module.hub1]
}

####################################################
# hub1
####################################################

# udr

module "hub1_udr_gateway" {
  source                 = "../../modules/udr"
  resource_group         = azurerm_resource_group.rg.name
  prefix                 = "${local.hub1_prefix}gateway"
  location               = local.hub1_location
  subnet_id              = module.hub1.subnets["GatewaySubnet"].id
  next_hop_type          = "VirtualAppliance"
  next_hop_in_ip_address = module.hub1.firewall_private_ip
  destinations           = local.hub1_gateway_udr_destinations
  depends_on             = [module.hub1, ]
}

module "hub1_udr_main" {
  source                 = "../../modules/udr"
  resource_group         = azurerm_resource_group.rg.name
  prefix                 = "${local.hub1_prefix}main"
  location               = local.hub1_location
  subnet_id              = module.hub1.subnets["MainSubnet"].id
  next_hop_type          = "VirtualAppliance"
  next_hop_in_ip_address = module.hub1.firewall_private_ip
  destinations           = local.main_udr_destinations
  depends_on             = [module.hub1, ]
}

####################################################
# vpn-site connection
####################################################

# lng
#----------------------------

# branch1

resource "azurerm_local_network_gateway" "hub1_branch1_lng" {
  resource_group_name = azurerm_resource_group.rg.name
  name                = "${local.hub1_prefix}branch1-lng"
  location            = local.hub1_location
  gateway_address     = azurerm_public_ip.branch1_nva_pip.ip_address
  address_space       = ["${local.branch1_nva_loopback0}/32", ]
  bgp_settings {
    asn                 = local.branch1_nva_asn
    bgp_peering_address = local.branch1_nva_loopback0
  }
}

# branch3

resource "azurerm_local_network_gateway" "hub1_branch3_lng" {
  resource_group_name = azurerm_resource_group.rg.name
  name                = "${local.hub1_prefix}branch3-lng"
  location            = local.hub1_location
  gateway_address     = azurerm_public_ip.branch3_nva_pip.ip_address
  address_space       = ["${local.branch3_nva_loopback0}/32", ]
  bgp_settings {
    asn                 = local.branch3_nva_asn
    bgp_peering_address = local.branch3_nva_loopback0
  }
}

# lng connection
#----------------------------

# branch1

resource "azurerm_virtual_network_gateway_connection" "hub1_branch1_lng" {
  resource_group_name        = azurerm_resource_group.rg.name
  name                       = "${local.hub1_prefix}branch1-lng-conn"
  location                   = local.hub1_location
  type                       = "IPsec"
  enable_bgp                 = true
  virtual_network_gateway_id = module.hub1.vpngw.id
  local_network_gateway_id   = azurerm_local_network_gateway.hub1_branch1_lng.id
  shared_key                 = local.psk
  egress_nat_rule_ids        = []
  ingress_nat_rule_ids       = []
}

# branch3

resource "azurerm_virtual_network_gateway_connection" "hub1_branch3_lng" {
  resource_group_name        = azurerm_resource_group.rg.name
  name                       = "${local.hub1_prefix}branch3-lng-conn"
  location                   = local.hub1_location
  type                       = "IPsec"
  enable_bgp                 = true
  virtual_network_gateway_id = module.hub1.vpngw.id
  local_network_gateway_id   = azurerm_local_network_gateway.hub1_branch3_lng.id
  shared_key                 = local.psk
  egress_nat_rule_ids        = []
  ingress_nat_rule_ids       = []
}

####################################################
# output files
####################################################

locals {
  hub1_files = {}
}

resource "local_file" "hub1_files" {
  for_each = local.hub1_files
  filename = each.key
  content  = each.value
}

