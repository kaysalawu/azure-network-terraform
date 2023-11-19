
####################################################
# spoke1
####################################################

# udr
#----------------------------

# main

module "spoke1_udr_main" {
  source                        = "../../modules/udr"
  resource_group                = azurerm_resource_group.rg.name
  prefix                        = "${local.spoke1_prefix}main"
  location                      = local.spoke1_location
  subnet_id                     = module.spoke1.subnets["MainSubnet"].id
  next_hop_type                 = "VirtualAppliance"
  next_hop_in_ip_address        = module.hub1.firewall_private_ip
  disable_bgp_route_propagation = true

  destinations = merge(
    local.default_udr_destinations,
    { "hub1" = local.hub1_address_space[0] }
  )
  depends_on = [
    module.hub1,
  ]
}

####################################################
# spoke2
####################################################

# udr
#----------------------------

# main

module "spoke2_udr_main" {
  source                        = "../../modules/udr"
  resource_group                = azurerm_resource_group.rg.name
  prefix                        = "${local.spoke2_prefix}main"
  location                      = local.spoke2_location
  subnet_id                     = module.spoke2.subnets["MainSubnet"].id
  next_hop_type                 = "VirtualAppliance"
  next_hop_in_ip_address        = module.hub1.firewall_private_ip
  disable_bgp_route_propagation = true

  destinations = merge(
    local.default_udr_destinations,
    { "hub1" = local.hub1_address_space[0] }
  )
  depends_on = [
    module.hub1,
  ]
}

####################################################
# hub1
####################################################

# udr
#----------------------------

# gateway

module "hub1_udr_gateway" {
  source                 = "../../modules/udr"
  resource_group         = azurerm_resource_group.rg.name
  prefix                 = "${local.hub1_prefix}gateway"
  location               = local.hub1_location
  subnet_id              = module.hub1.subnets["GatewaySubnet"].id
  next_hop_type          = "VirtualAppliance"
  next_hop_in_ip_address = module.hub1.firewall_private_ip
  destinations           = local.hub1_gateway_udr_destinations
  depends_on = [
    module.hub1,
  ]
}

# main

module "hub1_udr_main" {
  source                        = "../../modules/udr"
  resource_group                = azurerm_resource_group.rg.name
  prefix                        = "${local.hub1_prefix}main"
  location                      = local.hub1_location
  subnet_id                     = module.hub1.subnets["MainSubnet"].id
  next_hop_type                 = "VirtualAppliance"
  next_hop_in_ip_address        = module.hub1.firewall_private_ip
  disable_bgp_route_propagation = true

  destinations = merge(
    local.default_udr_destinations,
    {
      "spoke1" = local.spoke1_address_space[0]
      "spoke2" = local.spoke2_address_space[0]
    }
  )
  depends_on = [
    module.hub1,
  ]
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

