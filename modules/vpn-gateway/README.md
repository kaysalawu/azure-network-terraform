

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
| [azurerm_monitor_diagnostic_setting.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_diagnostic_setting) | resource |
| [azurerm_portal_dashboard.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/portal_dashboard) | resource |
| [azurerm_vpn_gateway.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/vpn_gateway) | resource |
| [azurerm_log_analytics_workspace.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/log_analytics_workspace) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_bgp_route_translation_for_nat_enabled"></a> [bgp\_route\_translation\_for\_nat\_enabled](#input\_bgp\_route\_translation\_for\_nat\_enabled) | enable bgp route translation for nat | `bool` | `false` | no |
| <a name="input_bgp_settings"></a> [bgp\_settings](#input\_bgp\_settings) | n/a | <pre>object({<br>    asn                                       = optional(string, "65515")<br>    peer_weight                               = optional(number, 0)<br>    instance_0_bgp_peering_address_custom_ips = optional(list(string), [])<br>    instance_1_bgp_peering_address_custom_ips = optional(list(string), [])<br>  })</pre> | `{}` | no |
| <a name="input_env"></a> [env](#input\_env) | environment name | `string` | `"dev"` | no |
| <a name="input_location"></a> [location](#input\_location) | vnet region location | `string` | n/a | yes |
| <a name="input_log_analytics_workspace_name"></a> [log\_analytics\_workspace\_name](#input\_log\_analytics\_workspace\_name) | log analytics workspace name | `string` | `null` | no |
| <a name="input_log_categories"></a> [log\_categories](#input\_log\_categories) | n/a | `list(any)` | <pre>[<br>  "GatewayDiagnosticLog",<br>  "TunnelDiagnosticLog",<br>  "RouteDiagnosticLog",<br>  "IKEDiagnosticLog"<br>]</pre> | no |
| <a name="input_prefix"></a> [prefix](#input\_prefix) | prefix to append before all resources | `string` | n/a | yes |
| <a name="input_resource_group"></a> [resource\_group](#input\_resource\_group) | resource group name | `any` | n/a | yes |
| <a name="input_routing_preference"></a> [routing\_preference](#input\_routing\_preference) | routing preference = Internet \| Microsoft Network | `string` | `"Microsoft Network"` | no |
| <a name="input_scale_unit"></a> [scale\_unit](#input\_scale\_unit) | scale unit | `number` | `1` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | tags for all hub resources | `map(any)` | `{}` | no |
| <a name="input_virtual_hub_id"></a> [virtual\_hub\_id](#input\_virtual\_hub\_id) | virtual hub id | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_bgp_default_ip0"></a> [bgp\_default\_ip0](#output\_bgp\_default\_ip0) | n/a |
| <a name="output_bgp_default_ip1"></a> [bgp\_default\_ip1](#output\_bgp\_default\_ip1) | n/a |
| <a name="output_gateway"></a> [gateway](#output\_gateway) | n/a |
| <a name="output_public_ip0"></a> [public\_ip0](#output\_public\_ip0) | n/a |
| <a name="output_public_ip1"></a> [public\_ip1](#output\_public\_ip1) | n/a |
<!-- END_TF_DOCS -->
