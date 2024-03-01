
####################################################
# log analytics workspace
####################################################

data "azurerm_log_analytics_workspace" "this" {
  count               = var.log_analytics_workspace_name != null ? 1 : 0
  name                = var.log_analytics_workspace_name
  resource_group_name = var.resource_group
}

####################################################
# root ca
####################################################

# private key

resource "tls_private_key" "root_ca" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

# root ca cert

resource "tls_self_signed_cert" "root_ca" {
  private_key_pem = tls_private_key.root_ca.private_key_pem
  subject {
    common_name         = "p2s-root-ca"
    organization        = "demo"
    organizational_unit = "cloud network team"
    street_address      = ["mpls chicken road"]
    locality            = "London"
    province            = "England"
    country             = "UK"
  }
  is_ca_certificate     = true
  validity_period_hours = 8760
  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "cert_signing",
  ]
}

# ####################################################
# vpn server configuration
# ####################################################

resource "azurerm_vpn_server_configuration" "this" {
  name                     = "p2s-vpn-server-config"
  resource_group_name      = var.resource_group
  location                 = var.location
  vpn_authentication_types = ["Certificate"]

  client_root_certificate {
    name = "p2s-root-ca"
    public_cert_data = trimspace(replace(replace(
      tls_self_signed_cert.root_ca.cert_pem,
      "-----BEGIN CERTIFICATE-----", ""),
      "-----END CERTIFICATE-----", ""
    ))
  }
}

# resource "pkcs12_from_pem" "root_ca" {
#   cert_pem        = tls_self_signed_cert.root_ca.cert_pem
#   private_key_pem = tls_private_key.root_ca.private_key_pem
#   password        = var.cert_password
# }

# ####################################################
# gateway
# ####################################################

resource "azurerm_point_to_site_vpn_gateway" "this" {
  resource_group_name         = var.resource_group
  name                        = "${var.prefix}p2sgw"
  location                    = var.location
  virtual_hub_id              = var.virtual_hub_id
  vpn_server_configuration_id = azurerm_vpn_server_configuration.this.id
  scale_unit                  = var.scale_unit

  connection_configuration {
    name = "connection-config"

    vpn_client_address_pool {
      address_prefixes = var.vpn_client_configuration["address_space"]
    }
  }
}

####################################################
# client cert
####################################################

module "client_certificates" {
  for_each = { for i in var.vpn_client_configuration["clients"] : i.name => i }
  source   = "../../modules/cert-self-signed"
  name     = "${var.prefix}vpngw-${each.value.name}"
  rsa_bits = 2048
  subject = {
    common_name         = each.value.name
    organization        = "networking"
    organizational_unit = "network team"
    street_address      = "99 mpls chicken road, network avenue"
    locality            = "London"
    province            = "England"
    country             = "UK"
  }

  dns_names          = []
  ca_private_key_pem = tls_private_key.root_ca.private_key_pem
  ca_cert_pem        = tls_self_signed_cert.root_ca.cert_pem
}

# ####################################################
# # diagnostic setting
# ####################################################

# # subscription id
# /*
# data "azurerm_subscription" "this" {}

# locals {
#   vnetgw_id = "/subscriptions/${data.azurerm_subscription.this.subscription_id}/resourceGroups/${var.resource_group}|${azurerm_virtual_network_gateway.this.name}"
# }

# data "external" "check_diag_setting" {
#   program = ["bash", "${path.module}/../../scripts/check_diag_setting.sh", "${local.vnetgw_id}"]
# }*/

# resource "azurerm_monitor_diagnostic_setting" "this" {
#   #count                      = data.external.check_diag_setting.result["exists"] == "true" ? 0 : 1
#   count                      = var.enable_diagnostics && var.create_dashboard ? 1 : 0
#   name                       = "${var.prefix}vpngw-diag"
#   target_resource_id         = azurerm_virtual_network_gateway.this.id
#   log_analytics_workspace_id = data.azurerm_log_analytics_workspace[0].this.id

#   metric {
#     category = "AllMetrics"
#     enabled  = true
#   }

#   dynamic "enabled_log" {
#     for_each = var.log_categories
#     content {
#       category = enabled_log.value
#     }
#   }
#   timeouts {
#     create = "60m"
#   }
# }

# ####################################################
# # dashboard
# ####################################################

# locals {
#   dashboard_vars = {
#     GATEWAY_NAME = azurerm_virtual_network_gateway.this.name
#     GATEWAY_ID   = azurerm_virtual_network_gateway.this.id
#     LOCATION     = var.location
#   }
#   dashboard_properties = templatefile("${path.module}/templates/dashboard.json", local.dashboard_vars)
# }

# resource "azurerm_portal_dashboard" "this" {
#   count                = var.enable_diagnostics && var.create_dashboard ? 1 : 0
#   name                 = "${var.prefix}vpngw-db"
#   resource_group_name  = var.resource_group
#   location             = var.location
#   tags                 = var.tags
#   dashboard_properties = local.dashboard_properties
# }

