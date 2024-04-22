
https://github.com/Azure/terraform-azurerm-loadbalancer

<!-- BEGIN_TF_DOCS -->
## Requirements

No requirements.

## Providers

| Name | Version |
|------|---------|
| <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) | n/a |
| <a name="provider_time"></a> [time](#provider\_time) | n/a |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [azurerm_lb.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/lb) | resource |
| [azurerm_lb_backend_address_pool.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/lb_backend_address_pool) | resource |
| [azurerm_lb_backend_address_pool_address.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/lb_backend_address_pool_address) | resource |
| [azurerm_lb_nat_rule.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/lb_nat_rule) | resource |
| [azurerm_lb_outbound_rule.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/lb_outbound_rule) | resource |
| [azurerm_lb_probe.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/lb_probe) | resource |
| [azurerm_lb_rule.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/lb_rule) | resource |
| [azurerm_network_interface_backend_address_pool_association.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_interface_backend_address_pool_association) | resource |
| [azurerm_portal_dashboard.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/portal_dashboard) | resource |
| [azurerm_public_ip.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/public_ip) | resource |
| [time_sleep.this](https://registry.terraform.io/providers/hashicorp/time/latest/docs/resources/sleep) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_allocation_method"></a> [allocation\_method](#input\_allocation\_method) | (Required) Defines how an IP address is assigned. Options are Static or Dynamic. | `string` | `"Static"` | no |
| <a name="input_backend_pools"></a> [backend\_pools](#input\_backend\_pools) | n/a | <pre>list(object({<br>    name = string<br>    interfaces = optional(list(object({<br>      ip_configuration_name = string<br>      network_interface_id  = string<br>    })), [])<br>    addresses = optional(list(object({<br>      name                                = string<br>      virtual_network_id                  = optional(string, null)<br>      ip_address                          = optional(string, null)<br>      backend_address_ip_configuration_id = optional(string, null)<br>    })), [])<br>  }))</pre> | `[]` | no |
| <a name="input_dns_host"></a> [dns\_host](#input\_dns\_host) | load balancer dns host name | `string` | `null` | no |
| <a name="input_enable_dual_stack"></a> [enable\_dual\_stack](#input\_enable\_dual\_stack) | Enable dual stack | `bool` | `false` | no |
| <a name="input_enable_ha_ports"></a> [enable\_ha\_ports](#input\_enable\_ha\_ports) | (Optional) Enable HA ports. Defaults to false. | `bool` | `false` | no |
| <a name="input_frontend_ip_configuration"></a> [frontend\_ip\_configuration](#input\_frontend\_ip\_configuration) | (Optional) Name of the frontend ip configuration for private load balancer. If it is set, the 'prefix' variable will be ignored. | <pre>list(object({<br>    name                          = string<br>    zones                         = optional(list(string), ["1", "2", "3"]) # ["1", "2", "3"], "Zone-redundant"<br>    subnet_id                     = optional(string, null)<br>    private_ip_address_version    = optional(string, "IPv4")    # IPv4 or IPv6<br>    public_ip_address_version     = optional(string, "IPv4")    # IPv4 or IPv6<br>    private_ip_address_allocation = optional(string, "Dynamic") # Static or Dynamic<br>    private_ip_address            = optional(string, null)<br>    public_ip_address_id          = optional(string, null)<br>    public_ip_prefix_id           = optional(string, null)<br>    domain_name_label             = optional(string, null)<br>  }))</pre> | `[]` | no |
| <a name="input_frontend_private_ip_address"></a> [frontend\_private\_ip\_address](#input\_frontend\_private\_ip\_address) | (Optional) Private ip address to assign to frontend. Use it with type = private | `string` | `""` | no |
| <a name="input_frontend_private_ip_address_allocation"></a> [frontend\_private\_ip\_address\_allocation](#input\_frontend\_private\_ip\_address\_allocation) | (Optional) Frontend ip allocation type (Static or Dynamic) | `string` | `"Dynamic"` | no |
| <a name="input_frontend_subnet_id"></a> [frontend\_subnet\_id](#input\_frontend\_subnet\_id) | (Optional) Frontend subnet id to use when in private mode | `string` | `""` | no |
| <a name="input_lb_rules"></a> [lb\_rules](#input\_lb\_rules) | (Optional) Protocols to be used for lb rules. Format as [frontend\_port, protocol, backend\_port] | <pre>list(object({<br>    name                           = string<br>    protocol                       = optional(string, "Tcp") # Tcp, Udp, All<br>    frontend_port                  = optional(string, "80")  # 0-65534<br>    backend_port                   = optional(string, "80")  # 0-65534<br>    frontend_ip_configuration_name = string<br>    backend_address_pool_name      = optional(list(string), [])<br>    enable_floating_ip             = optional(bool, false)<br>    probe_name                     = string<br>    idle_timeout_in_minutes        = optional(number, 30)<br>    load_distribution              = optional(string, "Default") # Default, SourceIP, SourceIPProtocol<br>    disable_outbound_snat          = optional(bool, true)<br><br>  }))</pre> | `[]` | no |
| <a name="input_lb_sku"></a> [lb\_sku](#input\_lb\_sku) | (Optional) The SKU of the Azure Load Balancer. Accepted values are Basic and Standard. | `string` | `"Standard"` | no |
| <a name="input_location"></a> [location](#input\_location) | (Optional) The location/region where the core network will be created. The full list of Azure regions can be found at https://azure.microsoft.com/regions | `string` | `""` | no |
| <a name="input_log_analytics_workspace_name"></a> [log\_analytics\_workspace\_name](#input\_log\_analytics\_workspace\_name) | log analytics workspace name | `string` | `null` | no |
| <a name="input_name"></a> [name](#input\_name) | (Optional) Name of the load balancer. If it is set, the 'prefix' variable will be ignored. | `string` | `""` | no |
| <a name="input_nat_rules"></a> [nat\_rules](#input\_nat\_rules) | (Optional) Protocols to be used for nat rules. Format as [frontend\_port, protocol, backend\_port] | <pre>list(object({<br>    name                           = string<br>    protocol                       = optional(string, "Tcp") # Tcp, Udp, All<br>    frontend_port                  = optional(string, "80")  # 0-65534<br>    backend_port                   = optional(string, "80")  # 0-65534<br>    frontend_ip_configuration_name = string<br>  }))</pre> | `[]` | no |
| <a name="input_outbound_rules"></a> [outbound\_rules](#input\_outbound\_rules) | SNAT rules for outbound traffic. | <pre>list(object({<br>    name                           = string<br>    frontend_ip_configuration_name = string<br>    backend_address_pool_name      = optional(string, null)<br>    protocol                       = optional(string, "Tcp") # Tcp, Udp, All<br>    enable_tcp_reset               = optional(bool, false)<br>    allocated_outbound_ports       = optional(number, 1024)<br>    idle_timeout_in_minutes        = optional(number, 4)<br>  }))</pre> | `[]` | no |
| <a name="input_pip_name"></a> [pip\_name](#input\_pip\_name) | (Optional) Name of public ip. If it is set, the 'prefix' variable will be ignored. | `string` | `""` | no |
| <a name="input_pip_sku"></a> [pip\_sku](#input\_pip\_sku) | (Optional) The SKU of the Azure Public IP. Accepted values are Basic and Standard. | `string` | `"Standard"` | no |
| <a name="input_prefix"></a> [prefix](#input\_prefix) | (Required) Default prefix to use with your resource names. | `string` | `"azure_lb"` | no |
| <a name="input_private_dns_zone"></a> [private\_dns\_zone](#input\_private\_dns\_zone) | private dns zone | `string` | `null` | no |
| <a name="input_probes"></a> [probes](#input\_probes) | (Optional) Protocols to be used for lb health probes. Format as [protocol, port, request\_path] | <pre>list(object({<br>    name             = string<br>    protocol         = optional(string, "Tcp")<br>    port             = optional(string, "80")<br>    request_path     = optional(string, null)<br>    interval         = optional(number, 5)<br>    number_of_probes = optional(number, 2)<br>  }))</pre> | `[]` | no |
| <a name="input_resource_group_name"></a> [resource\_group\_name](#input\_resource\_group\_name) | (Required) The name of the resource group where the load balancer resources will be imported. | `string` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | n/a | `map(string)` | `{}` | no |
| <a name="input_type"></a> [type](#input\_type) | (Optional) Defined if the loadbalancer is private or public | `string` | `"public"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_backend_address_pool_ids"></a> [backend\_address\_pool\_ids](#output\_backend\_address\_pool\_ids) | the id for the azurerm\_lb\_backend\_address\_pool resource |
| <a name="output_frontend_ip_configuration_ids"></a> [frontend\_ip\_configuration\_ids](#output\_frontend\_ip\_configuration\_ids) | the frontend\_ip\_configuration\_ids for the azurerm\_lb resource |
| <a name="output_frontend_ip_configurations"></a> [frontend\_ip\_configurations](#output\_frontend\_ip\_configurations) | the frontend\_ip\_configuration for the azurerm\_lb resource |
| <a name="output_id"></a> [id](#output\_id) | the id for the azurerm\_lb resource |
| <a name="output_nat_rule_ids"></a> [nat\_rule\_ids](#output\_nat\_rule\_ids) | the ids for the azurerm\_lb\_nat\_rule resources |
| <a name="output_probe_ids"></a> [probe\_ids](#output\_probe\_ids) | the ids for the azurerm\_lb\_probe resources |
| <a name="output_public_ip_address_ids"></a> [public\_ip\_address\_ids](#output\_public\_ip\_address\_ids) | The IDs for the azurerm\_public\_ip resource indexed by frontend IP configuration names. |
| <a name="output_public_ip_addresses"></a> [public\_ip\_addresses](#output\_public\_ip\_addresses) | The IP addresses for the azurerm\_public\_ip resource indexed by frontend IP configuration names. |
<!-- END_TF_DOCS -->