<!-- BEGIN_TF_DOCS -->
## Requirements

No requirements.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_connectivity_configurations"></a> [connectivity\_configurations](#input\_connectivity\_configurations) | connectivity configuration | <pre>list(object({<br>    name                  = string<br>    network_group_name    = string<br>    connectivity_topology = optional(string)<br>    global_mesh_enabled   = optional(bool, false)<br>    deploy                = optional(bool, false)<br><br>    hub = optional(object({<br>      resource_id   = string<br>      resource_type = optional(string, "Microsoft.Network/virtualNetworks")<br>    }), null)<br><br>    applies_to_group = object({<br>      group_connectivity  = optional(string, "None")<br>      global_mesh_enabled = optional(bool, false)<br>      use_hub_gateway     = optional(bool, false)<br>    })<br>  }))</pre> | `[]` | no |
| <a name="input_connectivity_deployment"></a> [connectivity\_deployment](#input\_connectivity\_deployment) | connectivity deployment | <pre>object({<br>    configuration_names = optional(list(string), [])<br>    configuration_ids   = optional(list(string), [])<br>  })</pre> | `{}` | no |
| <a name="input_location"></a> [location](#input\_location) | location for network manager and other resources | `string` | `null` | no |
| <a name="input_network_groups"></a> [network\_groups](#input\_network\_groups) | network group | <pre>list(object({<br>    name           = string<br>    description    = optional(string)<br>    member_type    = optional(string, "VirtualNetwork")<br>    static_members = optional(list(string))<br>  }))</pre> | `[]` | no |
| <a name="input_network_manager_id"></a> [network\_manager\_id](#input\_network\_manager\_id) | network manager id | `string` | n/a | yes |
| <a name="input_prefix"></a> [prefix](#input\_prefix) | prefix to append before all resources | `string` | n/a | yes |
| <a name="input_resource_group"></a> [resource\_group](#input\_resource\_group) | resource group name | `any` | n/a | yes |
| <a name="input_security_admin_configurations"></a> [security\_admin\_configurations](#input\_security\_admin\_configurations) | security admin configuration | <pre>list(object({<br>    name                = string<br>    description         = optional(string)<br>    apply_default_rules = optional(bool, true)<br>    deploy              = optional(bool, false)<br><br>    rule_collections = optional(list(object({<br>      name              = string<br>      description       = optional(string)<br>      network_group_ids = list(string)<br>      rules = list(object({<br>        name                    = string<br>        description             = optional(string)<br>        action                  = string<br>        direction               = string<br>        priority                = number<br>        protocol                = string<br>        destination_port_ranges = list(string)<br>        source = list(object({<br>          address_prefix_type = string<br>          address_prefix      = string<br>        }))<br>        destinations = list(object({<br>          address_prefix_type = string<br>          address_prefix      = string<br>        }))<br>      }))<br>    })))<br>  }))</pre> | `[]` | no |
| <a name="input_security_deployment"></a> [security\_deployment](#input\_security\_deployment) | security deployment | <pre>object({<br>    configuration_names = optional(list(string), [])<br>    configuration_ids   = optional(list(string), [])<br>  })</pre> | `{}` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | tags for all hub resources | `map(any)` | `{}` | no |
| <a name="input_use_azpapi"></a> [use\_azpapi](#input\_use\_azpapi) | use azpapi | `bool` | `false` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_connectivity_configurations"></a> [connectivity\_configurations](#output\_connectivity\_configurations) | connectivity configurations |
| <a name="output_security_configurations"></a> [security\_configurations](#output\_security\_configurations) | security configurations |
| <a name="output_vnet_network_groups"></a> [vnet\_network\_groups](#output\_vnet\_network\_groups) | network groups |
<!-- END_TF_DOCS -->