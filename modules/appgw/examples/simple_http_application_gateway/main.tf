# Azurerm Provider configuration
provider "azurerm" {
  features {}
}

resource "azurerm_user_assigned_identity" "example" {
  resource_group_name = "rg-shared-westeurope-01"
  location            = "westeurope"
  name                = "appgw-api"
}

module "application-gateway" {
  source  = "kumarvna/application-gateway/azurerm"
  version = "1.1.0"

  # By default, this module will not create a resource group and expect to provide 
  # a existing RG name to use an existing resource group. Location will be same as existing RG. 
  # set the argument to `create_resource_group = true` to create new resrouce.
  resource_group_name  = "rg-shared-westeurope-01"
  location             = "westeurope"
  virtual_network_name = "vnet-shared-hub-westeurope-001"
  subnet_name          = "snet-appgateway"
  app_gateway_name     = "testgateway"

  # SKU requires `name`, `tier` to use for this Application Gateway
  # `Capacity` property is optional if `autoscale_configuration` is set
  sku = {
    name     = "Standard_v2"
    tier     = "Standard_v2"
    capacity = 1
  }

  # A backend pool routes request to backend servers, which serve the request.
  # Can create different backend pools for different types of requests
  backend_address_pools = [
    {
      name  = "appgw-testgateway-westeurope-bapool01"
      fqdns = ["example1.com", "example2.com"]
    },
    {
      name         = "appgw-testgateway-westeurope-bapool02"
      ip_addresses = ["1.2.3.4", "2.3.4.5"]
    }
  ]

  # An application gateway routes traffic to the backend servers using the port, protocol, and other settings
  # The port and protocol used to check traffic is encrypted between the application gateway and backend servers
  # List of backend HTTP settings can be added here.  
  # `probe_name` argument is required if you are defing health probes.
  backend_http_settings = [
    {
      name                  = "appgw-testgateway-westeurope-be-http-set1"
      cookie_based_affinity = "Disabled"
      path                  = "/"
      enable_https          = false
      request_timeout       = 30
      # probe_name            = "appgw-testgateway-westeurope-probe1" # Remove this if `health_probes` object is not defined.
      connection_draining = {
        enable_connection_draining = true
        drain_timeout_sec          = 300

      }
    },
    {
      name                  = "appgw-testgateway-westeurope-be-http-set2"
      cookie_based_affinity = "Enabled"
      path                  = "/"
      enable_https          = false
      request_timeout       = 30
    }
  ]

  # List of HTTP/HTTPS listeners. SSL Certificate name is required
  # `Basic` - This type of listener listens to a single domain site, where it has a single DNS mapping to the IP address of the 
  # application gateway. This listener configuration is required when you host a single site behind an application gateway.
  # `Multi-site` - This listener configuration is required when you want to configure routing based on host name or domain name for 
  # more than one web application on the same application gateway. Each website can be directed to its own backend pool.
  # Setting `host_name` value changes Listener Type to 'Multi site`. `host_names` allows special wildcard charcters.
  http_listeners = [
    {
      name      = "appgw-testgateway-westeurope-be-htln01"
      host_name = null
    }
  ]

  # Request routing rule is to determine how to route traffic on the listener. 
  # The rule binds the listener, the back-end server pool, and the backend HTTP settings.
  # `Basic` - All requests on the associated listener (for example, blog.salawu.net/*) are forwarded to the associated 
  # backend pool by using the associated HTTP setting.
  # `Path-based` - This routing rule lets you route the requests on the associated listener to a specific backend pool, 
  # based on the URL in the request. 
  request_routing_rules = [
    {
      name                       = "appgw-testgateway-westeurope-be-rqrt"
      rule_type                  = "Basic"
      http_listener_name         = "appgw-testgateway-westeurope-be-htln01"
      backend_address_pool_name  = "appgw-testgateway-westeurope-bapool01"
      backend_http_settings_name = "appgw-testgateway-westeurope-be-http-set1"
    }
  ]

  # A list with a single user managed identity id to be assigned to access Keyvault
  identity_ids = ["${azurerm_user_assigned_identity.example.id}"]

  # (Optional) To enable Azure Monitoring for Azure Application Gateway
  # (Optional) Specify `storage_account_name` to save monitoring logs to storage. 
  log_analytics_workspace_name = "loganalytics-we-sharedtest2"

  # Adding TAG's to Azure resources
  tags = {
    ProjectName  = "demo-internal"
    Env          = "dev"
    Owner        = "user@example.com"
    BusinessUnit = "CORP"
    ServiceClass = "Gold"
  }
}
