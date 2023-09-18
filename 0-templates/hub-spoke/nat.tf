
####################################################
# branch1
####################################################

# lng
#----------------------------

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
/*
# nat
#----------------------------

data "azurerm_virtual_network_gateway" "hub1" {
  resource_group_name = azurerm_resource_group.rg.name
  name                = module.hub1.vpngw.name
}

# egress (static)

resource "azurerm_virtual_network_gateway_nat_rule" "hub1_branch1_static_nat_egress" {
  resource_group_name        = azurerm_resource_group.rg.name
  name                       = "${local.hub1_prefix}branch1-static-nat-egress"
  virtual_network_gateway_id = module.hub1.vpngw.id
  mode                       = "EgressSnat"
  type                       = "Static"

  internal_mapping {
    address_space = local.spoke1_subnets["${local.spoke1_prefix}main"].address_prefixes[0]
  }
  external_mapping {
    address_space = local.hub1_nat_ranges["branch1"]["egress-static"]
  }
}

# egeress (dynamic)

resource "azurerm_virtual_network_gateway_nat_rule" "hub1_branch1_dyn_nat_egress_0" {
  resource_group_name        = azurerm_resource_group.rg.name
  name                       = "${local.hub1_prefix}branch1-dyn-nat-egress-0"
  virtual_network_gateway_id = module.hub1.vpngw.id
  mode                       = "EgressSnat"
  type                       = "Dynamic"
  ip_configuration_id        = data.azurerm_virtual_network_gateway.hub1.ip_configuration.1.id

  internal_mapping {
    address_space = local.spoke1_subnets["${local.spoke1_prefix}main"].address_prefixes[0]
  }
  external_mapping {
    address_space = cidrsubnet(local.hub1_nat_ranges["branch1"]["egress-dynamic"], 2, 0)
  }
}

resource "azurerm_virtual_network_gateway_nat_rule" "hub1_branch1_dyn_nat_egress_1" {
  resource_group_name        = azurerm_resource_group.rg.name
  name                       = "${local.hub1_prefix}branch1-dyn-nat-egress-1"
  virtual_network_gateway_id = module.hub1.vpngw.id
  mode                       = "IngressSnat"
  type                       = "Dynamic"
  ip_configuration_id        = data.azurerm_virtual_network_gateway.hub1.ip_configuration.0.id

  internal_mapping {
    address_space = local.spoke1_subnets["${local.spoke1_prefix}main"].address_prefixes[0]
  }
  external_mapping {
    address_space = cidrsubnet(local.hub1_nat_ranges["branch1"]["egress-dynamic"], 2, 1)
  }
}

# ingress (static)

resource "azurerm_virtual_network_gateway_nat_rule" "hub1_branch1_static_nat_ingress" {
  resource_group_name        = azurerm_resource_group.rg.name
  name                       = "${local.hub1_prefix}branch1-static-nat-ingress"
  virtual_network_gateway_id = module.hub1.vpngw.id
  mode                       = "IngressSnat"
  type                       = "Static"

  internal_mapping {
    address_space = local.branch1_subnets["${local.branch1_prefix}main2"].address_prefixes[0]
  }
  external_mapping {
    address_space = local.hub1_nat_ranges["branch1"]["ingress-static"]
  }
}*/


# lng connection
#----------------------------

resource "azurerm_virtual_network_gateway_connection" "hub1_branch1_lng" {
  resource_group_name        = azurerm_resource_group.rg.name
  name                       = "${local.hub1_prefix}branch1-lng-conn"
  location                   = local.hub1_location
  type                       = "IPsec"
  enable_bgp                 = true
  virtual_network_gateway_id = module.hub1.vpngw.id
  local_network_gateway_id   = azurerm_local_network_gateway.hub1_branch1_lng.id
  shared_key                 = local.psk
  egress_nat_rule_ids = [
    #azurerm_virtual_network_gateway_nat_rule.hub1_branch1_static_nat_egress.id,
    #azurerm_virtual_network_gateway_nat_rule.hub1_branch1_dyn_nat_egress_0.id,
    #azurerm_virtual_network_gateway_nat_rule.hub1_branch1_dyn_nat_egress_1.id,
  ]
  ingress_nat_rule_ids = [
    #azurerm_virtual_network_gateway_nat_rule.hub1_branch1_static_nat_ingress.id,
  ]
}
