

<!-- BEGIN_TF_DOCS -->
## Requirements

No requirements.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_cert_password"></a> [cert\_password](#input\_cert\_password) | The password to use for the self-signed certificate. | `string` | `"Password123"` | no |
| <a name="input_custom_route_address_prefixes"></a> [custom\_route\_address\_prefixes](#input\_custom\_route\_address\_prefixes) | custom route address prefixes for vnet gateway | `list(string)` | `[]` | no |
| <a name="input_env"></a> [env](#input\_env) | environment name | `string` | `"dev"` | no |
| <a name="input_location"></a> [location](#input\_location) | vnet region location | `string` | n/a | yes |
| <a name="input_log_analytics_workspace_name"></a> [log\_analytics\_workspace\_name](#input\_log\_analytics\_workspace\_name) | log analytics workspace name | `string` | `null` | no |
| <a name="input_prefix"></a> [prefix](#input\_prefix) | prefix to append before all resources | `string` | n/a | yes |
| <a name="input_resource_group"></a> [resource\_group](#input\_resource\_group) | resource group name | `any` | n/a | yes |
| <a name="input_scale_unit"></a> [scale\_unit](#input\_scale\_unit) | scale unit for vnet gateway | `string` | `"1"` | no |
| <a name="input_sku"></a> [sku](#input\_sku) | sku for vnet gateway | `string` | `"VpnGw1AZ"` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | tags for all hub resources | `map(any)` | `{}` | no |
| <a name="input_virtual_hub_id"></a> [virtual\_hub\_id](#input\_virtual\_hub\_id) | virtual hub id | `string` | n/a | yes |
| <a name="input_vpn_client_configuration"></a> [vpn\_client\_configuration](#input\_vpn\_client\_configuration) | vpn client configuration for vnet gateway | <pre>object({<br>    address_space = list(string)<br>    clients = list(object({<br>      name = string<br>    }))<br>  })</pre> | <pre>{<br>  "address_space": [<br>    "172.16.0.0/24"<br>  ],<br>  "clients": []<br>}</pre> | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_client_certificates"></a> [client\_certificates](#output\_client\_certificates) | n/a |
| <a name="output_client_certificates_cert_name"></a> [client\_certificates\_cert\_name](#output\_client\_certificates\_cert\_name) | n/a |
| <a name="output_client_certificates_cert_pem"></a> [client\_certificates\_cert\_pem](#output\_client\_certificates\_cert\_pem) | n/a |
| <a name="output_client_certificates_cert_pfx"></a> [client\_certificates\_cert\_pfx](#output\_client\_certificates\_cert\_pfx) | n/a |
| <a name="output_client_certificates_cert_pfx_password"></a> [client\_certificates\_cert\_pfx\_password](#output\_client\_certificates\_cert\_pfx\_password) | n/a |
| <a name="output_client_certificates_private_key_pem"></a> [client\_certificates\_private\_key\_pem](#output\_client\_certificates\_private\_key\_pem) | n/a |
| <a name="output_gateway"></a> [gateway](#output\_gateway) | n/a |
<!-- END_TF_DOCS -->
