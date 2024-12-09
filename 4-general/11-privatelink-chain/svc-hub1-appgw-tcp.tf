
####################################################
# identity
####################################################

resource "azurerm_user_assigned_identity" "hub1_appgw_http" {
  resource_group_name = azurerm_resource_group.rg.name
  location            = local.hub1_location
  name                = "${local.hub1_prefix}appgw-api"
}

####################################################
# app gateway (tcp)
####################################################

# public ip

resource "azurerm_public_ip" "hub1_appgw_pip" {
  resource_group_name = azurerm_resource_group.rg.name
  name                = "${local.hub1_prefix}appgw-pip"
  location            = local.hub1_location
  sku                 = "Standard"
  allocation_method   = "Static"
}

# app gateway

resource "azapi_resource" "hub1_appgw_tcp" {
  type      = "Microsoft.Network/applicationGateways@2024-05-01"
  name      = "${local.prefix}-appgw-tcp"
  parent_id = azurerm_resource_group.rg.id
  location  = local.hub1_location
  tags      = local.hub1_tags
  # identity = {
  #   type = "string"
  #   userAssignedIdentities = {
  #     "${azurerm_user_assigned_identity.hub1_appgw_http.id}" = {}
  #   }
  # }
  # zones = [1, 2, 3, ]

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
          name = "${local.prefix}-appgw-feip-public"
          properties = {
            publicIPAddress = {
              id = azurerm_public_ip.hub1_appgw_pip.id
            }
            # listeners = [
            #   {
            #     id = "subscriptions/${data.azurerm_subscription.current.subscription_id}/resourceGroups/${azurerm_resource_group.rg.name}/providers/Microsoft.Network/applicationGateways/${local.prefix}-appgw-tcp/listeners/${local.prefix}-appgw-tcp-lsn"
            #   }
            # ]
          }
        },
        {
          name = "${local.prefix}-appgw-feip-private"
          properties = {
            privateIPAllocationMethod = "Static"
            privateIPAddress          = local.hub1_appgw_addr
            subnet = {
              id = module.hub1.subnets["AppGatewaySubnet"].id
            }
            listeners = [
              {
                id = "subscriptions/${data.azurerm_subscription.current.subscription_id}/resourceGroups/${azurerm_resource_group.rg.name}/providers/Microsoft.Network/applicationGateways/${local.prefix}-appgw-tcp/listeners/${local.prefix}-appgw-tcp-lsn"
              }
            ]
          }
        }
      ]
      frontendPorts = [
        {
          name = "port_80"
          properties = {
            port = 80
            listeners = [
              {
                id = "subscriptions/${data.azurerm_subscription.current.subscription_id}/resourceGroups/${azurerm_resource_group.rg.name}/providers/Microsoft.Network/applicationGateways/${local.prefix}-appgw-tcp/listeners/${local.prefix}-appgw-tcp-lsn"
              }
            ]
          }
        }
      ]
      listeners = [
        {
          name = "${local.prefix}-appgw-tcp-lsn"
          properties = {
            frontendIPConfiguration = {
              id = "subscriptions/${data.azurerm_subscription.current.subscription_id}/resourceGroups/${azurerm_resource_group.rg.name}/providers/Microsoft.Network/applicationGateways/${local.prefix}-appgw-tcp/frontendIPConfigurations/${local.prefix}-appgw-feip-public"
            }
            frontendPort = {
              id = "subscriptions/${data.azurerm_subscription.current.subscription_id}/resourceGroups/${azurerm_resource_group.rg.name}/providers/Microsoft.Network/applicationGateways/${local.prefix}-appgw-tcp/frontendPorts/port_80"
            }
            protocol = "Tcp"
            # hostNames = []
            # routingRules = [
            #   # {
            #   #   id = ""
            #   # }
            # ]
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
            routingRules = [
              {
                id = "subscriptions/${data.azurerm_subscription.current.subscription_id}/resourceGroups/${azurerm_resource_group.rg.name}/providers/Microsoft.Network/applicationGateways/${local.prefix}-appgw-tcp/routingRules/${local.prefix}-appgw-rr"

              }
            ]
          }
        }
      ]
      backendSettingsCollection = [
        {
          name = "${local.prefix}-appgw-bes"
          properties = {
            port     = 80
            protocol = "Tcp"
            timeout  = 20
            routingRules = [
              {
                id = "subscriptions/${data.azurerm_subscription.current.subscription_id}/resourceGroups/${azurerm_resource_group.rg.name}/providers/Microsoft.Network/applicationGateways/${local.prefix}-appgw-tcp/routingRules/${local.prefix}-appgw-rr"
              }
            ]
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
              id = "subscriptions/${data.azurerm_subscription.current.subscription_id}/resourceGroups/${azurerm_resource_group.rg.name}/providers/Microsoft.Network/applicationGateways/${local.prefix}-appgw-tcp/listeners/${local.prefix}-appgw-tcp-lsn"
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
      probes = [
        {
          name = "${local.prefix}-appgw-probe"
          properties = {
            protocol                            = "Tcp"
            interval                            = 30
            timeout                             = 30
            unhealthyThreshold                  = 3
            pickHostNameFromBackendHttpSettings = false
            match = {
              statusCodes = [
                "200-399"
              ]
            }
          }
        }
      ]
    }
  }
  schema_validation_enabled = false
}
