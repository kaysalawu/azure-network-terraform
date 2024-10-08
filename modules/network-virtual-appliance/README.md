

<!-- BEGIN_TF_DOCS -->
## Requirements

No requirements.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_custom_data"></a> [custom\_data](#input\_custom\_data) | base64 string containing virtual machine custom data | `string` | `null` | no |
| <a name="input_enable_ipv6"></a> [enable\_ipv6](#input\_enable\_ipv6) | enable ipv6 | `bool` | `false` | no |
| <a name="input_enable_plan"></a> [enable\_plan](#input\_enable\_plan) | enable plan | `bool` | `false` | no |
| <a name="input_health_probes"></a> [health\_probes](#input\_health\_probes) | probe name | <pre>list(object({<br>    name         = string<br>    port         = number<br>    protocol     = string<br>    request_path = optional(string, "")<br>  }))</pre> | <pre>[<br>  {<br>    "name": "ssh",<br>    "port": 22,<br>    "protocol": "Tcp",<br>    "request_path": ""<br>  }<br>]</pre> | no |
| <a name="input_ilb_trust_ip"></a> [ilb\_trust\_ip](#input\_ilb\_trust\_ip) | internal load balancer trust address | `string` | `null` | no |
| <a name="input_ilb_trust_ipv6"></a> [ilb\_trust\_ipv6](#input\_ilb\_trust\_ipv6) | internal ipv6 load balancer trust address | `string` | `null` | no |
| <a name="input_ilb_untrust_ip"></a> [ilb\_untrust\_ip](#input\_ilb\_untrust\_ip) | internal load balancer untrust address | `string` | `null` | no |
| <a name="input_ilb_untrust_ipv6"></a> [ilb\_untrust\_ipv6](#input\_ilb\_untrust\_ipv6) | internal ipv6 load balancer untrust address | `string` | `null` | no |
| <a name="input_location"></a> [location](#input\_location) | vnet region location | `string` | n/a | yes |
| <a name="input_log_analytics_workspace_name"></a> [log\_analytics\_workspace\_name](#input\_log\_analytics\_workspace\_name) | log analytics workspace name | `string` | `null` | no |
| <a name="input_name"></a> [name](#input\_name) | virtual machine resource name | `string` | n/a | yes |
| <a name="input_nva_type"></a> [nva\_type](#input\_nva\_type) | type of network virtual appliance - opnsense, linux | `string` | `"opnsense"` | no |
| <a name="input_prefix"></a> [prefix](#input\_prefix) | prefix to append before all resources | `string` | `""` | no |
| <a name="input_public_ip0_name"></a> [public\_ip0\_name](#input\_public\_ip0\_name) | public ip address name for untrust interface of instance 0 | `string` | `null` | no |
| <a name="input_public_ip1_name"></a> [public\_ip1\_name](#input\_public\_ip1\_name) | public ip address name for untrust interface of instance 1 | `string` | `null` | no |
| <a name="input_resource_group"></a> [resource\_group](#input\_resource\_group) | resource group name | `any` | n/a | yes |
| <a name="input_scenario_option"></a> [scenario\_option](#input\_scenario\_option) | scenario\_option = Active-Active, TwoNics | `string` | `"TwoNics"` | no |
| <a name="input_source_image_offer"></a> [source\_image\_offer](#input\_source\_image\_offer) | source image reference offer | `string` | `"0001-com-ubuntu-server-focal"` | no |
| <a name="input_source_image_publisher"></a> [source\_image\_publisher](#input\_source\_image\_publisher) | source image reference publisher | `string` | `"Canonical"` | no |
| <a name="input_source_image_sku"></a> [source\_image\_sku](#input\_source\_image\_sku) | source image reference sku | `string` | `"20_04-lts"` | no |
| <a name="input_source_image_version"></a> [source\_image\_version](#input\_source\_image\_version) | source image reference version | `string` | `"latest"` | no |
| <a name="input_storage_account"></a> [storage\_account](#input\_storage\_account) | storage account object | `any` | `null` | no |
| <a name="input_subnet_id_trust"></a> [subnet\_id\_trust](#input\_subnet\_id\_trust) | subnet id for trust interface | `string` | n/a | yes |
| <a name="input_subnet_id_untrust"></a> [subnet\_id\_untrust](#input\_subnet\_id\_untrust) | subnet id for untrust interface | `string` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | tags for all hub resources | `map(any)` | `null` | no |
| <a name="input_use_vm_extension"></a> [use\_vm\_extension](#input\_use\_vm\_extension) | use virtual machine extension | `bool` | `false` | no |
| <a name="input_user_assigned_ids"></a> [user\_assigned\_ids](#input\_user\_assigned\_ids) | list of identity ids | `list(any)` | `[]` | no |
| <a name="input_virtual_network_id"></a> [virtual\_network\_id](#input\_virtual\_network\_id) | virtual network id | `string` | `null` | no |
| <a name="input_vm_extension_auto_upgrade_minor_version"></a> [vm\_extension\_auto\_upgrade\_minor\_version](#input\_vm\_extension\_auto\_upgrade\_minor\_version) | vm extension settings | `bool` | `true` | no |
| <a name="input_vm_extension_publisher"></a> [vm\_extension\_publisher](#input\_vm\_extension\_publisher) | vm extension publisher | `string` | `"Microsoft.OSTCExtensions"` | no |
| <a name="input_vm_extension_settings"></a> [vm\_extension\_settings](#input\_vm\_extension\_settings) | vm extension settings | `string` | `""` | no |
| <a name="input_vm_extension_type"></a> [vm\_extension\_type](#input\_vm\_extension\_type) | vm extension type | `string` | `"CustomScriptForLinux"` | no |
| <a name="input_vm_extension_type_handler_version"></a> [vm\_extension\_type\_handler\_version](#input\_vm\_extension\_type\_handler\_version) | vm extension type | `string` | `"1.5"` | no |
| <a name="input_zone"></a> [zone](#input\_zone) | availability zone for supported regions | `string` | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_nva_0"></a> [nva\_0](#output\_nva\_0) | n/a |
| <a name="output_public_ip_untrust_0"></a> [public\_ip\_untrust\_0](#output\_public\_ip\_untrust\_0) | n/a |
| <a name="output_public_ip_untrust_1"></a> [public\_ip\_untrust\_1](#output\_public\_ip\_untrust\_1) | n/a |
<!-- END_TF_DOCS -->
