
####################################################
# base
####################################################

module "hub2" {
  source          = "../../modules/base"
  resource_group  = azurerm_resource_group.rg.name
  prefix          = trimsuffix(local.hub2_prefix, "-")
  location        = local.hub2_location
  storage_account = module.common.storage_accounts["region2"]

  private_dns_zone_name = azurerm_private_dns_zone.global.name
  private_dns_prefix    = local.hub2_dns_zone

  nsg_subnet_map = {
    "${local.hub2_prefix}main" = module.common.nsg_main["region2"].id
    "${local.hub2_prefix}nva"  = module.common.nsg_nva["region2"].id
    "${local.hub2_prefix}ilb"  = module.common.nsg_default["region2"].id
  }

  vnet_config = [
    {
      address_space = local.hub2_address_space
      subnets       = local.hub2_subnets

      private_dns_inbound_subnet_name  = "${local.hub2_prefix}dns-in"
      private_dns_outbound_subnet_name = "${local.hub2_prefix}dns-out"

      enable_private_dns_resolver = local.hub2_features.enable_private_dns_resolver
      enable_ars                  = local.hub2_features.enable_ars
      enable_vpn_gateway          = local.hub2_features.enable_vpn_gateway
      enable_er_gateway           = local.hub2_features.enable_er_gateway

      vpn_gateway_sku = "VpnGw2AZ"
      vpn_gateway_asn = local.hub2_vpngw_asn

      enable_firewall    = local.hub2_features.enable_firewall
      firewall_sku       = local.hub2_features.firewall_sku
      firewall_policy_id = local.hub2_features.firewall_policy_id
    }
  ]

  vm_config = [
    {
      name         = "vm"
      dns_host     = local.hub2_vm_dns_host
      subnet       = "${local.hub2_prefix}main"
      private_ip   = local.hub2_vm_addr
      custom_data  = base64encode(local.vm_startup)
      source_image = "ubuntu"
    }
  ]
}

####################################################
# dns resolver ruleset
####################################################
/*
# onprem

resource "azurerm_private_dns_resolver_dns_forwarding_ruleset" "hub2_onprem" {
  resource_group_name                        = azurerm_resource_group.rg.name
  name                                       = "${local.hub2_prefix}onprem"
  location                                   = local.hub2_location
  private_dns_resolver_outbound_endpoint_ids = [module.hub2.private_dns_outbound_ep.id]
}

resource "azurerm_private_dns_resolver_forwarding_rule" "hub2_onprem" {
  name                      = "${local.hub2_prefix}onprem"
  dns_forwarding_ruleset_id = azurerm_private_dns_resolver_dns_forwarding_ruleset.hub2_onprem.id
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

resource "azurerm_private_dns_resolver_dns_forwarding_ruleset" "hub2_cloud" {
  resource_group_name                        = azurerm_resource_group.rg.name
  name                                       = "${local.hub2_prefix}cloud"
  location                                   = local.hub2_location
  private_dns_resolver_outbound_endpoint_ids = [module.hub2.private_dns_outbound_ep.id]
}

resource "azurerm_private_dns_resolver_forwarding_rule" "hub2_cloud" {
  name                      = "${local.hub2_prefix}cloud"
  dns_forwarding_ruleset_id = azurerm_private_dns_resolver_dns_forwarding_ruleset.hub2_cloud.id
  domain_name               = "${local.cloud_domain}."
  enabled                   = true
  target_dns_servers {
    ip_address = local.hub2_dns_in_addr
    port       = 53
  }
}
/*
####################################################
# private endpoint
####################################################

resource "azurerm_private_endpoint" "hub2_spoke6_pe" {
  resource_group_name = azurerm_resource_group.rg.name
  name                = "${local.hub2_prefix}spoke6-pe"
  location            = local.hub2_location
  subnet_id           = module.hub2.subnets["${local.hub2_prefix}pep"].id

  private_service_connection {
    name                           = "${local.hub2_prefix}spoke6-pe-psc"
    private_connection_resource_id = module.spoke6_pls.private_link_service_id
    is_manual_connection           = false
  }
}

resource "azurerm_private_dns_a_record" "hub2_spoke6_pe" {
  resource_group_name = azurerm_resource_group.rg.name
  name                = local.hub2_pep_dns_host
  zone_name           = local.hub2_dns_zone
  ttl                 = 300
  records             = [azurerm_private_endpoint.hub2_spoke6_pe.private_service_connection[0].private_ip_address, ]
}*/
