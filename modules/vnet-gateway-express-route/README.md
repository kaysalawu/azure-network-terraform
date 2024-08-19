

<!-- BEGIN_TF_DOCS -->
## Requirements

No requirements.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_active_active"></a> [active\_active](#input\_active\_active) | enable active active | `bool` | `false` | no |
| <a name="input_bgp_asn"></a> [bgp\_asn](#input\_bgp\_asn) | bgp asn for vnet gateway | `string` | `65515` | no |
| <a name="input_env"></a> [env](#input\_env) | environment name | `string` | `"dev"` | no |
| <a name="input_location"></a> [location](#input\_location) | vnet region location | `string` | n/a | yes |
| <a name="input_log_analytics_workspace_name"></a> [log\_analytics\_workspace\_name](#input\_log\_analytics\_workspace\_name) | log analytics workspace name | `string` | `null` | no |
| <a name="input_log_categories"></a> [log\_categories](#input\_log\_categories) | n/a | `list(any)` | <pre>[<br>  {<br>    "category": "GatewayDiagnosticLog",<br>    "categoryGroup": null,<br>    "enabled": true,<br>    "retentionPolicy": {<br>      "days": 0,<br>      "enabled": false<br>    }<br>  },<br>  {<br>    "category": "TunnelDiagnosticLog",<br>    "categoryGroup": null,<br>    "enabled": false,<br>    "retentionPolicy": {<br>      "days": 0,<br>      "enabled": false<br>    }<br>  },<br>  {<br>    "category": "RouteDiagnosticLog",<br>    "categoryGroup": null,<br>    "enabled": true,<br>    "retentionPolicy": {<br>      "days": 0,<br>      "enabled": false<br>    }<br>  },<br>  {<br>    "category": "IKEDiagnosticLog",<br>    "categoryGroup": null,<br>    "enabled": false,<br>    "retentionPolicy": {<br>      "days": 0,<br>      "enabled": false<br>    }<br>  },<br>  {<br>    "category": "P2SDiagnosticLog",<br>    "categoryGroup": null,<br>    "enabled": false,<br>    "retentionPolicy": {<br>      "days": 0,<br>      "enabled": false<br>    }<br>  }<br>]</pre> | no |
| <a name="input_metric_categories"></a> [metric\_categories](#input\_metric\_categories) | n/a | `list(any)` | <pre>[<br>  {<br>    "category": "AllMetrics",<br>    "enabled": false,<br>    "retentionPolicy": {<br>      "days": 0,<br>      "enabled": false<br>    }<br>  }<br>]</pre> | no |
| <a name="input_prefix"></a> [prefix](#input\_prefix) | prefix to append before all resources | `string` | n/a | yes |
| <a name="input_remote_vnet_traffic_enabled"></a> [remote\_vnet\_traffic\_enabled](#input\_remote\_vnet\_traffic\_enabled) | remote vnet traffic enabled | `bool` | `true` | no |
| <a name="input_resource_group"></a> [resource\_group](#input\_resource\_group) | resource group name | `any` | n/a | yes |
| <a name="input_sku"></a> [sku](#input\_sku) | sku for vnet gateway | `string` | `"ErGw1AZ"` | no |
| <a name="input_subnet_id"></a> [subnet\_id](#input\_subnet\_id) | subnet id for vnet gateway | `string` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | tags for all hub resources | `map(any)` | `{}` | no |
| <a name="input_virtual_wan_traffic_enabled"></a> [virtual\_wan\_traffic\_enabled](#input\_virtual\_wan\_traffic\_enabled) | virtual wan traffic enabled | `bool` | `true` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_gateway"></a> [gateway](#output\_gateway) | n/a |
| <a name="output_gateway_name"></a> [gateway\_name](#output\_gateway\_name) | n/a |
| <a name="output_public_ip"></a> [public\_ip](#output\_public\_ip) | n/a |
<!-- END_TF_DOCS -->
