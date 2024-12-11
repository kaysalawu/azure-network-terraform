
####################################################
# identity
####################################################

resource "azurerm_user_assigned_identity" "hub1_appgw_tcp_int" {
  resource_group_name = azurerm_resource_group.rg.name
  location            = local.hub1_location
  name                = "${local.hub1_prefix}appgw-tcp-int"
}

####################################################
# app gateway (tcp)
####################################################

# app gateway

resource "azapi_resource" "hub1_appgw_tcp_int" {
  type      = "Microsoft.Network/applicationGateways@2024-05-01"
  name      = "${local.hub1_prefix}appgw-tcp-int"
  parent_id = azurerm_resource_group.rg.id
  location  = local.hub1_location
  tags      = local.hub1_tags

  body = {
    properties = {
      sku = {
        name     = "Standard_v2"
        tier     = "Standard_v2"
        family   = "Generation_1"
        capacity = 1
      }
      gatewayIPConfigurations = [
        {
          name = "appGatewayIpConfig"
          properties = {
            subnet = {
              id = module.hub1.subnets["AppGatewaySubnet"].id
            }
          }
        }
      ]
      frontendIPConfigurations = [
        {
          name = "${local.hub1_prefix}appgw-feip-private"
          properties = {
            privateIPAllocationMethod = "Static"
            privateIPAddress          = local.hub1_appgw_addr
            subnet = {
              id = module.hub1.subnets["AppGatewaySubnet"].id
            }
          }
        }
      ]
      frontendPorts = [
        {
          name = "port_80"
          properties = {
            port = 80
          }
        }
      ]
      listeners = [
        {
          name = "${local.hub1_prefix}-appgw-tcp-int-lsn"
          properties = {
            protocol = "Tcp"
            frontendIPConfiguration = {
              id = "subscriptions/${data.azurerm_subscription.current.subscription_id}/resourceGroups/${azurerm_resource_group.rg.name}/providers/Microsoft.Network/applicationGateways/${local.prefix}-appgw-tcp/frontendIPConfigurations/${local.hub1_prefix}appgw-feip-private"
            }
            frontendPort = {
              id = "subscriptions/${data.azurerm_subscription.current.subscription_id}/resourceGroups/${azurerm_resource_group.rg.name}/providers/Microsoft.Network/applicationGateways/${local.prefix}-appgw-tcp/frontendPorts/port_80"
            }
          }
        }
      ]
      backendAddressPools = [
        {
          name = "${local.prefix}-appgw-beap"
          properties = {
            backendAddresses = [
              {
                ipAddress = azurerm_private_endpoint.hub1_spoke1_pls_pep.ip_configuration[0].private_ip_address
              }
            ]
          }
        }
      ]
      probes = [
        {
          name = "${local.prefix}-appgw-probe"
          properties = {
            protocol                            = "Tcp"
            interval                            = 30
            timeout                             = 30
            unhealthyThreshold                  = 3
            pickHostNameFromBackendHttpSettings = false
          }
        }
      ]
      backendSettingsCollection = [
        {
          name = "${local.prefix}-appgw-bes"
          properties = {
            port                           = 80
            protocol                       = "Tcp"
            timeout                        = 20
            pickHostNameFromBackendAddress = false
            trustedRootCertificates        = []
            probe = {
              id = "subscriptions/${data.azurerm_subscription.current.subscription_id}/resourceGroups/${azurerm_resource_group.rg.name}/providers/Microsoft.Network/applicationGateways/${local.prefix}-appgw-tcp/probes/${local.hub1_prefix}appgw-tcp-ext-probe"
            }
          }
        }
      ]
      routingRules = [
        {
          name = "${local.prefix}-appgw-rr"
          properties = {
            ruleType = "Basic"
            priority = 100
            listener = {
              id = "subscriptions/${data.azurerm_subscription.current.subscription_id}/resourceGroups/${azurerm_resource_group.rg.name}/providers/Microsoft.Network/applicationGateways/${local.prefix}-appgw-tcp/listeners/${local.prefix}-appgw-tcp-lsn-private"
            }
            backendAddressPool = {
              id = "subscriptions/${data.azurerm_subscription.current.subscription_id}/resourceGroups/${azurerm_resource_group.rg.name}/providers/Microsoft.Network/applicationGateways/${local.prefix}-appgw-tcp/backendAddressPools/${local.prefix}-appgw-beap"
            }
            backendSettings = {
              id = "subscriptions/${data.azurerm_subscription.current.subscription_id}/resourceGroups/${azurerm_resource_group.rg.name}/providers/Microsoft.Network/applicationGateways/${local.prefix}-appgw-tcp/backendSettingsCollection/${local.prefix}-appgw-bes"
            }
          }
        }
      ]
    }
  }
  schema_validation_enabled = false
}
