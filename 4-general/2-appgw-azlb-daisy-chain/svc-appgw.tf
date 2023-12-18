
locals {
  cert_name_wdp  = "wdp"
  cert_name_pace = "pace"
}

####################################################
# vault
####################################################

resource "azurerm_user_assigned_identity" "hub1_appgw_http" {
  resource_group_name = azurerm_resource_group.rg.name
  location            = local.hub1_location
  name                = "${local.hub1_prefix}appgw-api"
}

# module "key_vault" {
#   source  = "kumarvna/key-vault/azurerm"
#   version = "2.1.0"

#   resource_group_name        = azurerm_resource_group.rg.name
#   key_vault_name             = "${local.hub1_prefix}appgw"
#   key_vault_sku_pricing_tier = "standard"
#   enable_purge_protection    = false

#   access_policies = [
#     {
#       azure_ad_user_principal_names = [azurerm_user_assigned_identity.hub1_appgw_http.name, ]
#       key_permissions               = ["get", "list"]
#       secret_permissions            = ["get", "list"]
#       certificate_permissions       = ["get", "import", "list"]
#       storage_permissions           = ["backup", "get", "list", "recover"]
#     },
#   ]
# }

####################################################
# app gateway
####################################################

module "hub1_appgw" {
  source               = "../../modules/appgw"
  resource_group_name  = azurerm_resource_group.rg.name
  location             = local.hub1_location
  app_gateway_name     = "${local.hub1_prefix}appgw"
  virtual_network_name = module.hub1.vnet.name
  subnet_name          = module.hub1.subnets["AppGatewaySubnet"].name
  private_ip_address   = local.hub1_appgw_addr

  sku = {
    name     = "Standard_v2"
    tier     = "Standard_v2"
    capacity = 2
  }

  backend_address_pools = [
    {
      name = "wdp-beap",
      ip_addresses = [
        module.spoke1_be1.private_ip_address,
        module.spoke1_be2.private_ip_address
      ]
    },
    {
      name = "pace-beap",
      ip_addresses = [
        module.spoke1_be1.private_ip_address,
        module.spoke1_be2.private_ip_address
      ]
    },
  ]

  backend_http_settings = [
    {
      name                  = "wdp-bhs"
      cookie_based_affinity = "Disabled"
      protocol              = "Http"
      port                  = 8080
      path                  = "/"
      probe_name            = "wdp-hp"
      enable_https          = false
      request_timeout       = 30
      connection_draining = {
        enable_connection_draining = true
        drain_timeout_sec          = 300

      }
    },
    {
      name                  = "pace-bhs"
      cookie_based_affinity = "Disabled"
      protocol              = "Http"
      port                  = 8081
      path                  = "/"
      probe_name            = "pace-hp"
      enable_https          = false
      request_timeout       = 30
      connection_draining = {
        enable_connection_draining = true
        drain_timeout_sec          = 300

      }
    },
  ]

  health_probes = [
    {
      name                = "wdp-hp"
      host                = "healthz.az.corp"
      protocol            = "Http"
      port                = 8080
      request_path        = "/healthz"
      interval            = 30
      timeout             = 30
      unhealthy_threshold = 3
    },
    {
      name                = "pace-hp"
      host                = "healthz.az.corp"
      port                = 8081
      protocol            = "Http"
      request_path        = "/healthz"
      interval            = 30
      timeout             = 30
      unhealthy_threshold = 3
    },
  ]

  http_listeners = [
    {
      name                 = "wdp-lsn"
      host_name            = "wdp.we.az.corp"
      ssl_certificate_name = module.hub1_appgw_wdp_cert.cert_name
    },
    {
      name      = "pace-lsn"
      host_name = "pace.we.az.corp"
    },
  ]

  request_routing_rules = [
    {
      priority                   = 100
      name                       = "wdp-rrr"
      rule_type                  = "Basic"
      http_listener_name         = "wdp-lsn"
      backend_address_pool_name  = "wdp-beap"
      backend_http_settings_name = "wdp-bhs"
    },
    {
      priority                   = 200
      name                       = "pace-rrr"
      rule_type                  = "Basic"
      http_listener_name         = "pace-lsn"
      backend_address_pool_name  = "pace-beap"
      backend_http_settings_name = "pace-bhs"
    },
  ]

  ssl_certificates = [
    {
      name     = local.cert_name_wdp
      data     = module.hub1_appgw_wdp_cert.cert_pfx_path
      password = module.hub1_appgw_wdp_cert.password
    },
  ]

  identity_ids = ["${azurerm_user_assigned_identity.hub1_appgw_http.id}"]
  #log_analytics_workspace_name = azurerm_log_analytics_workspace.analytics_ws.name
  depends_on = [
    azurerm_resource_group.rg,
    module.hub1
  ]
}

####################################################
# cert - root ca
####################################################

# private key

resource "tls_private_key" "hub1_root_ca" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

# root ca cert

resource "tls_self_signed_cert" "hub1_root_ca" {
  private_key_pem = tls_private_key.hub1_root_ca.private_key_pem
  subject {
    common_name         = "Self Root CA"
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

####################################################
# cert - wdp
####################################################

module "hub1_appgw_wdp_cert" {
  source = "../../modules/self-signed-cert"
  name   = local.cert_name_wdp
  subject = {
    common_name         = "wdp labs"
    organization        = "wdp demo"
    organizational_unit = "wdp network team"
    street_address      = "99 mpls chicken road, network avenue"
    locality            = "London"
    province            = "England"
    country             = "UK"
  }
  dns_names = [
    "wdp.we.az.corp",
  ]
  ca_private_key_pem = tls_private_key.hub1_root_ca.private_key_pem
  ca_cert_pem        = tls_self_signed_cert.hub1_root_ca.cert_pem
  cert_output_path   = "certs"
}


####################################################
# cert - pace
####################################################

module "hub1_appgw_pace_cert" {
  source = "../../modules/self-signed-cert"
  name   = local.cert_name_pace
  subject = {
    common_name         = "pace labs"
    organization        = "pace demo"
    organizational_unit = "pace network team"
    street_address      = "99 mpls chicken road, network avenue"
    locality            = "London"
    province            = "England"
    country             = "UK"
  }
  dns_names = [
    "pace.we.az.corp",
  ]
  ca_private_key_pem = tls_private_key.hub1_root_ca.private_key_pem
  ca_cert_pem        = tls_self_signed_cert.hub1_root_ca.cert_pem
  cert_output_path   = "certs"
}
