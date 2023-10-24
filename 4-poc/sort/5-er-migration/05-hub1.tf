
# env
#----------------------------

module "hub1" {
  source          = "../../modules/base"
  resource_group  = azurerm_resource_group.rg.name
  prefix          = trimsuffix(local.hub1_prefix, "-")
  location        = local.hub1_location
  storage_account = azurerm_storage_account.region1

  private_dns_zone      = local.hub1_dns_zone
  dns_zone_linked_vnets = {}
  dns_zone_linked_rulesets = {
    "hub1" = azurerm_private_dns_resolver_dns_forwarding_ruleset.hub1_onprem.id
  }

  nsg_subnets = {
    "main" = azurerm_network_security_group.nsg_region1_main.id
    "nva"  = azurerm_network_security_group.nsg_region1_nva.id
    "ilb"  = azurerm_network_security_group.nsg_region1_default.id
    #"dns"  = azurerm_network_security_group.nsg_region1_default.id
  }

  vnet_config = [
    {
      address_space               = local.hub1_address_space
      subnets                     = local.hub1_subnets
      enable_private_dns_resolver = true
      enable_ergw                 = true
      enable_vpngw                = false
      enable_ars                  = false

      vpngw_config = [
        {
          asn = local.hub1_vpngw_asn
        }
      ]
    }
  ]

  vm_config = [
    {
      name        = local.hub1_vm_dns_host
      private_ip  = local.hub1_vm_addr
      custom_data = base64encode(local.vm_startup)
    }
  ]
}

# dns resolver ruleset
#----------------------------

# onprem

resource "azurerm_private_dns_resolver_dns_forwarding_ruleset" "hub1_onprem" {
  resource_group_name                        = azurerm_resource_group.rg.name
  name                                       = "${local.hub1_prefix}onprem"
  location                                   = local.hub1_location
  private_dns_resolver_outbound_endpoint_ids = [module.hub1.private_dns_outbound_ep.id]
}

resource "azurerm_private_dns_resolver_forwarding_rule" "hub1_onprem" {
  name                      = "${local.hub1_prefix}onprem"
  dns_forwarding_ruleset_id = azurerm_private_dns_resolver_dns_forwarding_ruleset.hub1_onprem.id
  domain_name               = "${local.onprem_domain}."
  enabled                   = true
  target_dns_servers {
    ip_address = local.branch2_dns_addr
    port       = 53
  }
}

