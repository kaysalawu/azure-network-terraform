<!-- BEGIN_TF_DOCS -->
## Requirements

No requirements.

## Providers

| Name | Version |
|------|---------|
| <a name="provider_azapi"></a> [azapi](#provider\_azapi) | n/a |
| <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) | n/a |
| <a name="provider_resource"></a> [resource](#provider\_resource) | n/a |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [azapi_resource.azurerm_network_manager](https://registry.terraform.io/providers/azure/azapi/latest/docs/resources/resource) | resource |
| [azurerm_network_manager.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_manager) | resource |
| [resource_group.this](https://registry.terraform.io/providers/hashicorp/resource/latest/docs/data-sources/group) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_description"></a> [description](#input\_description) | global | `string` | n/a | yes |
| <a name="input_enable_diagnostics"></a> [enable\_diagnostics](#input\_enable\_diagnostics) | enable diagnostics | `bool` | `false` | no |
| <a name="input_flow_log_nsg_ids"></a> [flow\_log\_nsg\_ids](#input\_flow\_log\_nsg\_ids) | flow log nsg id | `list(string)` | `[]` | no |
| <a name="input_location"></a> [location](#input\_location) | location for network manager and other resources | `string` | n/a | yes |
| <a name="input_log_analytics_workspace_name"></a> [log\_analytics\_workspace\_name](#input\_log\_analytics\_workspace\_name) | log analytics workspace name | `string` | `null` | no |
| <a name="input_network_watcher_name"></a> [network\_watcher\_name](#input\_network\_watcher\_name) | network watcher name | `string` | `null` | no |
| <a name="input_network_watcher_resource_group"></a> [network\_watcher\_resource\_group](#input\_network\_watcher\_resource\_group) | network watcher resource group | `string` | `null` | no |
| <a name="input_prefix"></a> [prefix](#input\_prefix) | prefix to append before all resources | `string` | n/a | yes |
| <a name="input_resource_group_name"></a> [resource\_group\_name](#input\_resource\_group\_name) | resource group name | `any` | n/a | yes |
| <a name="input_scope_accesses"></a> [scope\_accesses](#input\_scope\_accesses) | scope accesses | `list(string)` | <pre>[<br>  "Connectivity",<br>  "SecurityAdmin"<br>]</pre> | no |
| <a name="input_scope_management_group_ids"></a> [scope\_management\_group\_ids](#input\_scope\_management\_group\_ids) | scope management group ids | `list(string)` | `[]` | no |
| <a name="input_scope_subscription_ids"></a> [scope\_subscription\_ids](#input\_scope\_subscription\_ids) | scope subscription ids | `list(string)` | `[]` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | tags for all hub resources | `map(any)` | `{}` | no |

## Outputs

No outputs.
<!-- END_TF_DOCS -->