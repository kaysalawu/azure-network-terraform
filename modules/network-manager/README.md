<!-- BEGIN_TF_DOCS -->
## Requirements

No requirements.

## Providers

| Name | Version |
|------|---------|
| <a name="provider_azapi"></a> [azapi](#provider\_azapi) | n/a |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [azapi_resource.network_group_vnet](https://registry.terraform.io/providers/azure/azapi/latest/docs/resources/resource) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_enable_diagnostics"></a> [enable\_diagnostics](#input\_enable\_diagnostics) | enable diagnostics | `bool` | `false` | no |
| <a name="input_location"></a> [location](#input\_location) | location for network manager and other resources | `string` | n/a | yes |
| <a name="input_log_analytics_workspace_name"></a> [log\_analytics\_workspace\_name](#input\_log\_analytics\_workspace\_name) | log analytics workspace name | `string` | `null` | no |
| <a name="input_prefix"></a> [prefix](#input\_prefix) | prefix to append before all resources | `string` | n/a | yes |
| <a name="input_resource_group_name"></a> [resource\_group\_name](#input\_resource\_group\_name) | resource group name | `any` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | tags for all hub resources | `map(any)` | `{}` | no |

## Outputs

No outputs.
<!-- END_TF_DOCS -->