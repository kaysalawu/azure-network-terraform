
####################################################
# vnet
####################################################

module "hub1" {
  source          = "../../modules/base"
  resource_group  = azurerm_resource_group.rg.name
  prefix          = trimsuffix(local.hub1_prefix, "-")
  env             = "prod"
  location        = local.hub1_location
  storage_account = module.common.storage_accounts["region1"]
  tags = {
    "nodeType" = "hub"
    "env"      = "prod"
  }

  create_private_dns_zone = true
  private_dns_zone_name   = "hub1.${local.cloud_domain}"
  private_dns_zone_linked_external_vnets = {
    "spoke1" = module.spoke1.vnet.id
    "spoke2" = module.spoke2.vnet.id
  }

  nsg_subnet_map = {
    "${local.hub1_prefix}main" = module.common.nsg_main["region1"].id
    "${local.hub1_prefix}nva"  = module.common.nsg_nva["region1"].id
    "${local.hub1_prefix}ilb"  = module.common.nsg_default["region1"].id
  }

  vnet_config = [
    {
      address_space = local.hub1_address_space
      subnets       = local.hub1_subnets
      dns_servers   = [local.hub1_dns_in_addr, local.azuredns, ]

      private_dns_inbound_subnet_name  = "${local.hub1_prefix}dns-in"
      private_dns_outbound_subnet_name = "${local.hub1_prefix}dns-out"

      enable_private_dns_resolver = local.hub1_features.enable_private_dns_resolver
      enable_ars                  = local.hub1_features.enable_ars
      enable_vpn_gateway          = local.hub1_features.enable_vpn_gateway
      enable_er_gateway           = local.hub1_features.enable_er_gateway

      vpn_gateway_sku = "VpnGw2AZ"
      vpn_gateway_asn = local.hub1_vpngw_asn

      create_firewall    = local.hub1_features.create_firewall
      firewall_sku       = local.hub1_features.firewall_sku
      firewall_policy_id = local.hub1_features.firewall_policy_id
    }
  ]
}

####################################################
# dns resolver
####################################################

# ruleset
#---------------------------

# onprem

resource "azurerm_private_dns_resolver_dns_forwarding_ruleset" "hub1" {
  resource_group_name                        = azurerm_resource_group.rg.name
  name                                       = "${local.hub1_prefix}ruleset"
  location                                   = local.hub1_location
  private_dns_resolver_outbound_endpoint_ids = [module.hub1.private_dns_outbound_ep.id]
}

# rules
#---------------------------

# onprem

resource "azurerm_private_dns_resolver_forwarding_rule" "hub1_onprem" {
  name                      = "${local.hub1_prefix}onprem"
  dns_forwarding_ruleset_id = azurerm_private_dns_resolver_dns_forwarding_ruleset.hub1.id
  domain_name               = "${local.onprem_domain}."
  enabled                   = true
  target_dns_servers {
    ip_address = local.branch1_dns_addr
    port       = 53
  }
  target_dns_servers {
    ip_address = local.branch3_dns_addr
    port       = 53
  }
}

# cloud

resource "azurerm_private_dns_resolver_forwarding_rule" "hub1_cloud" {
  name                      = "${local.hub1_prefix}cloud"
  dns_forwarding_ruleset_id = azurerm_private_dns_resolver_dns_forwarding_ruleset.hub1.id
  domain_name               = "${local.cloud_domain}."
  enabled                   = true
  target_dns_servers {
    ip_address = local.hub2_dns_in_addr
    port       = 53
  }
}

# links
#---------------------------

locals {
  dns_zone_linked_rulesets_hub1 = {
    "hub1-onprem" = module.hub1.vnet.id
  }
}

resource "azurerm_private_dns_resolver_virtual_network_link" "hub1_onprem" {
  for_each                  = local.dns_zone_linked_rulesets_hub1
  name                      = "${local.prefix}${each.key}-vnet-link"
  dns_forwarding_ruleset_id = azurerm_private_dns_resolver_dns_forwarding_ruleset.hub1.id
  virtual_network_id        = each.value
}

####################################################
# workload
####################################################

module "hub1_vm" {
  source                = "../../modules/linux"
  resource_group        = azurerm_resource_group.rg.name
  prefix                = local.hub1_prefix
  name                  = "vm"
  location              = local.hub1_location
  subnet                = module.hub1.subnets["${local.hub1_prefix}main"].id
  private_ip            = local.hub1_vm_addr
  enable_public_ip      = true
  custom_data           = base64encode(local.vm_startup)
  storage_account       = module.common.storage_accounts["region1"]
  private_dns_zone_name = "hub1.${local.cloud_domain}"
  delay_creation        = "120s"
  tags                  = local.hub1_tags
  depends_on = [
    module.common,
    module.hub1,
    azurerm_private_dns_resolver_virtual_network_link.hub1_onprem,
  ]
}
