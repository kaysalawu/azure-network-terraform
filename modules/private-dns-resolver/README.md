

<!-- BEGIN_TF_DOCS -->
## Requirements

No requirements.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_dns_zone_linked_rulesets"></a> [dns\_zone\_linked\_rulesets](#input\_dns\_zone\_linked\_rulesets) | private dns rulesets | `map(any)` | `{}` | no |
| <a name="input_enable_private_dns_resolver"></a> [enable\_private\_dns\_resolver](#input\_enable\_private\_dns\_resolver) | enable private dns resolver | `bool` | `false` | no |
| <a name="input_env"></a> [env](#input\_env) | environment name | `string` | `"dev"` | no |
| <a name="input_location"></a> [location](#input\_location) | vnet region location | `string` | n/a | yes |
| <a name="input_log_analytics_workspace_name"></a> [log\_analytics\_workspace\_name](#input\_log\_analytics\_workspace\_name) | log analytics workspace name | `string` | `null` | no |
| <a name="input_prefix"></a> [prefix](#input\_prefix) | prefix to append before all resources | `string` | n/a | yes |
| <a name="input_private_dns_inbound_subnet_id"></a> [private\_dns\_inbound\_subnet\_id](#input\_private\_dns\_inbound\_subnet\_id) | private dns inbound subnet id | `string` | n/a | yes |
| <a name="input_private_dns_outbound_subnet_id"></a> [private\_dns\_outbound\_subnet\_id](#input\_private\_dns\_outbound\_subnet\_id) | private dns outbound subnet id | `string` | n/a | yes |
| <a name="input_resource_group"></a> [resource\_group](#input\_resource\_group) | resource group name | `any` | n/a | yes |
| <a name="input_ruleset_dns_forwarding_rules"></a> [ruleset\_dns\_forwarding\_rules](#input\_ruleset\_dns\_forwarding\_rules) | private dns ruleset forwarding rules | `map(any)` | `{}` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | tags for all hub resources | `map(any)` | `{}` | no |
| <a name="input_virtual_network_id"></a> [virtual\_network\_id](#input\_virtual\_network\_id) | virtual network id | `string` | n/a | yes |
| <a name="input_vnets_linked_to_ruleset"></a> [vnets\_linked\_to\_ruleset](#input\_vnets\_linked\_to\_ruleset) | private dns rulesets | <pre>list(object({<br>    name    = string<br>    vnet_id = string<br>  }))</pre> | `[]` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_private_dns_forwarding_ruleset"></a> [private\_dns\_forwarding\_ruleset](#output\_private\_dns\_forwarding\_ruleset) | n/a |
| <a name="output_private_dns_inbound_ep"></a> [private\_dns\_inbound\_ep](#output\_private\_dns\_inbound\_ep) | n/a |
| <a name="output_private_dns_outbound_ep"></a> [private\_dns\_outbound\_ep](#output\_private\_dns\_outbound\_ep) | n/a |
| <a name="output_private_dns_resolver"></a> [private\_dns\_resolver](#output\_private\_dns\_resolver) | n/a |
<!-- END_TF_DOCS -->
