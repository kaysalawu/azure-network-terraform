

<!-- BEGIN_TF_DOCS -->
## Requirements

No requirements.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_allow_non_virtual_wan_traffic"></a> [allow\_non\_virtual\_wan\_traffic](#input\_allow\_non\_virtual\_wan\_traffic) | allow non virtual wan traffic | `bool` | `false` | no |
| <a name="input_bgp_route_translation_for_nat_enabled"></a> [bgp\_route\_translation\_for\_nat\_enabled](#input\_bgp\_route\_translation\_for\_nat\_enabled) | enable bgp route translation for nat | `bool` | `false` | no |
| <a name="input_env"></a> [env](#input\_env) | environment name | `string` | `"dev"` | no |
| <a name="input_location"></a> [location](#input\_location) | vnet region location | `string` | n/a | yes |
| <a name="input_log_analytics_workspace_name"></a> [log\_analytics\_workspace\_name](#input\_log\_analytics\_workspace\_name) | log analytics workspace name | `string` | `null` | no |
| <a name="input_log_categories"></a> [log\_categories](#input\_log\_categories) | n/a | `list(any)` | <pre>[<br>  "GatewayDiagnosticLog",<br>  "TunnelDiagnosticLog",<br>  "RouteDiagnosticLog",<br>  "IKEDiagnosticLog"<br>]</pre> | no |
| <a name="input_prefix"></a> [prefix](#input\_prefix) | prefix to append before all resources | `string` | n/a | yes |
| <a name="input_resource_group"></a> [resource\_group](#input\_resource\_group) | resource group name | `any` | n/a | yes |
| <a name="input_scale_units"></a> [scale\_units](#input\_scale\_units) | scale units | `number` | `1` | no |
| <a name="input_sku"></a> [sku](#input\_sku) | sku | `string` | `"ErGw1AZ"` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | tags for all hub resources | `map(any)` | `{}` | no |
| <a name="input_virtual_hub_id"></a> [virtual\_hub\_id](#input\_virtual\_hub\_id) | virtual hub id | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_gateway"></a> [gateway](#output\_gateway) | n/a |
| <a name="output_gateway_name"></a> [gateway\_name](#output\_gateway\_name) | n/a |
<!-- END_TF_DOCS -->
