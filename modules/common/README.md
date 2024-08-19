

<!-- BEGIN_TF_DOCS -->
## Requirements

No requirements.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_env"></a> [env](#input\_env) | environment name | `string` | `"dev"` | no |
| <a name="input_firewall_sku"></a> [firewall\_sku](#input\_firewall\_sku) | The SKU of the firewall to deploy | `string` | `"Standard"` | no |
| <a name="input_prefix"></a> [prefix](#input\_prefix) | The prefix to use for all resources | `string` | n/a | yes |
| <a name="input_private_prefixes"></a> [private\_prefixes](#input\_private\_prefixes) | A list of private prefixes to allow access to | `list(string)` | <pre>[<br>  "10.0.0.0/8",<br>  "172.16.0.0/12",<br>  "192.168.0.0/16",<br>  "100.64.0.0/10"<br>]</pre> | no |
| <a name="input_private_prefixes_v6"></a> [private\_prefixes\_v6](#input\_private\_prefixes\_v6) | A list of private prefixes to allow access to | `list(string)` | <pre>[<br>  "fd00::/8"<br>]</pre> | no |
| <a name="input_regions"></a> [regions](#input\_regions) | A map of regions to deploy resources to | <pre>map(object({<br>    name     = string<br>    dns_zone = string<br>  }))</pre> | n/a | yes |
| <a name="input_resource_group"></a> [resource\_group](#input\_resource\_group) | The name of the resource group to deploy to | `string` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | A map of tags to apply to all resources | `map(any)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_log_analytics_workspaces"></a> [log\_analytics\_workspaces](#output\_log\_analytics\_workspaces) | n/a |
| <a name="output_nsg_default"></a> [nsg\_default](#output\_nsg\_default) | n/a |
| <a name="output_nsg_lb"></a> [nsg\_lb](#output\_nsg\_lb) | n/a |
| <a name="output_nsg_main"></a> [nsg\_main](#output\_nsg\_main) | n/a |
| <a name="output_nsg_nva"></a> [nsg\_nva](#output\_nsg\_nva) | n/a |
| <a name="output_private_dns_zones"></a> [private\_dns\_zones](#output\_private\_dns\_zones) | n/a |
| <a name="output_storage_accounts"></a> [storage\_accounts](#output\_storage\_accounts) | n/a |
<!-- END_TF_DOCS -->
