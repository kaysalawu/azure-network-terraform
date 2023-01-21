#---------------------------
# Local declarations
#---------------------------
locals {
  frontend_port_name                     = "${var.app_gateway_name}-feport"
  frontend_ip_configuration_public_name  = "${var.app_gateway_name}-feip-public"
  frontend_ip_configuration_private_name = "${var.app_gateway_name}-feip-private"
  gateway_ip_configuration_name          = "${var.app_gateway_name}-gwip-config"

  resource_group_name = element(coalescelist(data.azurerm_resource_group.rgrp.*.name, azurerm_resource_group.rg.*.name, [""]), 0)
  location            = var.location
}

#----------------------------------------------------------
# Resource Group, VNet, Subnet selection & Random Resources
#----------------------------------------------------------
data "azurerm_resource_group" "rgrp" {
  count = var.create_resource_group == false ? 1 : 0
  name  = var.resource_group_name
}

resource "azurerm_resource_group" "rg" {
  count    = var.create_resource_group ? 1 : 0
  name     = lower(var.resource_group_name)
  location = var.location
  tags     = var.tags
}

data "azurerm_virtual_network" "vnet" {
  name                = var.virtual_network_name
  resource_group_name = var.vnet_resource_group_name == null ? local.resource_group_name : var.vnet_resource_group_name
}

data "azurerm_subnet" "snet" {
  name                 = var.subnet_name
  virtual_network_name = data.azurerm_virtual_network.vnet.name
  resource_group_name  = data.azurerm_virtual_network.vnet.resource_group_name
}

data "azurerm_log_analytics_workspace" "logws" {
  count               = var.log_analytics_workspace_name != null ? 1 : 0
  name                = var.log_analytics_workspace_name
  resource_group_name = local.resource_group_name
}

data "azurerm_storage_account" "storeacc" {
  count               = var.storage_account_name != null ? 1 : 0
  name                = var.storage_account_name
  resource_group_name = local.resource_group_name
}

#-----------------------------------
# Public IP for application gateway
#-----------------------------------
resource "azurerm_public_ip" "pip" {
  name                = lower("${var.app_gateway_name}-${var.location}-gw-pip")
  location            = var.location
  resource_group_name = local.resource_group_name
  allocation_method   = var.sku.tier == "Standard" ? "Dynamic" : "Static"
  sku                 = var.sku.tier == "Standard" ? "Basic" : "Standard"
  domain_name_label   = var.domain_name_label
  tags                = var.tags
}

#----------------------------------------------
# Application Gateway with all optional blocks
#----------------------------------------------
resource "azurerm_application_gateway" "main" {
  name                = lower("${var.app_gateway_name}")
  resource_group_name = local.resource_group_name
  location            = var.location
  enable_http2        = var.enable_http2
  zones               = var.zones
  firewall_policy_id  = var.firewall_policy_id != null ? var.firewall_policy_id : null
  tags                = var.tags

  sku {
    name     = var.sku.name
    tier     = var.sku.tier
    capacity = var.autoscale_configuration == null ? var.sku.capacity : null
  }

  /*dynamic "autoscale_configuration" {
    for_each = var.autoscale_configuration != null ? [var.autoscale_configuration] : []
    content {
      min_capacity = lookup(autoscale_configuration.value, "min_capacity")
      max_capacity = lookup(autoscale_configuration.value, "max_capacity")
    }
  }*/

  gateway_ip_configuration {
    name      = local.gateway_ip_configuration_name
    subnet_id = data.azurerm_subnet.snet.id
  }

  frontend_ip_configuration {
    name                 = local.frontend_ip_configuration_public_name
    public_ip_address_id = azurerm_public_ip.pip.id
  }

  frontend_ip_configuration {
    name                          = local.frontend_ip_configuration_private_name
    private_ip_address            = var.private_ip_address != null ? var.private_ip_address : null
    private_ip_address_allocation = var.private_ip_address != null ? "Static" : null
    subnet_id                     = var.private_ip_address != null ? data.azurerm_subnet.snet.id : null
  }

  frontend_port {
    name = "${local.frontend_port_name}-80"
    port = 80
  }

  frontend_port {
    name = "${local.frontend_port_name}-443"
    port = 443
  }

  dynamic "autoscale_configuration" {
    for_each = var.autoscale_configuration != null ? [var.autoscale_configuration] : []
    content {
      min_capacity = lookup(autoscale_configuration.value, "min_capacity")
      max_capacity = lookup(autoscale_configuration.value, "max_capacity")
    }
  }

  #----------------------------------------------------------
  # Backend Address Pool Configuration (Required)
  #----------------------------------------------------------
  dynamic "backend_address_pool" {
    for_each = var.backend_address_pools
    content {
      name         = backend_address_pool.value.name
      fqdns        = backend_address_pool.value.fqdns
      ip_addresses = backend_address_pool.value.ip_addresses
    }
  }

  #----------------------------------------------------------
  # Backend HTTP Settings (Required)
  #----------------------------------------------------------
  dynamic "backend_http_settings" {
    for_each = var.backend_http_settings
    content {
      name                                = backend_http_settings.value.name
      cookie_based_affinity               = lookup(backend_http_settings.value, "cookie_based_affinity", "Disabled")
      affinity_cookie_name                = lookup(backend_http_settings.value, "affinity_cookie_name", null)
      path                                = lookup(backend_http_settings.value, "path", "/")
      port                                = backend_http_settings.value.enable_https ? 443 : 80
      probe_name                          = lookup(backend_http_settings.value, "probe_name", null)
      protocol                            = backend_http_settings.value.enable_https ? "Https" : "Http"
      request_timeout                     = lookup(backend_http_settings.value, "request_timeout", 30)
      host_name                           = backend_http_settings.value.pick_host_name_from_backend_address == false ? lookup(backend_http_settings.value, "host_name") : null
      pick_host_name_from_backend_address = lookup(backend_http_settings.value, "pick_host_name_from_backend_address", false)

      dynamic "authentication_certificate" {
        for_each = backend_http_settings.value.authentication_certificate[*]
        content {
          name = authentication_certificate.value.name
        }
      }

      trusted_root_certificate_names = lookup(backend_http_settings.value, "trusted_root_certificate_names", null)

      dynamic "connection_draining" {
        for_each = backend_http_settings.value.connection_draining[*]
        content {
          enabled           = connection_draining.value.enable_connection_draining
          drain_timeout_sec = connection_draining.value.drain_timeout_sec
        }
      }
    }
  }

  #----------------------------------------------------------
  # HTTP Listener Configuration (Required)
  #----------------------------------------------------------
  dynamic "http_listener" {
    for_each = var.http_listeners
    content {
      name                           = http_listener.value.name
      frontend_ip_configuration_name = local.frontend_ip_configuration_public_name
      frontend_port_name             = http_listener.value.ssl_certificate_name == null ? "${local.frontend_port_name}-80" : "${local.frontend_port_name}-443"
      host_name                      = lookup(http_listener.value, "host_name", null)
      host_names                     = lookup(http_listener.value, "host_names", null)
      protocol                       = http_listener.value.ssl_certificate_name == null ? "Http" : "Https"
      require_sni                    = http_listener.value.ssl_certificate_name != null ? http_listener.value.require_sni : null
      ssl_certificate_name           = http_listener.value.ssl_certificate_name
      firewall_policy_id             = http_listener.value.firewall_policy_id
      ssl_profile_name               = http_listener.value.ssl_profile_name

      dynamic "custom_error_configuration" {
        for_each = http_listener.value.custom_error_configuration != null ? lookup(http_listener.value, "custom_error_configuration", {}) : []
        content {
          custom_error_page_url = lookup(custom_error_configuration.value, "custom_error_page_url", null)
          status_code           = lookup(custom_error_configuration.value, "status_code", null)
        }
      }
    }
  }

  #----------------------------------------------------------
  # Request routing rules Configuration (Required)
  #----------------------------------------------------------
  dynamic "request_routing_rule" {
    for_each = var.request_routing_rules
    content {
      priority                    = request_routing_rule.value.priority
      name                        = request_routing_rule.value.name
      rule_type                   = lookup(request_routing_rule.value, "rule_type", "Basic")
      http_listener_name          = request_routing_rule.value.http_listener_name
      backend_address_pool_name   = request_routing_rule.value.redirect_configuration_name == null ? request_routing_rule.value.backend_address_pool_name : null
      backend_http_settings_name  = request_routing_rule.value.redirect_configuration_name == null ? request_routing_rule.value.backend_http_settings_name : null
      redirect_configuration_name = lookup(request_routing_rule.value, "redirect_configuration_name", null)
      rewrite_rule_set_name       = lookup(request_routing_rule.value, "rewrite_rule_set_name", null)
      url_path_map_name           = lookup(request_routing_rule.value, "url_path_map_name", null)
    }
  }

  #---------------------------------------------------------------
  # Identity block Configuration (Optional)
  # A list with a single user managed identity id to be assigned
  #---------------------------------------------------------------
  dynamic "identity" {
    for_each = var.identity_ids != null ? [1] : []
    content {
      type         = "UserAssigned"
      identity_ids = var.identity_ids
    }
  }

  #----------------------------------------------------------
  # Authentication SSL Certificate Configuration (Optional)
  #----------------------------------------------------------
  dynamic "authentication_certificate" {
    for_each = var.authentication_certificates
    content {
      name = authentication_certificate.value.name
      data = filebase64(authentication_certificate.value.data)
    }
  }

  #----------------------------------------------------------
  # Trusted Root SSL Certificate Configuration (Optional)
  #----------------------------------------------------------
  dynamic "trusted_root_certificate" {
    for_each = var.trusted_root_certificates
    content {
      name = trusted_root_certificate.value.name
      data = filebase64(trusted_root_certificate.value.data)
    }
  }

  #----------------------------------------------------------------------------------------------------------------------------------------------------------------------
  # SSL Policy for Application Gateway (Optional)
  # Application Gateway has three predefined security policies to get the appropriate level of security
  # AppGwSslPolicy20150501 - MinProtocolVersion(TLSv1_0), AppGwSslPolicy20170401 - MinProtocolVersion(TLSv1_1), AppGwSslPolicy20170401S - MinProtocolVersion(TLSv1_2)
  #----------------------------------------------------------------------------------------------------------------------------------------------------------------------
  dynamic "ssl_policy" {
    for_each = var.ssl_policy != null ? [var.ssl_policy] : []
    content {
      disabled_protocols   = var.ssl_policy.policy_type == null && var.ssl_policy.policy_name == null ? var.ssl_policy.disabled_protocols : null
      policy_type          = lookup(var.ssl_policy, "policy_type", "Predefined")
      policy_name          = var.ssl_policy.policy_type == "Predefined" ? var.ssl_policy.policy_name : null
      cipher_suites        = var.ssl_policy.policy_type == "Custom" ? var.ssl_policy.cipher_suites : null
      min_protocol_version = var.ssl_policy.min_protocol_version
    }
  }

  #----------------------------------------------------------
  # SSL Certificate (.pfx) Configuration (Optional)
  #----------------------------------------------------------
  dynamic "ssl_certificate" {
    for_each = var.ssl_certificates
    content {
      name                = ssl_certificate.value.name
      data                = ssl_certificate.value.key_vault_secret_id == null ? filebase64(ssl_certificate.value.data) : null
      password            = ssl_certificate.value.key_vault_secret_id == null ? ssl_certificate.value.password : null
      key_vault_secret_id = lookup(ssl_certificate.value, "key_vault_secret_id", null)
    }
  }

  #----------------------------------------------------------
  # Health Probe (Optional)
  #----------------------------------------------------------
  dynamic "probe" {
    for_each = var.health_probes
    content {
      name                                      = probe.value.name
      host                                      = lookup(probe.value, "host", "127.0.0.1")
      interval                                  = lookup(probe.value, "interval", 30)
      protocol                                  = probe.value.port == 443 ? "Https" : "Http"
      path                                      = lookup(probe.value, "path", "/")
      timeout                                   = lookup(probe.value, "timeout", 30)
      unhealthy_threshold                       = lookup(probe.value, "unhealthy_threshold", 3)
      port                                      = lookup(probe.value, "port", 443)
      pick_host_name_from_backend_http_settings = lookup(probe.value, "pick_host_name_from_backend_http_settings", false)
      minimum_servers                           = lookup(probe.value, "minimum_servers", 0)
    }
  }

  #----------------------------------------------------------
  # URL Path Mappings (Optional)
  #----------------------------------------------------------
  dynamic "url_path_map" {
    for_each = var.url_path_maps
    content {
      name                                = url_path_map.value.name
      default_backend_address_pool_name   = url_path_map.value.default_redirect_configuration_name == null ? url_path_map.value.default_backend_address_pool_name : null
      default_backend_http_settings_name  = url_path_map.value.default_redirect_configuration_name == null ? url_path_map.value.default_backend_http_settings_name : null
      default_redirect_configuration_name = lookup(url_path_map.value, "default_redirect_configuration_name", null)
      default_rewrite_rule_set_name       = lookup(url_path_map.value, "default_rewrite_rule_set_name", null)

      dynamic "path_rule" {
        for_each = lookup(url_path_map.value, "path_rules")
        content {
          name                        = path_rule.value.name
          backend_address_pool_name   = path_rule.value.backend_address_pool_name
          backend_http_settings_name  = path_rule.value.backend_http_settings_name
          paths                       = flatten(path_rule.value.paths)
          redirect_configuration_name = lookup(path_rule.value, "redirect_configuration_name", null)
          rewrite_rule_set_name       = lookup(path_rule.value, "rewrite_rule_set_name", null)
          firewall_policy_id          = lookup(path_rule.value, "firewall_policy_id", null)
        }
      }
    }
  }

  #----------------------------------------------------------
  # Redirect Configuration (Optional)
  #----------------------------------------------------------
  dynamic "redirect_configuration" {
    for_each = var.redirect_configuration
    content {
      name                 = lookup(redirect_configuration.value, "name", null)
      redirect_type        = lookup(redirect_configuration.value, "redirect_type", "Permanent")
      target_listener_name = lookup(redirect_configuration.value, "target_listener_name", null)
      target_url           = lookup(redirect_configuration.value, "target_url", null)
      include_path         = lookup(redirect_configuration.value, "include_path", "true")
      include_query_string = lookup(redirect_configuration.value, "include_query_string", "true")
    }
  }

  #----------------------------------------------------------
  # Custom error configuration (Optional)
  #----------------------------------------------------------
  dynamic "custom_error_configuration" {
    for_each = var.custom_error_configuration
    content {
      custom_error_page_url = lookup(custom_error_configuration.value, "custom_error_page_url", null)
      status_code           = lookup(custom_error_configuration.value, "status_code", null)
    }
  }

  #----------------------------------------------------------
  # Rewrite Rules Set configuration (Optional)
  #----------------------------------------------------------
  dynamic "rewrite_rule_set" {
    for_each = var.rewrite_rule_set
    content {
      name = var.rewrite_rule_set.name

      dynamic "rewrite_rule" {
        for_each = lookup(var.rewrite_rule_set, "rewrite_rules", [])
        content {
          name          = rewrite_rule.value.name
          rule_sequence = rewrite_rule.value.rule_sequence

          dynamic "condition" {
            for_each = lookup(rewrite_rule_set.value, "condition", [])
            content {
              variable    = condition.value.variable
              pattern     = condition.value.pattern
              ignore_case = condition.value.ignore_case
              negate      = condition.value.negate
            }
          }

          dynamic "request_header_configuration" {
            for_each = lookup(rewrite_rule.value, "request_header_configuration", [])
            content {
              header_name  = request_header_configuration.value.header_name
              header_value = request_header_configuration.value.header_value
            }
          }

          dynamic "response_header_configuration" {
            for_each = lookup(rewrite_rule.value, "response_header_configuration", [])
            content {
              header_name  = response_header_configuration.value.header_name
              header_value = response_header_configuration.value.header_value
            }
          }

          dynamic "url" {
            for_each = lookup(rewrite_rule.value, "url", [])
            content {
              path         = url.value.path
              query_string = url.value.query_string
              reroute      = url.value.reroute
            }
          }
        }
      }
    }
  }

  #----------------------------------------------------------
  # Web application Firewall (WAF) configuration (Optional)
  # Tier to be either “WAF” or “WAF V2”
  #----------------------------------------------------------
  dynamic "waf_configuration" {
    for_each = var.waf_configuration != null ? [var.waf_configuration] : []
    content {
      enabled                  = true
      firewall_mode            = lookup(waf_configuration.value, "firewall_mode", "Detection")
      rule_set_type            = "OWASP"
      rule_set_version         = lookup(waf_configuration.value, "rule_set_version", "3.1")
      file_upload_limit_mb     = lookup(waf_configuration.value, "file_upload_limit_mb", 100)
      request_body_check       = lookup(waf_configuration.value, "request_body_check", true)
      max_request_body_size_kb = lookup(waf_configuration.value, "max_request_body_size_kb", 128)

      dynamic "disabled_rule_group" {
        for_each = waf_configuration.value.disabled_rule_group
        content {
          rule_group_name = disabled_rule_group.value.rule_group_name
          rules           = disabled_rule_group.value.rules
        }
      }

      dynamic "exclusion" {
        for_each = waf_configuration.value.exclusion
        content {
          match_variable          = exclusion.value.match_variable
          selector_match_operator = exclusion.value.selector_match_operator
          selector                = exclusion.value.selector
        }
      }
    }
  }

  lifecycle {
    ignore_changes = [
      tags,
    ]
  }
}

#---------------------------------------------------------------
# azurerm monitoring diagnostics - PIP, and Application Gateway
#---------------------------------------------------------------
resource "azurerm_monitor_diagnostic_setting" "pip-diag" {
  count                      = var.log_analytics_workspace_name != null || var.storage_account_name != null ? 1 : 0
  name                       = lower("pip-${var.app_gateway_name}-diag")
  target_resource_id         = azurerm_public_ip.pip.id
  storage_account_id         = var.storage_account_name != null ? data.azurerm_storage_account.storeacc.0.id : null
  log_analytics_workspace_id = data.azurerm_log_analytics_workspace.logws.0.id

  dynamic "log" {
    for_each = var.pip_diag_logs
    content {
      category = log.value
      enabled  = true

      retention_policy {
        enabled = false
        days    = 0
      }
    }
  }

  metric {
    category = "AllMetrics"

    retention_policy {
      enabled = false
      days    = 0
    }
  }

  lifecycle {
    ignore_changes = [log, metric]
  }
}

resource "azurerm_monitor_diagnostic_setting" "agw-diag" {
  count                      = var.log_analytics_workspace_name != null || var.storage_account_name != null ? 1 : 0
  name                       = lower("agw-${var.app_gateway_name}-diag")
  target_resource_id         = azurerm_application_gateway.main.id
  storage_account_id         = var.storage_account_name != null ? data.azurerm_storage_account.storeacc.0.id : null
  log_analytics_workspace_id = data.azurerm_log_analytics_workspace.logws.0.id

  dynamic "log" {
    for_each = var.agw_diag_logs
    content {
      category = log.value
      enabled  = true

      retention_policy {
        enabled = false
        days    = 0
      }
    }
  }

  metric {
    category = "AllMetrics"

    retention_policy {
      enabled = false
      days    = 0
    }
  }

  lifecycle {
    ignore_changes = [log, metric]
  }
}
