
####################################################
# identity
####################################################

resource "azurerm_user_assigned_identity" "hub1_appgw_tcp_ext_uai" {
  resource_group_name = azurerm_resource_group.rg.name
  location            = local.hub1_location
  name                = "${local.hub1_prefix}appgw-tcp-ext-uai"
}

####################################################
# app gateway (tcp)
####################################################

# public ip

resource "azurerm_public_ip" "hub1_appgw_tcp_ext_pip" {
  resource_group_name = azurerm_resource_group.rg.name
  name                = "${local.hub1_prefix}appgw-tcp-ext-pip"
  location            = local.hub1_location
  sku                 = "Standard"
  allocation_method   = "Static"
}

# app gateway

resource "azapi_resource" "hub1_appgw_tcp_ext" {
  type      = "Microsoft.Network/applicationGateways@2024-05-01"
  name      = "${local.hub1_prefix}appgw-tcp-ext"
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
          name = "gw-ipconfig"
          properties = {
            subnet = {
              id = module.hub1.subnets["AppGatewaySubnet"].id
            }
          }
        }
      ]
      frontendIPConfigurations = [
        {
          name = "feip-public"
          properties = {
            publicIPAddress = {
              id = azurerm_public_ip.hub1_appgw_tcp_ext_pip.id
            }
          }
        },
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
          name = "lsn-public-80"
          properties = {
            protocol = "Tcp"
            frontendIPConfiguration = {
              id = "subscriptions/${data.azurerm_subscription.current.subscription_id}/resourceGroups/${azurerm_resource_group.rg.name}/providers/Microsoft.Network/applicationGateways/${local.hub1_prefix}appgw-tcp-ext/frontendIPConfigurations/feip-public"
            }
            frontendPort = {
              id = "subscriptions/${data.azurerm_subscription.current.subscription_id}/resourceGroups/${azurerm_resource_group.rg.name}/providers/Microsoft.Network/applicationGateways/${local.hub1_prefix}appgw-tcp-ext/frontendPorts/port_80"
            }
          }
        },
      ]
      backendAddressPools = [
        {
          name = "beap-spoke1"
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
          name = "probe-spoke1"
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
          name = "bes-spoke1"
          properties = {
            port                           = 80
            protocol                       = "Tcp"
            timeout                        = 20
            pickHostNameFromBackendAddress = false
            trustedRootCertificates        = []
            probe = {
              id = "subscriptions/${data.azurerm_subscription.current.subscription_id}/resourceGroups/${azurerm_resource_group.rg.name}/providers/Microsoft.Network/applicationGateways/${local.hub1_prefix}appgw-tcp-ext/probes/probe-spoke1"
            }
          }
        }
      ]
      routingRules = [
        {
          name = "rr-spoke1"
          properties = {
            ruleType = "Basic"
            priority = 100
            listener = {
              id = "subscriptions/${data.azurerm_subscription.current.subscription_id}/resourceGroups/${azurerm_resource_group.rg.name}/providers/Microsoft.Network/applicationGateways/${local.hub1_prefix}appgw-tcp-ext/listeners/lsn-public-80"
            }
            backendAddressPool = {
              id = "subscriptions/${data.azurerm_subscription.current.subscription_id}/resourceGroups/${azurerm_resource_group.rg.name}/providers/Microsoft.Network/applicationGateways/${local.hub1_prefix}appgw-tcp-ext/backendAddressPools/beap-spoke1"
            }
            backendSettings = {
              id = "subscriptions/${data.azurerm_subscription.current.subscription_id}/resourceGroups/${azurerm_resource_group.rg.name}/providers/Microsoft.Network/applicationGateways/${local.hub1_prefix}appgw-tcp-ext/backendSettingsCollection/bes-spoke1"
            }
          }
        }
      ]
    }
  }
  schema_validation_enabled = false
  depends_on = [
    azurerm_public_ip.hub1_appgw_tcp_ext_pip,
    azurerm_private_endpoint.hub1_spoke1_pls_pep,
  ]
}
