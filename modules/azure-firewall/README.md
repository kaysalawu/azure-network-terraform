
# Azure Firewall Module

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
| [azurerm_firewall.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/firewall) | resource |
| [azurerm_monitor_diagnostic_setting.azfw](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_diagnostic_setting) | resource |
| [azurerm_portal_dashboard.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/portal_dashboard) | resource |
| [azurerm_public_ip.mgt_pip](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/public_ip) | resource |
| [azurerm_public_ip.pip](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/public_ip) | resource |
| [azurerm_log_analytics_workspace.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/log_analytics_workspace) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_env"></a> [env](#input\_env) | environment name | `string` | `"dev"` | no |
| <a name="input_firewall_policy_id"></a> [firewall\_policy\_id](#input\_firewall\_policy\_id) | firewall policy id | `string` | `null` | no |
| <a name="input_location"></a> [location](#input\_location) | vnet region location | `string` | n/a | yes |
| <a name="input_log_analytics_workspace_name"></a> [log\_analytics\_workspace\_name](#input\_log\_analytics\_workspace\_name) | log analytics workspace name | `string` | `null` | no |
| <a name="input_log_categories_firewall"></a> [log\_categories\_firewall](#input\_log\_categories\_firewall) | n/a | `list(any)` | <pre>[<br>  "AzureFirewallNetworkRule",<br>  "AZFWNetworkRule",<br>  "AZFWApplicationRule",<br>  "AZFWNatRule",<br>  "AZFWThreatIntel",<br>  "AZFWIdpsSignature",<br>  "AZFWDnsQuery",<br>  "AZFWFqdnResolveFailure",<br>  "AZFWFatFlow",<br>  "AZFWFlowTrace",<br>  "AZFWApplicationRuleAggregation",<br>  "AZFWNetworkRuleAggregation",<br>  "AZFWNatRuleAggregation"<br>]</pre> | no |
| <a name="input_mgt_subnet_id"></a> [mgt\_subnet\_id](#input\_mgt\_subnet\_id) | management subnet id | `string` | `null` | no |
| <a name="input_prefix"></a> [prefix](#input\_prefix) | prefix to append before all resources | `string` | n/a | yes |
| <a name="input_resource_group"></a> [resource\_group](#input\_resource\_group) | resource group name | `any` | n/a | yes |
| <a name="input_sku_name"></a> [sku\_name](#input\_sku\_name) | firewall sku name | `string` | `"AZFW_VNet"` | no |
| <a name="input_sku_tier"></a> [sku\_tier](#input\_sku\_tier) | firewall sku | `string` | `"Basic"` | no |
| <a name="input_storage_account"></a> [storage\_account](#input\_storage\_account) | storage account object | `any` | `null` | no |
| <a name="input_subnet_id"></a> [subnet\_id](#input\_subnet\_id) | subnet id | `string` | `null` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | tags for all hub resources | `map(any)` | `{}` | no |
| <a name="input_virtual_hub_id"></a> [virtual\_hub\_id](#input\_virtual\_hub\_id) | virtual hub id | `string` | `null` | no |
| <a name="input_virtual_hub_public_ip_count"></a> [virtual\_hub\_public\_ip\_count](#input\_virtual\_hub\_public\_ip\_count) | virtual hub public ip count | `number` | `1` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_firewall"></a> [firewall](#output\_firewall) | n/a |
| <a name="output_private_ip"></a> [private\_ip](#output\_private\_ip) | n/a |
| <a name="output_public_ip"></a> [public\_ip](#output\_public\_ip) | n/a |
| <a name="output_public_ip_mgt"></a> [public\_ip\_mgt](#output\_public\_ip\_mgt) | n/a |
<!-- END_TF_DOCS -->
