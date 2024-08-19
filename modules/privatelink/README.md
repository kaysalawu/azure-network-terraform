

<!-- BEGIN_TF_DOCS -->
## Requirements

No requirements.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_dns_host"></a> [dns\_host](#input\_dns\_host) | load balancer dns host name | `string` | `null` | no |
| <a name="input_location"></a> [location](#input\_location) | vnet region location | `string` | n/a | yes |
| <a name="input_log_analytics_workspace_name"></a> [log\_analytics\_workspace\_name](#input\_log\_analytics\_workspace\_name) | log analytics workspace name | `string` | `null` | no |
| <a name="input_nat_ip_config"></a> [nat\_ip\_config](#input\_nat\_ip\_config) | n/a | <pre>list(object({<br>    name               = string<br>    primary            = optional(bool, true)<br>    subnet_id          = string<br>    private_ip_address = optional(string, "")<br>    lb_frontend_ids    = optional(list(any), [])<br>  }))</pre> | `[]` | no |
| <a name="input_prefix"></a> [prefix](#input\_prefix) | prefix to append before all resources | `string` | n/a | yes |
| <a name="input_private_dns_zone"></a> [private\_dns\_zone](#input\_private\_dns\_zone) | private dns zone | `string` | `null` | no |
| <a name="input_resource_group"></a> [resource\_group](#input\_resource\_group) | resource group name | `any` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | tags for all hub resources | `map(any)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_private_link_service_id"></a> [private\_link\_service\_id](#output\_private\_link\_service\_id) | n/a |
<!-- END_TF_DOCS -->
