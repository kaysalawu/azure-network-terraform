
####################################################
# identity
####################################################

resource "azurerm_user_assigned_identity" "hub1_appgw_tcp_int_uai" {
  resource_group_name = azurerm_resource_group.rg.name
  location            = local.hub1_location
  name                = "${local.hub1_prefix}appgw-tcp-int-uai"
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
          name = "feip-private"
          properties = {
            privateIPAllocationMethod = "Static"
            privateIPAddress          = local.hub1_appgw_addr
            subnet = {
              id = module.hub1.subnets["AppGatewaySubnet"].id
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
          name = "lsn-private-80"
          properties = {
            protocol = "Tcp"
            frontendIPConfiguration = {
              id = "subscriptions/${data.azurerm_subscription.current.subscription_id}/resourceGroups/${azurerm_resource_group.rg.name}/providers/Microsoft.Network/applicationGateways/${local.hub1_prefix}appgw-tcp-int/frontendIPConfigurations/feip-private"
            }
            frontendPort = {
              id = "subscriptions/${data.azurerm_subscription.current.subscription_id}/resourceGroups/${azurerm_resource_group.rg.name}/providers/Microsoft.Network/applicationGateways/${local.hub1_prefix}appgw-tcp-int/frontendPorts/port_80"
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
              id = "subscriptions/${data.azurerm_subscription.current.subscription_id}/resourceGroups/${azurerm_resource_group.rg.name}/providers/Microsoft.Network/applicationGateways/${local.hub1_prefix}appgw-tcp-int/probes/probe-spoke1"
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
              id = "subscriptions/${data.azurerm_subscription.current.subscription_id}/resourceGroups/${azurerm_resource_group.rg.name}/providers/Microsoft.Network/applicationGateways/${local.hub1_prefix}appgw-tcp-int/listeners/lsn-private-80"
            }
            backendAddressPool = {
              id = "subscriptions/${data.azurerm_subscription.current.subscription_id}/resourceGroups/${azurerm_resource_group.rg.name}/providers/Microsoft.Network/applicationGateways/${local.hub1_prefix}appgw-tcp-int/backendAddressPools/beap-spoke1"
            }
            backendSettings = {
              id = "subscriptions/${data.azurerm_subscription.current.subscription_id}/resourceGroups/${azurerm_resource_group.rg.name}/providers/Microsoft.Network/applicationGateways/${local.hub1_prefix}appgw-tcp-int/backendSettingsCollection/bes-spoke1"
            }
          }
        }
      ]
      # privateLinkConfigurations = [
      #   {
      #     name = "pl-config"
      #     properties = {
      #       ipConfigurations = [
      #         {
      #           name = "pl-ipconfig"
      #           properties = {
      #             primary                   = true
      #             privateIPAllocationMethod = "Dynamic"
      #             subnet = {
      #               id = module.hub1.subnets["PrivateLinkServiceSubnet"].id
      #             }
      #           }
      #         }
      #       ]
      #     }
      #   }
      # ]
    }
  }
  schema_validation_enabled = false
  depends_on = [
    azurerm_private_endpoint.hub1_spoke1_pls_pep,
  ]
}

# Private Link Configuration is not yet supported with TCP Application Gateway
# {
# │   "error": {
# │     "code": "ApplicationGatewayNetworkIsolationNotSupportedWithFeature",
# │     "message": "Application Gateway /subscriptions/812d474a-a031-4f0d-8151-91eb0a914d16/resourceGroups/Hs14_HubSpoke_Nva_2Region_RG/providers/Microsoft.Network/applicationGateways/Hs14-hub1-appgw-tcp-int with NetworkIsolation is not supported with feature Private Link Configuration..",
# │     "details": []
# │   }
# │ }
