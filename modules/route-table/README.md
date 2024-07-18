

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
| [azurerm_route.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/route) | resource |
| [azurerm_route_table.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/route_table) | resource |
| [azurerm_subnet_route_table_association.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet_route_table_association) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_bgp_route_propagation_enabled"></a> [disable\_bgp\_route\_propagation](#input\_disable\_bgp\_route\_propagation) | n/a | `bool` | `false` | no |
| <a name="input_location"></a> [location](#input\_location) | The location/region where the route table will be created | `string` | n/a | yes |
| <a name="input_prefix"></a> [prefix](#input\_prefix) | A short prefix to identify the resource | `string` | n/a | yes |
| <a name="input_resource_group"></a> [resource\_group](#input\_resource\_group) | The name of the resource group in which the route table will be created | `string` | n/a | yes |
| <a name="input_routes"></a> [routes](#input\_routes) | A list of route objects | <pre>list(object({<br>    name                   = string<br>    address_prefix         = list(string)<br>    next_hop_type          = string<br>    next_hop_in_ip_address = optional(string, null)<br>    delay_creation         = optional(string, "0s")<br>  }))</pre> | `[]` | no |
| <a name="input_subnet_ids"></a> [subnet\_ids](#input\_subnet\_ids) | A list of subnet IDs to associate with the route table | `list(string)` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | A map of tags to apply to all resources | `map(any)` | `{}` | no |

## Outputs

No outputs.
<!-- END_TF_DOCS -->
