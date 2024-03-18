

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
| [azurerm_monitor_diagnostic_setting.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_diagnostic_setting) | resource |
| [azurerm_portal_dashboard.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/portal_dashboard) | resource |
| [azurerm_public_ip.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/public_ip) | resource |
| [azurerm_virtual_network_gateway.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_network_gateway) | resource |
| [azurerm_log_analytics_workspace.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/log_analytics_workspace) | data source |
| [azurerm_public_ip.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/public_ip) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_active_active"></a> [active\_active](#input\_active\_active) | active active | `bool` | `true` | no |
| <a name="input_bgp_asn"></a> [bgp\_asn](#input\_bgp\_asn) | bgp asn for vnet gateway | `string` | `65515` | no |
| <a name="input_enable_bgp"></a> [enable\_bgp](#input\_enable\_bgp) | enable bgp | `bool` | `true` | no |
| <a name="input_env"></a> [env](#input\_env) | environment name | `string` | `"dev"` | no |
| <a name="input_ip_config0_apipa_addresses"></a> [ip\_config0\_apipa\_addresses](#input\_ip\_config0\_apipa\_addresses) | ip config0 apipa addresses for vnet gateway | `list(string)` | <pre>[<br>  "169.254.21.1"<br>]</pre> | no |
| <a name="input_ip_config1_apipa_addresses"></a> [ip\_config1\_apipa\_addresses](#input\_ip\_config1\_apipa\_addresses) | ip config1 apipa addresses for vnet gateway | `list(string)` | <pre>[<br>  "169.254.21.5"<br>]</pre> | no |
| <a name="input_ip_configuration"></a> [ip\_configuration](#input\_ip\_configuration) | ip configurations for vnet gateway | <pre>list(object({<br>    name                          = string<br>    subnet_id                     = string<br>    public_ip_address_name        = optional(string, null)<br>    private_ip_address_allocation = optional(string, "Dynamic")<br>    apipa_addresses               = optional(list(string), null)<br>  }))</pre> | `[]` | no |
| <a name="input_location"></a> [location](#input\_location) | vnet region location | `string` | n/a | yes |
| <a name="input_log_analytics_workspace_name"></a> [log\_analytics\_workspace\_name](#input\_log\_analytics\_workspace\_name) | log analytics workspace name | `string` | `null` | no |
| <a name="input_log_categories"></a> [log\_categories](#input\_log\_categories) | n/a | `list(any)` | <pre>[<br>  "GatewayDiagnosticLog",<br>  "TunnelDiagnosticLog",<br>  "RouteDiagnosticLog",<br>  "IKEDiagnosticLog",<br>  "P2SDiagnosticLog"<br>]</pre> | no |
| <a name="input_prefix"></a> [prefix](#input\_prefix) | prefix to append before all resources | `string` | n/a | yes |
| <a name="input_private_ip_address_enabled"></a> [private\_ip\_address\_enabled](#input\_private\_ip\_address\_enabled) | private ip address enabled | `bool` | `true` | no |
| <a name="input_remote_vnet_traffic_enabled"></a> [remote\_vnet\_traffic\_enabled](#input\_remote\_vnet\_traffic\_enabled) | remote vnet traffic enabled | `bool` | `true` | no |
| <a name="input_resource_group"></a> [resource\_group](#input\_resource\_group) | resource group name | `any` | n/a | yes |
| <a name="input_sku"></a> [sku](#input\_sku) | sku for vnet gateway | `string` | `"VpnGw1AZ"` | no |
| <a name="input_subnet_id"></a> [subnet\_id](#input\_subnet\_id) | subnet id for vnet gateway | `string` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | tags for all hub resources | `map(any)` | `{}` | no |
| <a name="input_virtual_wan_traffic_enabled"></a> [virtual\_wan\_traffic\_enabled](#input\_virtual\_wan\_traffic\_enabled) | virtual wan traffic enabled | `bool` | `true` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_bgp_asn"></a> [bgp\_asn](#output\_bgp\_asn) | n/a |
| <a name="output_bgp_default_ip0"></a> [bgp\_default\_ip0](#output\_bgp\_default\_ip0) | n/a |
| <a name="output_bgp_default_ip1"></a> [bgp\_default\_ip1](#output\_bgp\_default\_ip1) | n/a |
| <a name="output_gateway"></a> [gateway](#output\_gateway) | n/a |
| <a name="output_private_ip0"></a> [private\_ip0](#output\_private\_ip0) | n/a |
| <a name="output_private_ip1"></a> [private\_ip1](#output\_private\_ip1) | n/a |
| <a name="output_public_ip0"></a> [public\_ip0](#output\_public\_ip0) | n/a |
| <a name="output_public_ip1"></a> [public\_ip1](#output\_public\_ip1) | n/a |
<!-- END_TF_DOCS -->
