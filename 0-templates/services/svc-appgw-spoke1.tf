
locals {
  spoke1_host_http_80   = "http80-${azurerm_public_ip.spoke1_appgw_pip.ip_address}.nip.io"
  spoke1_host_http_8080 = "http8080-${azurerm_public_ip.spoke1_appgw_pip.ip_address}.nip.io"
}

####################################################
# addresses
####################################################

resource "azurerm_public_ip" "spoke1_appgw_pip" {
  resource_group_name = azurerm_resource_group.rg.name
  name                = "${local.spoke1_prefix}appgw-pip"
  location            = local.spoke1_location
  sku                 = "Standard"
  allocation_method   = "Static"
}

####################################################
# identity
####################################################

resource "azurerm_user_assigned_identity" "spoke1_appgw_http" {
  resource_group_name = azurerm_resource_group.rg.name
  location            = local.spoke1_location
  name                = "${local.spoke1_prefix}appgw-api"
}

####################################################
# app gateway
####################################################

module "spoke1_appgw" {
  source                 = "../../modules/application-gateway"
  resource_group_name    = azurerm_resource_group.rg.name
  location               = local.spoke1_location
  app_gateway_name       = "${local.spoke1_prefix}appgw"
  virtual_network_name   = module.spoke1.vnet.name
  subnet_name            = module.spoke1.subnets["AppGatewaySubnet"].name
  private_ip_address     = local.spoke1_appgw_addr
  public_ip_address_name = azurerm_public_ip.spoke1_appgw_pip.name

  sku = {
    name     = "WAF_v2"
    tier     = "WAF_v2"
    capacity = 2
  }

  backend_address_pools = [
    { name = "http-80-beap", ip_addresses = [module.spoke1_vm.private_ip_address, ] },
    { name = "http-8080-beap", ip_addresses = [module.spoke1_vm.private_ip_address, ] },
  ]

  backend_http_settings = [
    { name = "http-80-bhs", port = 80, path = "/", probe_name = "http-80-hp" },
    { name = "http-8080-bhs", port = 8080, path = "/", probe_name = "http-8080-hp" },
  ]

  health_probes = [
    { name = "http-80-hp", host = local.spoke1_host_http_80, protocol = "Http", port = 80, path = "/" },
    { name = "http-8080-hp", host = local.spoke1_host_http_8080, protocol = "Http", port = 8080, path = "/" },
  ]

  http_listeners = [
    {
      name               = "http-80-http-lsn"
      host_name          = local.spoke1_host_http_80
      firewall_policy_id = azurerm_web_application_firewall_policy.spoke1_appgw.id
    },
    {
      name      = "http-8080-http-lsn"
      host_name = local.spoke1_host_http_8080
    },
  ]

  request_routing_rules = [
    {
      priority           = 100
      name               = "http-80-http-rrr"
      http_listener_name = "http-80-http-lsn"
      rule_type          = "PathBasedRouting"
      url_path_map_name  = "http-80-upm"
    },
    {
      priority                   = 200
      name                       = "http-8080-http-rrr"
      http_listener_name         = "http-8080-http-lsn"
      backend_address_pool_name  = "http-8080-beap"
      backend_http_settings_name = "http-8080-bhs"
      rule_type                  = "Basic"
    },
  ]

  url_path_maps = [
    {
      name                               = "http-80-upm"
      default_backend_http_settings_name = "http-80-bhs"
      default_backend_address_pool_name  = "http-80-beap"
      path_rules = [
        {
          name                       = "http-80-pr"
          paths                      = ["/*"]
          backend_address_pool_name  = "http-80-beap"
          backend_http_settings_name = "http-80-bhs"
          firewall_policy_id         = azurerm_web_application_firewall_policy.spoke1_appgw.id
        },
      ]
    }
  ]

  log_analytics_workspace_name = module.common.log_analytics_workspaces["region1"].name
  identity_ids                 = ["${azurerm_user_assigned_identity.spoke1_appgw_http.id}"]

  depends_on = [
    module.spoke1,
  ]
}


####################################################
# app gateway waf policy
####################################################

resource "azurerm_web_application_firewall_policy" "spoke1_appgw" {
  name                = "${local.spoke1_prefix}appgw"
  resource_group_name = azurerm_resource_group.rg.name
  location            = local.spoke1_location

  policy_settings {
    enabled                     = true
    mode                        = "Prevention"
    request_body_check          = true
    file_upload_limit_in_mb     = 100
    max_request_body_size_in_kb = 128
  }

  custom_rules {
    name      = "Rule1"
    priority  = 1
    rule_type = "MatchRule"
    action    = "Block"

    match_conditions {
      match_variables {
        variable_name = "RemoteAddr"
      }
      operator           = "IPMatch"
      negation_condition = false
      match_values       = ["192.168.1.0/24", "10.0.0.0/24"]
    }
  }

  custom_rules {
    name      = "Rule2"
    priority  = 2
    rule_type = "MatchRule"
    action    = "Block"

    match_conditions {
      match_variables {
        variable_name = "RemoteAddr"
      }
      operator           = "IPMatch"
      negation_condition = false
      match_values       = ["192.168.1.0/24"]
    }

    match_conditions {
      match_variables {
        variable_name = "RequestHeaders"
        selector      = "UserAgent"
      }
      operator           = "Contains"
      negation_condition = false
      match_values       = ["Windows"]
    }
  }

  managed_rules {
    exclusion {
      match_variable          = "RequestHeaderNames"
      selector                = "x-company-secret-header"
      selector_match_operator = "Equals"
    }
    exclusion {
      match_variable          = "RequestCookieNames"
      selector                = "too-tasty"
      selector_match_operator = "EndsWith"
    }

    managed_rule_set {
      type    = "OWASP"
      version = "3.2"
      rule_group_override {
        rule_group_name = "REQUEST-920-PROTOCOL-ENFORCEMENT"
        rule {
          id      = "920300"
          enabled = true
          action  = "Log"
        }

        rule {
          id      = "920440"
          enabled = true
          action  = "Block"
        }
      }
    }
  }
}

####################################################
# outputs
####################################################

output "spoke1_appgw" {
  value = {
    spoke1_host_http_80   = local.spoke1_host_http_80
    spoke1_host_http_8080 = local.spoke1_host_http_8080
  }
}
