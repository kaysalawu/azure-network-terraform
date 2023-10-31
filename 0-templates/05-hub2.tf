
####################################################
# vnet
####################################################

module "hub2" {
  source          = "../../modules/base"
  resource_group  = azurerm_resource_group.rg.name
  prefix          = trimsuffix(local.hub2_prefix, "-")
  env             = "prod"
  location        = local.hub2_location
  storage_account = module.common.storage_accounts["region2"]
  tags = {
    "nodeType" = "hub"
    "env"      = "prod"
  }

  create_private_dns_zone = true
  private_dns_zone_name   = "hub2.${local.cloud_domain}"
  private_dns_zone_linked_external_vnets = {
    "spoke4" = module.spoke4.vnet.id
    "spoke5" = module.spoke5.vnet.id
  }

  nsg_subnet_map = {
    "${local.hub2_prefix}main" = module.common.nsg_main["region2"].id
    "${local.hub2_prefix}nva"  = module.common.nsg_nva["region2"].id
    "${local.hub2_prefix}ilb"  = module.common.nsg_default["region2"].id
  }

  vnet_config = [
    {
      address_space = local.hub2_address_space
      subnets       = local.hub2_subnets
      dns_servers   = [local.hub2_dns_in_addr, local.azuredns, ]

      private_dns_inbound_subnet_name  = "${local.hub2_prefix}dns-in"
      private_dns_outbound_subnet_name = "${local.hub2_prefix}dns-out"

      enable_private_dns_resolver = local.hub2_features.enable_private_dns_resolver
      enable_ars                  = local.hub2_features.enable_ars
      enable_vpn_gateway          = local.hub2_features.enable_vpn_gateway
      enable_er_gateway           = local.hub2_features.enable_er_gateway

      vpn_gateway_sku = "VpnGw2AZ"
      vpn_gateway_asn = local.hub2_vpngw_asn

      create_firewall    = local.hub2_features.create_firewall
      firewall_sku       = local.hub2_features.firewall_sku
      firewall_policy_id = local.hub2_features.firewall_policy_id
    }
  ]
}

####################################################
# dns resolver
####################################################

# ruleset
#---------------------------

# onprem

resource "azurerm_private_dns_resolver_dns_forwarding_ruleset" "hub2" {
  resource_group_name                        = azurerm_resource_group.rg.name
  name                                       = "${local.hub2_prefix}ruleset"
  location                                   = local.hub2_location
  private_dns_resolver_outbound_endpoint_ids = [module.hub2.private_dns_outbound_ep.id]
}

# rules
#---------------------------

# onprem

resource "azurerm_private_dns_resolver_forwarding_rule" "hub2_onprem" {
  name                      = "${local.hub2_prefix}onprem"
  dns_forwarding_ruleset_id = azurerm_private_dns_resolver_dns_forwarding_ruleset.hub2.id
  domain_name               = "${local.onprem_domain}."
  enabled                   = true
  target_dns_servers {
    ip_address = local.branch3_dns_addr
    port       = 53
  }
  target_dns_servers {
    ip_address = local.branch1_dns_addr
    port       = 53
  }
}

# cloud

resource "azurerm_private_dns_resolver_forwarding_rule" "hub2_cloud" {
  name                      = "${local.hub2_prefix}cloud"
  dns_forwarding_ruleset_id = azurerm_private_dns_resolver_dns_forwarding_ruleset.hub2.id
  domain_name               = "${local.cloud_domain}."
  enabled                   = true
  target_dns_servers {
    ip_address = local.hub1_dns_in_addr
    port       = 53
  }
}

# links
#---------------------------

locals {
  dns_zone_linked_rulesets_hub2 = {
    "hub2-onprem" = module.hub2.vnet.id
  }
}

resource "azurerm_private_dns_resolver_virtual_network_link" "hub2_onprem" {
  for_each                  = local.dns_zone_linked_rulesets_hub2
  name                      = "${local.prefix}${each.key}-vnet-link"
  dns_forwarding_ruleset_id = azurerm_private_dns_resolver_dns_forwarding_ruleset.hub2.id
  virtual_network_id        = each.value
}

####################################################
# workload
####################################################

module "hub2_vm" {
  source                = "../../modules/linux"
  resource_group        = azurerm_resource_group.rg.name
  prefix                = local.hub2_prefix
  name                  = "vm"
  location              = local.hub2_location
  subnet                = module.hub2.subnets["${local.hub2_prefix}main"].id
  private_ip            = local.hub2_vm_addr
  enable_public_ip      = true
  custom_data           = base64encode(local.vm_startup)
  storage_account       = module.common.storage_accounts["region2"]
  private_dns_zone_name = "hub2.${local.cloud_domain}"
  delay_creation        = "120s"
  tags                  = local.hub2_tags
  depends_on = [
    module.common,
    module.hub2,
    azurerm_private_dns_resolver_virtual_network_link.hub2_onprem,
  ]
}
