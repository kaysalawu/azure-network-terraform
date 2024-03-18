

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_megaport"></a> [megaport](#requirement\_megaport) | 0.4.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) | n/a |
| <a name="provider_megaport"></a> [megaport](#provider\_megaport) | 0.4.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [azurerm_express_route_circuit.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/express_route_circuit) | resource |
| [azurerm_express_route_circuit_authorization.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/express_route_circuit_authorization) | resource |
| [azurerm_express_route_circuit_peering.microsoft](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/express_route_circuit_peering) | resource |
| [azurerm_express_route_circuit_peering.private](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/express_route_circuit_peering) | resource |
| [azurerm_express_route_connection.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/express_route_connection) | resource |
| [azurerm_virtual_network_gateway_connection.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_network_gateway_connection) | resource |
| [megaport_azure_connection.this](https://registry.terraform.io/providers/megaport/megaport/0.4.0/docs/resources/azure_connection) | resource |
| [megaport_mcr.this](https://registry.terraform.io/providers/megaport/megaport/0.4.0/docs/resources/mcr) | resource |
| [megaport_location.this](https://registry.terraform.io/providers/megaport/megaport/0.4.0/docs/data-sources/location) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_azure_location"></a> [azure\_location](#input\_azure\_location) | azure region | `any` | n/a | yes |
| <a name="input_circuits"></a> [circuits](#input\_circuits) | megaport circuits | <pre>list(object({<br>    name                       = string<br>    connection_target          = string<br>    location                   = string<br>    peering_location           = string<br>    peering_type               = optional(string, "AzurePrivatePeering")<br>    advertised_public_prefixes = optional(list(string))<br>    service_provider_name      = optional(string, "Megaport")<br>    bandwidth_in_mbps          = optional(number, 50)<br>    requested_vlan             = optional(number, 0)<br>    mcr_name                   = string<br>    sku_tier                   = optional(string, "Standard")<br>    sku_family                 = optional(string, "MeteredData")<br><br>    primary_peer_address_prefix   = string<br>    secondary_peer_address_prefix = string<br>    virtual_network_gateway_id    = optional(string, null)<br>    express_route_gateway_id      = optional(string, null)<br>    auto_create_private_peering   = optional(bool, true)<br>    auto_create_microsoft_peering = optional(bool, true)<br>  }))</pre> | `[]` | no |
| <a name="input_log_analytics_workspace_name"></a> [log\_analytics\_workspace\_name](#input\_log\_analytics\_workspace\_name) | log analytics workspace name | `string` | `null` | no |
| <a name="input_mcr"></a> [mcr](#input\_mcr) | megaport cloud router | <pre>list(object({<br>    name          = string<br>    port_speed    = number<br>    requested_asn = number<br>  }))</pre> | `[]` | no |
| <a name="input_megaport_location"></a> [megaport\_location](#input\_megaport\_location) | megaport location | `any` | n/a | yes |
| <a name="input_prefix"></a> [prefix](#input\_prefix) | prefix | `string` | `"megaport"` | no |
| <a name="input_resource_group"></a> [resource\_group](#input\_resource\_group) | Name of the resource group | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_expressroute_circuits"></a> [expressroute\_circuits](#output\_expressroute\_circuits) | n/a |
<!-- END_TF_DOCS -->
