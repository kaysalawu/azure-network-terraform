

<!-- BEGIN_TF_DOCS -->
## Requirements

No requirements.

## Providers

| Name | Version |
|------|---------|
| <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) | n/a |
| <a name="provider_time"></a> [time](#provider\_time) | n/a |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_azfw"></a> [azfw](#module\_azfw) | ../../modules/azure-firewall | n/a |
| <a name="module_ergw"></a> [ergw](#module\_ergw) | ../../modules/express-route-gateway | n/a |
| <a name="module_p2sgw"></a> [p2sgw](#module\_p2sgw) | ../../modules/point-to-site-gateway | n/a |
| <a name="module_vpngw"></a> [vpngw](#module\_vpngw) | ../../modules/vpn-gateway | n/a |

## Resources

| Name | Type |
|------|------|
| [azurerm_virtual_hub.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_hub) | resource |
| [azurerm_virtual_hub_route_table_route.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_hub_route_table_route) | resource |
| [azurerm_virtual_hub_routing_intent.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_hub_routing_intent) | resource |
| [time_sleep.this](https://registry.terraform.io/providers/hashicorp/time/latest/docs/resources/sleep) | resource |
| [azurerm_virtual_hub_route_table.default](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/virtual_hub_route_table) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_address_prefix"></a> [address\_prefix](#input\_address\_prefix) | Address prefix for the virtual hub | `string` | n/a | yes |
| <a name="input_config_security"></a> [config\_security](#input\_config\_security) | n/a | <pre>object({<br>    create_firewall       = optional(bool, false)<br>    enable_routing_intent = optional(bool, false)<br>    firewall_sku          = optional(string, "Basic")<br>    firewall_policy_id    = optional(string, null)<br>    routing_policies = optional(object({<br>      internet            = optional(bool, false)<br>      private_traffic     = optional(bool, false)<br>      additional_prefixes = optional(map(any), {})<br>    }))<br>  })</pre> | `{}` | no |
| <a name="input_enable_diagnostics"></a> [enable\_diagnostics](#input\_enable\_diagnostics) | enable diagnostics | `bool` | `false` | no |
| <a name="input_enable_routing_intent"></a> [enable\_routing\_intent](#input\_enable\_routing\_intent) | Enable routing intent | `bool` | `false` | no |
| <a name="input_env"></a> [env](#input\_env) | environment name | `string` | `"dev"` | no |
| <a name="input_express_route_gateway"></a> [express\_route\_gateway](#input\_express\_route\_gateway) | n/a | <pre>object({<br>    enable = optional(bool, false)<br>    sku    = optional(string, "ErGw1AZ")<br>  })</pre> | `{}` | no |
| <a name="input_hub_routing_preference"></a> [hub\_routing\_preference](#input\_hub\_routing\_preference) | Hub routing preference: ExpressRoute \| ASPath \| VpnGateway | `string` | `"ASPath"` | no |
| <a name="input_location"></a> [location](#input\_location) | Location for all resources | `string` | n/a | yes |
| <a name="input_log_analytics_workspace_name"></a> [log\_analytics\_workspace\_name](#input\_log\_analytics\_workspace\_name) | log analytics workspace name | `string` | `null` | no |
| <a name="input_log_categories_firewall"></a> [log\_categories\_firewall](#input\_log\_categories\_firewall) | n/a | `list(any)` | <pre>[<br>  {<br>    "category": "AzureFirewallNetworkRule",<br>    "categoryGroup": null,<br>    "enabled": false,<br>    "retentionPolicy": {<br>      "days": 0,<br>      "enabled": false<br>    }<br>  },<br>  {<br>    "category": "AZFWNetworkRule",<br>    "categoryGroup": null,<br>    "enabled": true,<br>    "retentionPolicy": {<br>      "days": 0,<br>      "enabled": false<br>    }<br>  },<br>  {<br>    "category": "AZFWApplicationRule",<br>    "categoryGroup": null,<br>    "enabled": true,<br>    "retentionPolicy": {<br>      "days": 0,<br>      "enabled": false<br>    }<br>  },<br>  {<br>    "category": "AZFWNatRule",<br>    "categoryGroup": null,<br>    "enabled": true,<br>    "retentionPolicy": {<br>      "days": 0,<br>      "enabled": false<br>    }<br>  },<br>  {<br>    "category": "AZFWThreatIntel",<br>    "categoryGroup": null,<br>    "enabled": false,<br>    "retentionPolicy": {<br>      "days": 0,<br>      "enabled": false<br>    }<br>  },<br>  {<br>    "category": "AZFWIdpsSignature",<br>    "categoryGroup": null,<br>    "enabled": false,<br>    "retentionPolicy": {<br>      "days": 0,<br>      "enabled": false<br>    }<br>  },<br>  {<br>    "category": "AZFWDnsQuery",<br>    "categoryGroup": null,<br>    "enabled": false,<br>    "retentionPolicy": {<br>      "days": 0,<br>      "enabled": false<br>    }<br>  },<br>  {<br>    "category": "AZFWFqdnResolveFailure",<br>    "categoryGroup": null,<br>    "enabled": false,<br>    "retentionPolicy": {<br>      "days": 0,<br>      "enabled": false<br>    }<br>  },<br>  {<br>    "category": "AZFWFatFlow",<br>    "categoryGroup": null,<br>    "enabled": false,<br>    "retentionPolicy": {<br>      "days": 0,<br>      "enabled": false<br>    }<br>  },<br>  {<br>    "category": "AZFWFlowTrace",<br>    "categoryGroup": null,<br>    "enabled": false,<br>    "retentionPolicy": {<br>      "days": 0,<br>      "enabled": false<br>    }<br>  },<br>  {<br>    "category": "AZFWApplicationRuleAggregation",<br>    "categoryGroup": null,<br>    "enabled": false,<br>    "retentionPolicy": {<br>      "days": 0,<br>      "enabled": false<br>    }<br>  },<br>  {<br>    "category": "AZFWNetworkRuleAggregation",<br>    "categoryGroup": null,<br>    "enabled": false,<br>    "retentionPolicy": {<br>      "days": 0,<br>      "enabled": false<br>    }<br>  },<br>  {<br>    "category": "AZFWNatRuleAggregation",<br>    "categoryGroup": null,<br>    "enabled": false,<br>    "retentionPolicy": {<br>      "days": 0,<br>      "enabled": false<br>    }<br>  }<br>]</pre> | no |
| <a name="input_metric_categories_firewall"></a> [metric\_categories\_firewall](#input\_metric\_categories\_firewall) | n/a | `list(any)` | <pre>[<br>  {<br>    "category": "AllMetrics",<br>    "enabled": false,<br>    "retentionPolicy": {<br>      "days": 0,<br>      "enabled": false<br>    }<br>  }<br>]</pre> | no |
| <a name="input_p2s_vpn_gateway"></a> [p2s\_vpn\_gateway](#input\_p2s\_vpn\_gateway) | n/a | <pre>object({<br>    enable        = optional(bool, false)<br>    sku           = optional(string, "VpnGw1AZ")<br>    active_active = optional(bool, false)<br><br>    custom_route_address_prefixes = optional(list(string), [])<br><br>    vpn_client_configuration = optional(object({<br>      address_space = list(string)<br>      clients = list(object({<br>        name = string<br>      }))<br>    }))<br>  })</pre> | <pre>{<br>  "enable": false,<br>  "ip_configuration": [<br>    {<br>      "name": "ip-config",<br>      "public_ip_address_name": null<br>    }<br>  ],<br>  "sku": "VpnGw1AZ"<br>}</pre> | no |
| <a name="input_prefix"></a> [prefix](#input\_prefix) | Prefix for all resources | `string` | n/a | yes |
| <a name="input_resource_group"></a> [resource\_group](#input\_resource\_group) | Name of the resource group | `string` | n/a | yes |
| <a name="input_routing_policies"></a> [routing\_policies](#input\_routing\_policies) | n/a | <pre>object({<br>    internet            = optional(bool, false)<br>    private_traffic     = optional(bool, false)<br>    additional_prefixes = optional(map(any), {})<br>  })</pre> | <pre>{<br>  "additional_prefixes": {},<br>  "internet": false,<br>  "private_traffic": false<br>}</pre> | no |
| <a name="input_s2s_vpn_gateway"></a> [s2s\_vpn\_gateway](#input\_s2s\_vpn\_gateway) | n/a | <pre>object({<br>    enable = optional(bool, false)<br>    sku    = optional(string, "VpnGw1AZ")<br>    bgp_settings = optional(object({<br>      asn                                       = optional(string, "65515")<br>      peer_weight                               = optional(number, 0)<br>      instance_0_bgp_peering_address_custom_ips = optional(list(string), [])<br>      instance_1_bgp_peering_address_custom_ips = optional(list(string), [])<br>    }))<br>  })</pre> | <pre>{<br>  "bgp_settings": {},<br>  "enable": false,<br>  "sku": "VpnGw1AZ"<br>}</pre> | no |
| <a name="input_sku"></a> [sku](#input\_sku) | SKU of the virtual hub: Basic \| Standard | `string` | `"Standard"` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | A map of tags to apply to all resources | `map(any)` | `{}` | no |
| <a name="input_virtual_wan_id"></a> [virtual\_wan\_id](#input\_virtual\_wan\_id) | ID of the virtual WAN | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_bgp_asn"></a> [bgp\_asn](#output\_bgp\_asn) | n/a |
| <a name="output_ergw"></a> [ergw](#output\_ergw) | n/a |
| <a name="output_firewall"></a> [firewall](#output\_firewall) | n/a |
| <a name="output_firewall_private_ip"></a> [firewall\_private\_ip](#output\_firewall\_private\_ip) | n/a |
| <a name="output_p2sgw"></a> [p2sgw](#output\_p2sgw) | n/a |
| <a name="output_router_bgp_ip0"></a> [router\_bgp\_ip0](#output\_router\_bgp\_ip0) | n/a |
| <a name="output_router_bgp_ip1"></a> [router\_bgp\_ip1](#output\_router\_bgp\_ip1) | n/a |
| <a name="output_virtual_hub"></a> [virtual\_hub](#output\_virtual\_hub) | n/a |
| <a name="output_vpngw"></a> [vpngw](#output\_vpngw) | n/a |
| <a name="output_vpngw_bgp_ip0"></a> [vpngw\_bgp\_ip0](#output\_vpngw\_bgp\_ip0) | n/a |
| <a name="output_vpngw_bgp_ip1"></a> [vpngw\_bgp\_ip1](#output\_vpngw\_bgp\_ip1) | n/a |
| <a name="output_vpngw_public_ip0"></a> [vpngw\_public\_ip0](#output\_vpngw\_public\_ip0) | n/a |
| <a name="output_vpngw_public_ip1"></a> [vpngw\_public\_ip1](#output\_vpngw\_public\_ip1) | n/a |
<!-- END_TF_DOCS -->
