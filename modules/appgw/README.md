# Azure Application Gateway Terraform Module

https://github.com/kumarvna/terraform-azurerm-application-gateway

Azure Application Gateway provides HTTP based load balancing that enables in creating routing rules for traffic based on HTTP. Traditional load balancers operate at the transport level and then route the traffic using source IP address and port to deliver data to a destination IP and port. Application Gateway using additional attributes such as URI (Uniform Resource Identifier) path and host headers to route the traffic.

Classic load balances operate at OSI layer 4 - TCP and UDP, while Application Gateway operates at application layer OSI layer 7 for load balancing.

This terraform module quickly creates a desired application gateway with additional options like WAF, Custom Error Configuration, SSL offloading with SSL policies, URL path mapping and many other options.

## Module Usage

```hcl
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
    name = "Standard_v2"
    tier = "Standard_v2"
  }

  autoscale_configuration = {
    min_capacity = 1
    max_capacity = 15
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
      enable_https          = true
      request_timeout       = 30
      probe_name            = "appgw-testgateway-westeurope-probe1" # Remove this if `health_probes` object is not defined.
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
      name                 = "appgw-testgateway-westeurope-be-htln01"
      ssl_certificate_name = "appgw-testgateway-westeurope-ssl01"
      host_name            = null
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

  # TLS termination (previously known as Secure Sockets Layer (SSL) Offloading)
  # The certificate on the listener requires the entire certificate chain (PFX certificate) to be uploaded to establish the chain of trust.
  # Authentication and trusted root certificate setup are not required for trusted Azure services such as Azure App Service.
  ssl_certificates = [{
    name     = "appgw-testgateway-westeurope-ssl01"
    data     = "./keyBag.pfx"
    password = "P@$$w0rd123"
  }]

  # By default, an application gateway monitors the health of all resources in its backend pool and automatically removes unhealthy ones. 
  # It then monitors unhealthy instances and adds them back to the healthy backend pool when they become available and respond to health probes.
  # must allow incoming Internet traffic on TCP ports 65503-65534 for the Application Gateway v1 SKU, and TCP ports 65200-65535 
  # for the v2 SKU with the destination subnet as Any and source as GatewayManager service tag. This port range is required for Azure infrastructure communication.
  # Additionally, outbound Internet connectivity can't be blocked, and inbound traffic coming from the AzureLoadBalancer tag must be allowed.
  health_probes = [
    {
      name                = "appgw-testgateway-westeurope-probe1"
      host                = "127.0.0.1"
      interval            = 30
      path                = "/"
      port                = 443
      timeout             = 30
      unhealthy_threshold = 3
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
```

## sku - Which one is the correct sku v1 or V2?

Application Gateway is available under a Standard_v2 SKU. Web Application Firewall (WAF) is available under a WAF_v2 SKU. The v2 SKU offers performance enhancements and adds support for critical new features like autoscaling, zone redundancy, and support for static VIPs.

Application Gateway Standard_v2 supports autoscaling and can scale up or down based on changing traffic load patterns. Autoscaling also removes the requirement to choose a deployment size or instance count during provisioning.

`sku` object supports the following:

| Name | Description
|--|--
`name`|The Name of the `SKU` to use for this Application Gateway. Possible values are `Standard_Small`, `Standard_Medium`, `Standard_Large`, `Standard_v2`, `WAF_Medium`, `WAF_Large`, and `WAF_v2`.
tier|The `Tier` of the `SKU` to use for this Application Gateway. Possible values are `Standard`, `Standard_v2`, WAF and `WAF_v2`.
`capacity`|The Capacity of the `SKU` to use for this Application Gateway. When using a `V1` SKU this value must be between `1` and `32`, and `1` to `125` for a `V2` SKU. This property is optional if `autoscale_configuration` is set.

A `autoscale_configuration` block supports the following:

| Name | Description
|--|--
`min_capacity`|Minimum capacity for autoscaling. Accepted values are in the range `0` to `100`.
`max_capacity`|Maximum capacity for autoscaling. Accepted values are in the range `2` to `125`.

### FEATURE COMPARISON BETWEEN V1 SKU AND V2 SKU

Feature|v1 SKU|v2 SKU
-------|------|------
Autoscaling| |✓|
Zone redundancy| |✓
Static VIP| |✓
Azure Kubernetes Service (AKS) Ingress controller| |✓
Azure Key Vault integration| |✓
Rewrite HTTP(S) headers| |✓
URL-based routing|✓|✓
Multiple-site hosting|✓|✓
Traffic redirection|✓|✓
Web Application Firewall (WAF)|✓|✓
WAF custom rules| |✓
Transport Layer Security (TLS)/Secure Sockets Layer (SSL) termination|✓|✓
End-to-end TLS encryption|✓|✓
Session affinity|✓|✓
Custom error pages|✓|✓
WebSocket support|✓|✓
HTTP/2 support|✓|✓
Connection draining|✓|✓

## `backend_address_pools` -  route request to backend servers

The backend pool is used to route requests to the backend servers that serve the request. Backend pools can be composed of NICs, virtual machine scale sets, public IP addresses, internal IP addresses, fully qualified domain names (FQDN), and multi-tenant back-ends like Azure App Service

`backend_address_pools` object supports the following:

| Name | Description
|--|--
`name`|The name of the Backend Address Pool.
`fqdns`|A list of FQDN's which should be part of the Backend Address Pool.
`ip_addresses`|A list of IP Addresses which should be part of the Backend Address Pool.

## `backend_http_settings` - Application Gateway HTTP settings configuration

The application gateway routes traffic to the back-end servers by using the configuration that you specify here. After you create an HTTP setting, you must associate it with one or more request-routing rules.

`backend_http_settings` object supports the following:

| Name | Description
|--|--
`name`|The name of the Backend HTTP Settings Collection.
`cookie_based_affinity`|Is Cookie-Based Affinity enabled? Possible values are `Enabled` and `Disabled`.
`affinity_cookie_name`|The name of the affinity cookie.
`path`|The Path which should be used as a prefix for all HTTP requests.
`enable_https`|enbale SSL port and https protocol. Possible values are `true` and `false`
`probe_name`|The name of an associated HTTP Probe. Required when health_probes object specified.
`request_timeout`|The request timeout in seconds, which must be between 1 and 86400 seconds.
`host_name`|Host header to be sent to the backend servers. Cannot be set if `pick_host_name_from_backend_address` is set to true.
`pick_host_name_from_backend_address`|Whether host header should be picked from the host name of the backend server. Defaults to `false`.
`authentication_certificate`|One or more authentication_certificate blocks available by specifing `authentication_certificate` object.
`trusted_root_certificate_names`|A list of trusted_root_certificate names.
`connection_draining`|A `connection_draining` object to specified with `enable_connection_draining` and `drain_timeout_sec` arguments.

## `http_listeners` - logical entity that checks for incoming connection requests

A listener is a logical entity that checks for incoming connection requests. A listener accepts a request if the protocol, port, hostname, and IP address associated with the request match the same elements associated with the listener configuration.

Before you use an application gateway, you must add at least one listener. There can be multiple listeners attached to an application gateway, and they can be used for the same protocol.

After a listener detects incoming requests from clients, the application gateway routes these requests to members in the backend pool configured in the rule.

There are two types of listeners:

* **Basic** - This type of listener listens to a single domain site, where it has a single DNS mapping to the IP address of the application gateway. This listener configuration is required when you host a single site behind an application gateway.
* **Multi-site** - This listener configuration is required when you want to configure routing based on host name or domain name for more than one web application on the same application gateway. Each website can be directed to its own backend pool.

A `http_listeners` block supports the following:

| Name | Description
|--|--
`name`|The Name of the HTTP Listener.
`host_name`|The Hostname which should be used for this HTTP Listener. Setting this value changes Listener Type to `Multi site`.
`host_names`|A list of Hostname(s) should be used for this HTTP Listener. It allows special wildcard characters. The `host_names` and `host_name` are mutually exclusive and cannot both be set.
`require_sni`|Should Server Name Indication be Required? Defaults to `false`.
`ssl_certificate_name`|The name of the associated SSL Certificate which should be used for this HTTP Listener.
`custom_error_configuration`|One or more `custom_error_configuration` blocks as defined below.
`firewall_policy_id`|The ID of the Web Application Firewall Policy which should be used for this HTTP Listener.
`ssl_profile_name`| The name of the associated SSL Profile (`ssl_profile` as defined below) which should be used for this HTTP Listener.

## request_routing_rules - how to route traffic on the listener?

A request routing rule is a key component of an application gateway because it determines how to route traffic on the listener. The rule binds the listener, the back-end server pool, and the backend HTTP settings.

When a listener accepts a request, the request routing rule forwards the request to the backend or redirects it elsewhere. If the request is forwarded to the backend, the request routing rule defines which backend server pool to forward it to. The request routing rule also determines if the headers in the request are to be rewritten. One listener can be attached to one rule.

There are two types of request routing rules:

* **Basic**: All requests on the associated listener (for example, blog.salawu.net/*) are forwarded to the associated backend pool by using the associated HTTP setting.

* **Path-based**: This routing rule lets you route the requests on the associated listener to a specific backend pool, based on the URL in the request. If the path of the URL in a request matches the path pattern in a path-based rule, the rule routes that request. It applies the path pattern only to the URL path, not to its query parameters. If the URL path on a listener request doesn't match any of the path-based rules, it routes the request to the default backend pool and HTTP settings.

A `request_routing_rules` block supports the following:

| Name | Description
|--|--
`name`|The Name of this Request Routing Rule.
`rule_type`|The Type of Routing that should be used for this Rule. Possible values are Basic and PathBasedRouting.
`http_listener_name`|The Name of the HTTP Listener which should be used for this Routing Rule.
`backend_address_pool_name`|The Name of the Backend Address Pool which should be used for this Routing Rule. Cannot be set if `redirect_configuration_name` is set.
`backend_http_settings_name`|The Name of the Backend HTTP Settings Collection which should be used for this Routing Rule. Cannot be set if `redirect_configuration_name` is set.
`redirect_configuration_name`|The Name of the Redirect Configuration which should be used for this Routing Rule. Cannot be set if either `backend_address_pool_name` or `backend_http_settings_name` is set.
`rewrite_rule_set_name`|The Name of the Rewrite Rule Set which should be used for this Routing Rule. Only valid for `v2 SKUs`.
`url_path_map_name`|The Name of the URL Path Map which should be associated with this Routing Rule.

> [!NOTE]
> backend_address_pool_name, backend_http_settings_name, redirect_configuration_name, and rewrite_rule_set_name are applicable only when rule_type is Basic.
>

## Advanced Usage of the Module

### `ssl_policy` - Application Gateway TLS policy

Application Gateway has three predefined security policies. You can configure your gateway with any of these policies to get the appropriate level of security. The policy names are annotated by the year and month in which they were configured. If not specified, Defaults to `AppGwSslPolicy20150501`.

Policy Name |Min. Protocol Version
------------|----------------------------
`AppGwSslPolicy20150501`|TLSv1_0
`AppGwSslPolicy20170401`|TLSv1_1
`AppGwSslPolicy20170401S`|TLSv1_2

```hcl
module "application-gateway" {
  source  = "kumarvna/application-gateway/azurerm"
  version = "1.1.0"

  # .... omitted

  ssl_policy = {
    policy_type = "Predefined"
    policy_name = "AppGwSslPolicy20170401S"
  }

  # .... omitted
}
```

### `ssl_certificates` - TLS termination and end to end TLS with Application Gateway

When configured with end-to-end TLS communication mode, Application Gateway terminates the TLS sessions at the gateway and decrypts user traffic. It then applies the configured rules to select an appropriate backend pool instance to route traffic to. Application Gateway then initiates a new TLS connection to the backend server and re-encrypts data using the backend server's public key certificate before transmitting the request to the backend. Any response from the web server goes through the same process back to the end user. End-to-end TLS is enabled by setting protocol setting in Backend HTTP Setting to HTTPS, which is then applied to a backend pool.

The certificate on the listener requires the entire certificate chain to be uploaded (the root certificate from the CA, the intermediates and the leaf certificate) to establish the chain of trust. Authentication and trusted root certificate setup are not required for trusted Azure services such as Azure App Service. They are considered trusted by default.

For TLS termination with Key Vault certificates to work properly existing user-assigned managed identity, which Application Gateway uses to retrieve certificates from `Key Vault`, should be defined via `identity` block. Additionally, access policies in the Key Vault to allow the `identity` to be granted get access to the secret should be defined and requires `v2 SKU`

A ssl_certificates block supports the following:

| Name | Description
|--|--
`name`|The Name of the SSL certificate that is unique within this Application Gateway
`data`|PFX certificate. Required if `key_vault_secret_id` is not set.
`password`|Password for the pfx file specified in data. Required if `data` is set.
`key_vault_secret_id`|Secret Id of (base-64 encoded unencrypted pfx) Secret or Certificate object stored in Azure `KeyVault`. You need to enable `soft delete` for keyvault to use this feature. Required if `data` is not set.

```hcl
module "application-gateway" {
  source  = "kumarvna/application-gateway/azurerm"
  version = "1.1.0"

  # .... omitted

  ssl_certificates = [{
    name     = "appgw-testgateway-westeurope-ssl01"
    data     = "./keyBag.pfx"
    password = "P@$$w0rd123"
  }]

  # .... omitted
}
```

### `custom_error_configuration` - Create Application Gateway custom error pages

Application Gateway allows you to create custom error pages instead of displaying default error pages. You can use your own branding and layout using a custom error page.

Custom error pages are supported for the following two scenarios:

* **Maintenance page** - This custom error page is sent instead of a 502 bad gateway page. It's shown when Application Gateway has no backend to route traffic to.
* **Unauthorized access page** - This custom error page is sent instead of a 403 unauthorized access page. It's shown when the Application Gateway WAF detects malicious traffic and blocks it.

Custom error pages can be defined at the global level and the listener level:

* **Global level** - the error page applies to traffic for all the web applications deployed on that application gateway.
* **Listener level** - the error page is applied to traffic received on that listener.
* **Both** - the custom error page defined at the listener level overrides the one set at global level.

> The size of the error page must be less than 1 MB. You may reference either internal or external images/CSS for this HTML file. For externally referenced resources, use absolute URLs that are publicly accessible.

```hcl
module "application-gateway" {
  source  = "kumarvna/application-gateway/azurerm"
  version = "1.1.0"

  # .... omitted

  http_listeners = [
    {
      name                 = "appgw-testgateway-westeurope-be-htln01"
      ssl_certificate_name = "appgw-testgateway-westeurope-ssl01"
      host_name            = null

      custom_error_configuration = [
        {
          custom_error_page_url = "https://example.blob.core.windows.net/appgateway/custom_error_403_page.html"
          status_code           = "HttpStatus403"
        },
        {
          custom_error_page_url = "https://example.blob.core.windows.net/appgateway/custom_error_502_page.html"
          status_code           = "HttpStatus502"
        }
      ]
    }
  ]

  custom_error_configuration = [
    {
      custom_error_page_url = "https://example.blob.core.windows.net/appgateway/custom_error_403_page.html"
      status_code           = "HttpStatus403"
    },
    {
      custom_error_page_url = "https://example.blob.core.windows.net/appgateway/custom_error_502_page.html"
      status_code           = "HttpStatus502"
    }
  ]

  # .... omitted
}
```

### `url_path_maps` - URL Path Based Routing

URL Path Based Routing allows you to route traffic to back-end server pools based on URL Paths of the request. One of the scenarios is to route requests for different content types to different backend server pools.

> For both the v1 and v2 SKUs, rules are processed in the order they are listed in the portal. If a basic listener is listed first and matches an incoming request, it gets processed by that listener. However, it is highly recommended to configure multi-site listeners first prior to configuring a basic listener. This ensures that traffic gets routed to the right back end.

The `url_path_maps` is used to specify Path patterns to back-end server pool mappings. The following code example is the snippet of `url_path_maps` from example file.

```hcl
module "application-gateway" {
  source  = "kumarvna/application-gateway/azurerm"
  version = "1.1.0"

  # .... omitted

  url_path_maps = [
    {
      name                               = "testgateway-url-path"
      default_backend_address_pool_name  = "appgw-testgateway-westeurope-bapool01"
      default_backend_http_settings_name = "appgw-testgateway-westeurope-be-http-set1"
      path_rules = [
        {
          name                       = "api"
          paths                      = ["/api/*"]
          backend_address_pool_name  = "appgw-testgateway-westeurope-bapool01"
          backend_http_settings_name = "appgw-testgateway-westeurope-be-http-set1"
        },
        {
          name                       = "videos"
          paths                      = ["/videos/*"]
          backend_address_pool_name  = "appgw-testgateway-westeurope-bapool02"
          backend_http_settings_name = "appgw-testgateway-westeurope-be-http-set2"
        }
      ]
    }
  ]

  # .... omitted
}
```

### `health_probes` - Application Gateway health monitoring

By default, an application gateway monitors the health of all resources in its backend pool and automatically removes unhealthy ones.  It then monitors unhealthy instances and adds them back to the healthy backend pool when they become available and respond to health probes.

You must allow incoming Internet traffic on `TCP` ports `65503-65534` for the Application Gateway `v1 SKU`, and TCP ports `65200-65535` for the `v2 SKU` with the destination subnet as `Any` and source as `GatewayManager` service tag. This port range is required for Azure infrastructure communication.

Additionally, outbound Internet connectivity can't be blocked, and inbound traffic coming from the `AzureLoadBalancer` tag must be allowed.

You can specify a list of health probes to monitor application gateway health. The following code example is the snippet of `health_probes` from example file.

```hcl
module "application-gateway" {
  source  = "kumarvna/application-gateway/azurerm"
  version = "1.1.0"

  # .... omitted

  health_probes = [
    {
      name                = "appgw-testgateway-westeurope-probe1"
      host                = "127.0.0.1"
      interval            = 30
      path                = "/"
      port                = 443
      timeout             = 30
      unhealthy_threshold = 3
    }
  ]

  # .... omitted
}
```

### `redirect_configuration` -  redirect traffic

You can use application gateway to redirect traffic. It has a generic redirection mechanism which allows for redirecting traffic received at one listener to another listener or to an external site. A common redirection scenario for many web applications is to support automatic HTTP to HTTPS redirection to ensure all communication between application and its users occurs over an encrypted path.

The following types of redirection are supported:

* 301 Permanent Redirect
* 302 Found
* 303 See Other
* 307 Temporary Redirect

Application Gateway redirection support offers the following capabilities:

* **Global redirection**: Redirects from one listener to another listener on the gateway. This enables HTTP to HTTPS redirection on a site.

* **Path-based redirection**: This type of redirection enables HTTP to HTTPS redirection only on a specific site area, for example a shopping cart area denoted by /cart/*.

### `rewrite_rule_set` - Rewrite HTTP headers and URL's

Application Gateway allows you to rewrite selected content of requests and responses. With this feature, you can translate URLs, query string parameters as well as modify request and response headers. It also allows you to add conditions to ensure that the URL or the specified headers are rewritten only when certain conditions are met. These conditions are based on the request and response information.

> HTTP header and URL rewrite features are only available for the Application Gateway v2 SKU

For more informaiton check [Microsoft documentation](https://docs.microsoft.com/en-us/azure/application-gateway/rewrite-http-headers-url).

### `waf_configuration` - Azure Web Application Firewall

Azure Web Application Firewall (WAF) on Azure Application Gateway provides centralized protection of your web applications from common exploits and vulnerabilities. Web applications are increasingly targeted by malicious attacks that exploit commonly known vulnerabilities. SQL injection and cross-site scripting are among the most common attacks.

The `waf_configuration` object is used to specify waf configuration, disabled rule groups and exclusions. The following code example is the snippet of `waf_configuration` from example file.

```hcl
module "application-gateway" {
  source  = "kumarvna/application-gateway/azurerm"
  version = "1.1.0"

  # .... omitted

  waf_configuration = {
    firewall_mode            = "Detection"
    rule_set_version         = "3.1"
    file_upload_limit_mb     = 100
    max_request_body_size_kb = 128

    disabled_rule_group = [
      {
        rule_group_name = "REQUEST-930-APPLICATION-ATTACK-LFI"
        rules           = ["930100", "930110"]
      },
      {
        rule_group_name = "REQUEST-920-PROTOCOL-ENFORCEMENT"
        rules           = ["920160"]
      }
    ]

    exclusion = [
      {
        match_variable          = "RequestCookieNames"
        selector                = "SomeCookie"
        selector_match_operator = "Equals"
      },
      {
        match_variable          = "RequestHeaderNames"
        selector                = "referer"
        selector_match_operator = "Equals"
      }
    ]
  }

  # .... omitted
}
```

For more information on Web Application Firewall CRS rule groups and rules, [visit Microsoft documentation](https://docs.microsoft.com/en-us/azure/web-application-firewall/ag/application-gateway-crs-rulegroups-rules?tabs=owasp32).

## Recommended naming and tagging conventions

Applying tags to your Azure resources, resource groups, and subscriptions to logically organize them into a taxonomy. Each tag consists of a name and a value pair. For example, you can apply the name `Environment` and the value `Production` to all the resources in production.
For recommendations on how to implement a tagging strategy, see Resource naming and tagging decision guide.

>**Important** :
Tag names are case-insensitive for operations. A tag with a tag name, regardless of the casing, is updated or retrieved. However, the resource provider might keep the casing you provide for the tag name. You'll see that casing in cost reports. **Tag values are case-sensitive.**

An effective naming convention assembles resource names by using important resource information as parts of a resource's name. For example, using these [recommended naming conventions](https://docs.microsoft.com/en-us/azure/cloud-adoption-framework/ready/azure-best-practices/naming-and-tagging#example-names), a public IP resource for a production SharePoint workload is named like this: `pip-sharepoint-prod-westus-001`.

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 0.13 |
| azurerm | >= 2.59.0 |

## Providers

| Name | Version |
|------|---------|
| azurerm | >= 2.59.0 |

## Inputs

Name | Description | Type | Default
---- | ----------- | ---- | -------
`create_resource_group` | Whether to create resource group and use it for all networking resources | string | `"false"`
`resource_group_name`|The name of an existing resource group.|string|`""`
`location`|The location for all resources while creating a new resource group.|string|`""`
`virtual_network_name`|The name of the virtual network|string|`""`
`vnet_resource_group_name`|The resource group name where the virtual network is created|string|`""`
`subnet_name`|The name of the subnet to use in VM scale set|string|`""`
`app_gateway_name`|The name of the application gateway|string|`""`
`log_analytics_workspace_name`|The name of log analytics workspace name|string|`null`
`storage_account_name`|The name of the hub storage account to store logs|string|`null`
`domain_name_label`|Label for the Domain Name. Will be used to make up the FQDN|string|`null`
`enable_http2`|Is HTTP2 enabled on the application gateway resource?|string|`false`
`zones`|A collection of availability zones to spread the Application Gateway over|list(string)|`[]`
`firewall_policy_id`|The ID of the Web Application Firewall Policy which can be associated with app gateway|string|`null`
`sku`|The sku pricing model of v1 and v2|object({})|`{}`
`autoscale_configuration`|Minimum or Maximum capacity for autoscaling. Accepted values are for Minimum in the range `0` to `100` and for Maximum in the range `2` to `125`|object|`null`
`private_ip_address`|Private IP Address to assign to the Load Balancer|string|`null`
`backend_address_pools`|List of backend address pools|list(object{})|`[]`
`backend_http_settings`|List of backend HTTP settings|list(object{})|`[]`
`http_listeners`|List of HTTP/HTTPS listeners. SSL Certificate name is required|list(object{})|`[]`
`request_routing_rules`|List of Request routing rules to be used for listeners|list(object{})|`[]`
`identity_ids`|Specifies a list with a single user managed identity id to be assigned to the Application Gateway|list(string)|`null`
`authentication_certificates`|Authentication certificates to allow the backend with Azure Application Gateway|list(object{})|`[]`
`trusted_root_certificates`|Trusted root certificates to allow the backend with Azure Application Gateway|list(object{})|`[]`
`ssl_policy`|Application Gateway SSL configuration|object({})|`null`
`ssl_certificates`|List of SSL certificates data for Application gateway|list(object{})|`[]`
`health_probes`|List of Health probes used to test backend pools health|list(object{})|`[]`
`url_path_maps`|List of URL path maps associated to path-based rules|list(object{})|`[]`
`redirect_configuration`|list of maps for redirect configurations|list(map(string))|`[]`
`custom_error_configuration`|Global level custom error configuration for application gateway|list(map(string))|`[]`
`rewrite_rule_set`|List of rewrite rule set including rewrite rules|any|`[]`
`waf_configuration`|Web Application Firewall support for your Azure Application Gateway|object({})|`null`
`Tags`|A map of tags to add to all resources|map|`{}`

## Outputs

Name | Description
---- | -----------
`application_gateway_id`|The ID of the Application Gateway
`authentication_certificate_id`|The ID of the Authentication Certificate
`backend_address_pool_id`|The ID of the Backend Address Pool
`backend_http_settings_id`|The ID of the Backend HTTP Settings Configuration
`backend_http_settings_probe_id`|The ID of the Backend HTTP Settings Configuration associated Probe
`frontend_ip_configuration_id`|The ID of the Frontend IP Configuration
`frontend_port_id`|The ID of the Frontend Port
`gateway_ip_configuration_id`|The ID of the Gateway IP Configuration
`http_listener_id`|The ID of the HTTP Listener
`http_listener_frontend_ip_configuration_id`|The ID of the associated Frontend Configuration
`http_listener_frontend_port_id`|The ID of the associated Frontend Port
`http_listener_ssl_certificate_id`|The ID of the associated SSL Certificate
`probe_id`|The ID of the health Probe
`request_routing_rule_id`|The ID of the Request Routing Rule
`request_routing_rule_http_listener_id`|The ID of the Request Routing Rule associated HTTP Listener
`request_routing_rule_backend_address_pool_id`|The ID of the Request Routing Rule associated Backend Address Pool
`request_routing_rule_backend_http_settings_id`|The ID of the Request Routing Rule associated Backend HTTP Settings Configuration
`request_routing_rule_redirect_configuration_id`|The ID of the Request Routing Rule associated Redirect Configuration
`request_routing_rule_rewrite_rule_set_id`|The ID of the Request Routing Rule associated Rewrite Rule Set
`request_routing_rule_url_path_map_id`|The ID of the Request Routing Rule associated URL Path Map
`ssl_certificate_id`|The ID of the SSL Certificate
`ssl_certificate_public_cert_data`|The Public Certificate Data associated with the SSL Certificate
`url_path_map_id`|The ID of the URL Path Map
`url_path_map_default_backend_address_pool_id`|The ID of the Default Backend Address Pool associated with URL Path Map
`url_path_map_default_backend_http_settings_id`|The ID of the Default Backend HTTP Settings Collection associated with URL Path Map
`url_path_map_default_redirect_configuration_id`|The ID of the Default Redirect Configuration associated with URL Path Map
`custom_error_configuration_id`|The ID of the Custom Error Configuration
`redirect_configuration_id`|The ID of the Redirect Configuration
`rewrite_rule_set_id`|The ID of the Rewrite Rule Set

## Resource Graph

![](graph.png)

## Authors

Originally created by [Kumaraswamy Vithanala](mailto:kumarvna@gmail.com)

## Other resources

* [Azure Application Gateway documentation](https://docs.microsoft.com/en-us/azure/application-gateway/)

* [Terraform AzureRM Provider Documentation](https://www.terraform.io/docs/providers/azurerm/index.html)
