

<!-- BEGIN_TF_DOCS -->
## Requirements

No requirements.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_application_rule_collection"></a> [application\_rule\_collection](#input\_application\_rule\_collection) | n/a | <pre>list(object({<br>    name     = string<br>    priority = number<br>    action   = string<br>    rule = list(object({<br>      name              = string<br>      protocols         = list(string)<br>      source_ip_groups  = list(string)<br>      destination_fqdns = list(string)<br>      destination_ports = list(string)<br>    }))<br>  }))</pre> | `[]` | no |
| <a name="input_firewall_policy_id"></a> [firewall\_policy\_id](#input\_firewall\_policy\_id) | firewall policy id | `string` | n/a | yes |
| <a name="input_log_analytics_workspace_name"></a> [log\_analytics\_workspace\_name](#input\_log\_analytics\_workspace\_name) | log analytics workspace name | `string` | `null` | no |
| <a name="input_nat_rule_collection"></a> [nat\_rule\_collection](#input\_nat\_rule\_collection) | n/a | <pre>list(object({<br>    name     = string<br>    priority = number<br>    action   = string<br>    rule = list(object({<br>      name                = string<br>      protocols           = list(string)<br>      source_addresses    = list(string)<br>      destination_address = string<br>      destination_ports   = optional(list(string), null)<br>      translated_address  = optional(string, null)<br>      translated_port     = string<br>      translated_fqdn     = optional(string, null)<br>    }))<br>  }))</pre> | `[]` | no |
| <a name="input_network_rule_collection"></a> [network\_rule\_collection](#input\_network\_rule\_collection) | n/a | <pre>list(object({<br>    name     = string<br>    priority = number<br>    action   = string<br>    rule = list(object({<br>      name                  = string<br>      protocols             = list(string)<br>      source_addresses      = list(string)<br>      destination_addresses = list(string)<br>      destination_ports     = list(string)<br>    }))<br>  }))</pre> | `[]` | no |
| <a name="input_prefix"></a> [prefix](#input\_prefix) | prefix to append before all resources | `string` | n/a | yes |

## Outputs

No outputs.
<!-- END_TF_DOCS -->
