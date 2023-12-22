
locals {
  hub1_cert_name_app1   = "app1"
  hub1_cert_name_app2   = "app2"
  hub1_cert_output_path = "certs/hub1"
  hub1_app1_host        = "app1.we.az.corp"
  hub1_app2_host        = "app2.we.az.corp"
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

# data "azurerm_monitor_diagnostic_categories" "example" {
#   resource_id = module.hub1_appgw.application_gateway_id
# }

# output "test" {
#   value = data.azurerm_monitor_diagnostic_categories.example
# }

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
      name = "app1-beap",
      ip_addresses = [
        local.spoke1_ilb_addr,
      ]
    },
    {
      name = "app2-beap",
      ip_addresses = [
        local.spoke1_ilb_addr,
      ]
    },
  ]

  trusted_root_certificates = [
    {
      name = "hub1-root-ca"
      data = base64encode(tls_self_signed_cert.root_ca.cert_pem)
    },
  ]

  backend_http_settings = [
    {
      name                  = "app1-bhs"
      cookie_based_affinity = "Disabled"
      protocol              = "Https"
      port                  = 8080
      path                  = "/"
      probe_name            = "app1-hp"
      enable_https          = false
      request_timeout       = 30
      connection_draining = {
        enable_connection_draining = true
        drain_timeout_sec          = 300

      }
      trusted_root_certificate_names = [
        "hub1-root-ca"
      ]
    },
    {
      name                  = "app2-bhs"
      cookie_based_affinity = "Disabled"
      protocol              = "Http"
      port                  = 8081
      path                  = "/"
      probe_name            = "app2-hp"
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
      name                = "app1-hp"
      host                = "healthz.az.corp"
      protocol            = "Https"
      port                = 8080
      path                = "/healthz"
      interval            = 30
      timeout             = 30
      unhealthy_threshold = 3
    },
    {
      name                = "app2-hp"
      host                = "healthz.az.corp"
      port                = 8081
      protocol            = "Http"
      path                = "/healthz"
      interval            = 30
      timeout             = 30
      unhealthy_threshold = 3
    },
  ]

  http_listeners = [
    {
      name                 = "app1-lsn"
      host_name            = local.hub1_app1_host
      ssl_certificate_name = module.hub1_appgw_app1_cert.cert_name
    },
    {
      name      = "app2-lsn"
      host_name = local.hub1_app2_host
    },
  ]

  request_routing_rules = [
    {
      priority                   = 100
      name                       = "app1-rrr"
      rule_type                  = "PathBasedRouting"
      http_listener_name         = "app1-lsn"
      backend_address_pool_name  = "app1-beap"
      backend_http_settings_name = "app1-bhs"
    },
    {
      priority                   = 200
      name                       = "app2-rrr"
      rule_type                  = "PathBasedRouting"
      http_listener_name         = "app2-lsn"
      backend_address_pool_name  = "app2-beap"
      backend_http_settings_name = "app2-bhs"
    },
  ]

  ssl_certificates = [
    {
      name     = module.hub1_appgw_app1_cert.cert_name
      data     = module.hub1_appgw_app1_cert.cert_pfx
      password = module.hub1_appgw_app1_cert.password
    },
  ]

  log_analytics_workspace_name = module.common.log_analytics_workspaces["region1"].name

  identity_ids = [
    "${azurerm_user_assigned_identity.hub1_appgw_http.id}"
  ]

  depends_on = [
    azurerm_resource_group.rg,
    module.hub1,
  ]
}

####################################################
# cert - app1
####################################################

module "hub1_appgw_app1_cert" {
  source   = "../../modules/self-signed-cert"
  name     = local.hub1_cert_name_app1
  rsa_bits = 2048
  subject = {
    common_name         = local.hub1_app1_host
    organization        = "app1 demo"
    organizational_unit = "app1 network team"
    street_address      = "99 mpls chicken road, network avenue"
    locality            = "London"
    province            = "England"
    country             = "UK"
  }
  dns_names = [
    local.hub1_app1_host,
  ]
  ca_private_key_pem = tls_private_key.root_ca.private_key_pem
  ca_cert_pem        = tls_self_signed_cert.root_ca.cert_pem
  cert_output_path   = local.hub1_cert_output_path
}

