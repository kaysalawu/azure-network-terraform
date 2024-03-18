# Azure Application Gateway -hub2-azfw Module

https://github.com/kumarvna/terraform-azurerm-application-gateway

<!-- BEGIN_TF_DOCS -->
## Requirements

No requirements.

## Providers

| Name | Version |
|------|---------|
| <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) | n/a |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [azurerm_application_gateway.main](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/application_gateway) | resource |
| [azurerm_monitor_diagnostic_setting.agw-diag](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_diagnostic_setting) | resource |
| [azurerm_public_ip.pip](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/public_ip) | resource |
| [azurerm_resource_group.rg](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/resource_group) | resource |
| [azurerm_log_analytics_workspace.logws](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/log_analytics_workspace) | data source |
| [azurerm_public_ip.pip](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/public_ip) | data source |
| [azurerm_resource_group.rgrp](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/resource_group) | data source |
| [azurerm_storage_account.storeacc](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/storage_account) | data source |
| [azurerm_subnet.snet](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/subnet) | data source |
| [azurerm_virtual_network.vnet](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/virtual_network) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_agw_diag_logs"></a> [agw\_diag\_logs](#input\_agw\_diag\_logs) | Application Gateway Monitoring Category details for Azure Diagnostic setting | `list` | <pre>[<br>  "ApplicationGatewayAccessLog",<br>  "ApplicationGatewayPerformanceLog",<br>  "ApplicationGatewayFirewallLog"<br>]</pre> | no |
| <a name="input_app_gateway_name"></a> [app\_gateway\_name](#input\_app\_gateway\_name) | The name of the application gateway | `string` | `""` | no |
| <a name="input_authentication_certificates"></a> [authentication\_certificates](#input\_authentication\_certificates) | Authentication certificates to allow the backend with Azure Application Gateway | <pre>list(object({<br>    name = string<br>    data = string<br>  }))</pre> | `[]` | no |
| <a name="input_autoscale_configuration"></a> [autoscale\_configuration](#input\_autoscale\_configuration) | Minimum or Maximum capacity for autoscaling. Accepted values are for Minimum in the range 0 to 100 and for Maximum in the range 2 to 125 | <pre>object({<br>    min_capacity = number<br>    max_capacity = optional(number)<br>  })</pre> | `null` | no |
| <a name="input_backend_address_pools"></a> [backend\_address\_pools](#input\_backend\_address\_pools) | List of backend address pools | <pre>list(object({<br>    name         = string<br>    fqdns        = optional(list(string))<br>    ip_addresses = optional(list(string))<br>  }))</pre> | n/a | yes |
| <a name="input_backend_http_settings"></a> [backend\_http\_settings](#input\_backend\_http\_settings) | List of backend HTTP settings. | <pre>list(object({<br>    name                  = string<br>    cookie_based_affinity = optional(string, "Disabled")<br>    affinity_cookie_name  = optional(string)<br>    path                  = optional(string)<br>    port                  = optional(number, 80)<br>    probe_name            = optional(string)<br>    #protocol              = optional(string, "Http")<br>    request_timeout = optional(number, 30)<br>    host_name       = optional(string)<br><br>    pick_host_name_from_backend_address = optional(bool)<br>    authentication_certificate = optional(object({<br>      name = string<br>    }))<br>    trusted_root_certificate_names = optional(list(string), [])<br>    connection_draining = optional(object({<br>      enable_connection_draining = optional(bool, true)<br>      drain_timeout_sec          = optional(number, 300)<br>    }))<br>  }))</pre> | n/a | yes |
| <a name="input_create_resource_group"></a> [create\_resource\_group](#input\_create\_resource\_group) | Whether to create resource group and use it for all networking resources | `bool` | `false` | no |
| <a name="input_custom_error_configuration"></a> [custom\_error\_configuration](#input\_custom\_error\_configuration) | Global level custom error configuration for application gateway | `list(map(string))` | `[]` | no |
| <a name="input_domain_name_label"></a> [domain\_name\_label](#input\_domain\_name\_label) | Label for the Domain Name. Will be used to make up the FQDN. | `any` | `null` | no |
| <a name="input_enable_http2"></a> [enable\_http2](#input\_enable\_http2) | Is HTTP2 enabled on the application gateway resource? | `bool` | `false` | no |
| <a name="input_firewall_policy_id"></a> [firewall\_policy\_id](#input\_firewall\_policy\_id) | The ID of the Web Application Firewall Policy which can be associated with app gateway | `any` | `null` | no |
| <a name="input_health_probes"></a> [health\_probes](#input\_health\_probes) | List of Health probes used to test backend pools health. | <pre>list(object({<br>    name                                      = string<br>    protocol                                  = optional(string, "Http")<br>    port                                      = optional(number, 80)<br>    host                                      = optional(string, "127.0.0.1")<br>    path                                      = optional(string, "/")<br>    interval                                  = optional(number, 30)<br>    timeout                                   = optional(number, 30)<br>    unhealthy_threshold                       = optional(number, 3)<br>    pick_host_name_from_backend_http_settings = optional(bool, false)<br>    minimum_servers                           = optional(number)<br>    match = optional(object({<br>      body        = optional(string)<br>      status_code = optional(list(string))<br>    }))<br>  }))</pre> | `[]` | no |
| <a name="input_http_listeners"></a> [http\_listeners](#input\_http\_listeners) | List of HTTP/HTTPS listeners. SSL Certificate name is required | <pre>list(object({<br>    name                 = string<br>    host_name            = optional(string)<br>    host_names           = optional(list(string))<br>    require_sni          = optional(bool)<br>    ssl_certificate_name = optional(string)<br>    firewall_policy_id   = optional(string)<br>    ssl_profile_name     = optional(string)<br>    custom_error_configuration = optional(list(object({<br>      status_code           = string<br>      custom_error_page_url = string<br>    })))<br>  }))</pre> | n/a | yes |
| <a name="input_identity_ids"></a> [identity\_ids](#input\_identity\_ids) | Specifies a list with a single user managed identity id to be assigned to the Application Gateway | `any` | `null` | no |
| <a name="input_location"></a> [location](#input\_location) | The location/region to keep all your network resources. To get the list of all locations with table format from azure cli, run 'az account list-locations -o table' | `string` | `""` | no |
| <a name="input_log_analytics_workspace_name"></a> [log\_analytics\_workspace\_name](#input\_log\_analytics\_workspace\_name) | log analytics workspace name | `string` | `null` | no |
| <a name="input_pip_diag_logs"></a> [pip\_diag\_logs](#input\_pip\_diag\_logs) | Load balancer Public IP Monitoring Category details for Azure Diagnostic setting | `list` | <pre>[<br>  "DDoSProtectionNotifications",<br>  "DDoSMitigationFlowLogs",<br>  "DDoSMitigationReports"<br>]</pre> | no |
| <a name="input_private_ip_address"></a> [private\_ip\_address](#input\_private\_ip\_address) | Private IP Address to assign to the Load Balancer. | `any` | `null` | no |
| <a name="input_public_ip_address_name"></a> [public\_ip\_address\_name](#input\_public\_ip\_address\_name) | Public IP address name of application gateway | `string` | `null` | no |
| <a name="input_redirect_configuration"></a> [redirect\_configuration](#input\_redirect\_configuration) | list of maps for redirect configurations | `list(map(string))` | `[]` | no |
| <a name="input_request_routing_rules"></a> [request\_routing\_rules](#input\_request\_routing\_rules) | List of Request routing rules to be used for listeners. | <pre>list(object({<br>    priority                    = number<br>    name                        = string<br>    rule_type                   = optional(string, "Basic") # Basic, PathBasedRouting<br>    http_listener_name          = string<br>    backend_address_pool_name   = optional(string)<br>    backend_http_settings_name  = optional(string)<br>    redirect_configuration_name = optional(string)<br>    rewrite_rule_set_name       = optional(string)<br>    url_path_map_name           = optional(string)<br>  }))</pre> | `[]` | no |
| <a name="input_resource_group_name"></a> [resource\_group\_name](#input\_resource\_group\_name) | A container that holds related resources for an Azure solution | `string` | `""` | no |
| <a name="input_rewrite_rule_set"></a> [rewrite\_rule\_set](#input\_rewrite\_rule\_set) | List of rewrite rule set including rewrite rules | `any` | `[]` | no |
| <a name="input_sku"></a> [sku](#input\_sku) | The sku pricing model of v1 and v2 | <pre>object({<br>    name     = string<br>    tier     = string<br>    capacity = optional(number)<br>  })</pre> | n/a | yes |
| <a name="input_ssl_certificates"></a> [ssl\_certificates](#input\_ssl\_certificates) | List of SSL certificates data for Application gateway | <pre>list(object({<br>    name                = string<br>    data                = optional(string)<br>    password            = optional(string)<br>    key_vault_secret_id = optional(string)<br>  }))</pre> | `[]` | no |
| <a name="input_ssl_policy"></a> [ssl\_policy](#input\_ssl\_policy) | Application Gateway SSL configuration | <pre>object({<br>    disabled_protocols   = optional(list(string))<br>    policy_type          = optional(string)<br>    policy_name          = optional(string)<br>    cipher_suites        = optional(list(string))<br>    min_protocol_version = optional(string)<br>  })</pre> | `null` | no |
| <a name="input_storage_account_name"></a> [storage\_account\_name](#input\_storage\_account\_name) | The name of the hub storage account to store logs | `any` | `null` | no |
| <a name="input_subnet_name"></a> [subnet\_name](#input\_subnet\_name) | The name of the subnet to use in VM scale set | `string` | `""` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | A map of tags to add to all resources | `map(string)` | `{}` | no |
| <a name="input_trusted_root_certificates"></a> [trusted\_root\_certificates](#input\_trusted\_root\_certificates) | Trusted root certificates to allow the backend with Azure Application Gateway | <pre>list(object({<br>    name = string<br>    data = string<br>  }))</pre> | `[]` | no |
| <a name="input_url_path_maps"></a> [url\_path\_maps](#input\_url\_path\_maps) | List of URL path maps associated to path-based rules. | <pre>list(object({<br>    name                                = string<br>    default_backend_http_settings_name  = optional(string)<br>    default_backend_address_pool_name   = optional(string)<br>    default_redirect_configuration_name = optional(string)<br>    default_rewrite_rule_set_name       = optional(string)<br>    path_rules = list(object({<br>      name                        = string<br>      backend_address_pool_name   = optional(string)<br>      backend_http_settings_name  = optional(string)<br>      paths                       = list(string)<br>      redirect_configuration_name = optional(string)<br>      rewrite_rule_set_name       = optional(string)<br>      firewall_policy_id          = optional(string)<br>    }))<br>  }))</pre> | `[]` | no |
| <a name="input_virtual_network_name"></a> [virtual\_network\_name](#input\_virtual\_network\_name) | The name of the virtual network | `string` | `""` | no |
| <a name="input_vnet_resource_group_name"></a> [vnet\_resource\_group\_name](#input\_vnet\_resource\_group\_name) | The resource group name where the virtual network is created | `any` | `null` | no |
| <a name="input_waf_configuration"></a> [waf\_configuration](#input\_waf\_configuration) | Web Application Firewall support for your Azure Application Gateway | <pre>object({<br>    firewall_mode            = string<br>    rule_set_version         = string<br>    file_upload_limit_mb     = optional(number)<br>    request_body_check       = optional(bool, true)<br>    max_request_body_size_kb = optional(number)<br>    disabled_rule_group = optional(list(object({<br>      rule_group_name = string<br>      rules           = optional(list(string))<br>    })))<br>    exclusion = optional(list(object({<br>      match_variable          = string<br>      selector_match_operator = optional(string)<br>      selector                = optional(string)<br>    })))<br>  })</pre> | `null` | no |
| <a name="input_zones"></a> [zones](#input\_zones) | A collection of availability zones to spread the Application Gateway over. | `list(string)` | `[]` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_application_gateway_id"></a> [application\_gateway\_id](#output\_application\_gateway\_id) | The ID of the Application Gateway |
| <a name="output_authentication_certificate_id"></a> [authentication\_certificate\_id](#output\_authentication\_certificate\_id) | The ID of the Authentication Certificate |
| <a name="output_backend_address_pool_id"></a> [backend\_address\_pool\_id](#output\_backend\_address\_pool\_id) | The ID of the Backend Address Pool |
| <a name="output_backend_http_settings_id"></a> [backend\_http\_settings\_id](#output\_backend\_http\_settings\_id) | The ID of the Backend HTTP Settings Configuration |
| <a name="output_backend_http_settings_probe_id"></a> [backend\_http\_settings\_probe\_id](#output\_backend\_http\_settings\_probe\_id) | The ID of the Backend HTTP Settings Configuration associated Probe |
| <a name="output_custom_error_configuration_id"></a> [custom\_error\_configuration\_id](#output\_custom\_error\_configuration\_id) | The ID of the Custom Error Configuration |
| <a name="output_frontend_ip_configuration_id"></a> [frontend\_ip\_configuration\_id](#output\_frontend\_ip\_configuration\_id) | The ID of the Frontend IP Configuration |
| <a name="output_frontend_port_id"></a> [frontend\_port\_id](#output\_frontend\_port\_id) | The ID of the Frontend Port |
| <a name="output_gateway_ip_configuration_id"></a> [gateway\_ip\_configuration\_id](#output\_gateway\_ip\_configuration\_id) | The ID of the Gateway IP Configuration |
| <a name="output_http_listener_frontend_ip_configuration_id"></a> [http\_listener\_frontend\_ip\_configuration\_id](#output\_http\_listener\_frontend\_ip\_configuration\_id) | The ID of the associated Frontend Configuration |
| <a name="output_http_listener_frontend_port_id"></a> [http\_listener\_frontend\_port\_id](#output\_http\_listener\_frontend\_port\_id) | The ID of the associated Frontend Port |
| <a name="output_http_listener_id"></a> [http\_listener\_id](#output\_http\_listener\_id) | The ID of the HTTP Listener |
| <a name="output_http_listener_ssl_certificate_id"></a> [http\_listener\_ssl\_certificate\_id](#output\_http\_listener\_ssl\_certificate\_id) | The ID of the associated SSL Certificate |
| <a name="output_probe_id"></a> [probe\_id](#output\_probe\_id) | The ID of the health Probe |
| <a name="output_redirect_configuration_id"></a> [redirect\_configuration\_id](#output\_redirect\_configuration\_id) | The ID of the Redirect Configuration |
| <a name="output_request_routing_rule_backend_address_pool_id"></a> [request\_routing\_rule\_backend\_address\_pool\_id](#output\_request\_routing\_rule\_backend\_address\_pool\_id) | The ID of the Request Routing Rule associated Backend Address Pool |
| <a name="output_request_routing_rule_backend_http_settings_id"></a> [request\_routing\_rule\_backend\_http\_settings\_id](#output\_request\_routing\_rule\_backend\_http\_settings\_id) | The ID of the Request Routing Rule associated Backend HTTP Settings Configuration |
| <a name="output_request_routing_rule_http_listener_id"></a> [request\_routing\_rule\_http\_listener\_id](#output\_request\_routing\_rule\_http\_listener\_id) | The ID of the Request Routing Rule associated HTTP Listener |
| <a name="output_request_routing_rule_id"></a> [request\_routing\_rule\_id](#output\_request\_routing\_rule\_id) | The ID of the Request Routing Rule |
| <a name="output_request_routing_rule_redirect_configuration_id"></a> [request\_routing\_rule\_redirect\_configuration\_id](#output\_request\_routing\_rule\_redirect\_configuration\_id) | The ID of the Request Routing Rule associated Redirect Configuration |
| <a name="output_request_routing_rule_rewrite_rule_set_id"></a> [request\_routing\_rule\_rewrite\_rule\_set\_id](#output\_request\_routing\_rule\_rewrite\_rule\_set\_id) | The ID of the Request Routing Rule associated Rewrite Rule Set |
| <a name="output_request_routing_rule_url_path_map_id"></a> [request\_routing\_rule\_url\_path\_map\_id](#output\_request\_routing\_rule\_url\_path\_map\_id) | The ID of the Request Routing Rule associated URL Path Map |
| <a name="output_rewrite_rule_set_id"></a> [rewrite\_rule\_set\_id](#output\_rewrite\_rule\_set\_id) | The ID of the Rewrite Rule Set |
| <a name="output_ssl_certificate_id"></a> [ssl\_certificate\_id](#output\_ssl\_certificate\_id) | The ID of the SSL Certificate |
| <a name="output_ssl_certificate_public_cert_data"></a> [ssl\_certificate\_public\_cert\_data](#output\_ssl\_certificate\_public\_cert\_data) | The Public Certificate Data associated with the SSL Certificate |
| <a name="output_url_path_map_default_backend_address_pool_id"></a> [url\_path\_map\_default\_backend\_address\_pool\_id](#output\_url\_path\_map\_default\_backend\_address\_pool\_id) | The ID of the Default Backend Address Pool associated with URL Path Map |
| <a name="output_url_path_map_default_backend_http_settings_id"></a> [url\_path\_map\_default\_backend\_http\_settings\_id](#output\_url\_path\_map\_default\_backend\_http\_settings\_id) | The ID of the Default Backend HTTP Settings Collection associated with URL Path Map |
| <a name="output_url_path_map_default_redirect_configuration_id"></a> [url\_path\_map\_default\_redirect\_configuration\_id](#output\_url\_path\_map\_default\_redirect\_configuration\_id) | The ID of the Default Redirect Configuration associated with URL Path Map |
| <a name="output_url_path_map_id"></a> [url\_path\_map\_id](#output\_url\_path\_map\_id) | The ID of the URL Path Map |
<!-- END_TF_DOCS -->
