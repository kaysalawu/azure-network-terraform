
module "dns_resolver" {
  source             = "../../modules/private-dns-resolver"
  resource_group     = azurerm_resource_group.rg.name
  prefix             = var.prefix
  env                = var.env
  location           = var.location
  virtual_network_id = var.virtual_network_id
  tags               = var.tags

  private_dns_inbound_subnet_id  = azurerm_subnet.private_dns_inbound_subnet.id
  private_dns_outbound_subnet_id = azurerm_subnet.private_dns_outbound_subnet.id

  private_dns_ruleset_linked_external_vnets = {
    "spoke1" = azurerm_virtual_network.spoke1.id
    "spoke2" = azurerm_virtual_network.spoke2.id
  }

  ruleset_dns_forwarding_rules = {
    "onprem-zones" = {
      domain = local.onprem_domain
      target_dns_servers = [
        { ip_address = "10.30.0.6", port = 53 },
        { ip_address = "10.10.0.6", port = 53 },
      ]
    }
    "hub1-zones" = {
      domain = "we.${local.cloud_domain}"
      target_dns_servers = [
        { ip_address = "10.11.1.4", port = 53 },
      ]
    }
    "hub2-zones" = {
      domain = "ne.${local.cloud_domain}"
      target_dns_servers = [
        { ip_address = "10.22.1.4", port = 53 },
      ]
    }
  }
}
