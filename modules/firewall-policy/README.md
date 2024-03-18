

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
| [azurerm_firewall_policy_rule_collection_group.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/firewall_policy_rule_collection_group) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_application_rule_collection"></a> [application\_rule\_collection](#input\_application\_rule\_collection) | n/a | <pre>list(object({<br>    name     = string<br>    priority = number<br>    action   = string<br>    rule = list(object({<br>      name              = string<br>      protocols         = list(string)<br>      source_ip_groups  = list(string)<br>      destination_fqdns = list(string)<br>      destination_ports = list(string)<br>    }))<br>  }))</pre> | `[]` | no |
| <a name="input_firewall_policy_id"></a> [firewall\_policy\_id](#input\_firewall\_policy\_id) | firewall policy id | `string` | n/a | yes |
| <a name="input_log_analytics_workspace_name"></a> [log\_analytics\_workspace\_name](#input\_log\_analytics\_workspace\_name) | log analytics workspace name | `string` | `null` | no |
| <a name="input_nat_rule_collection"></a> [nat\_rule\_collection](#input\_nat\_rule\_collection) | n/a | <pre>list(object({<br>    name     = string<br>    priority = number<br>    action   = string<br>    rule = list(object({<br>      name                  = string<br>      protocols             = list(string)<br>      source_addresses      = list(string)<br>      destination_addresses = string<br>      destination_ports     = list(string)<br>      translated_address    = string<br>      translated_port       = string<br>    }))<br>  }))</pre> | `[]` | no |
| <a name="input_network_rule_collection"></a> [network\_rule\_collection](#input\_network\_rule\_collection) | n/a | <pre>list(object({<br>    name     = string<br>    priority = number<br>    action   = string<br>    rule = list(object({<br>      name                  = string<br>      protocols             = list(string)<br>      source_addresses      = list(string)<br>      destination_addresses = list(string)<br>      destination_ports     = list(string)<br>    }))<br>  }))</pre> | `[]` | no |
| <a name="input_prefix"></a> [prefix](#input\_prefix) | prefix to append before all resources | `string` | n/a | yes |

## Outputs

No outputs.
<!-- END_TF_DOCS -->
