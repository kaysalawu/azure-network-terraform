

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
| [azurerm_express_route_circuit_peering.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/express_route_circuit_peering) | resource |
| [megaport_azure_connection.primary](https://registry.terraform.io/providers/megaport/megaport/0.4.0/docs/resources/azure_connection) | resource |
| [megaport_mcr.this](https://registry.terraform.io/providers/megaport/megaport/0.4.0/docs/resources/mcr) | resource |
| [megaport_location.this](https://registry.terraform.io/providers/megaport/megaport/0.4.0/docs/data-sources/location) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_azure_location"></a> [azure\_location](#input\_azure\_location) | azure region | `any` | n/a | yes |
| <a name="input_circuits"></a> [circuits](#input\_circuits) | megaport circuits | <pre>list(object({<br>    name = string<br>    # connection_target          = string<br>    location                    = string<br>    peering_location            = string<br>    peering_type                = optional(string, "AzurePrivatePeering")<br>    advertised_public_prefixes  = optional(list(string))<br>    service_provider_name       = optional(string, "Megaport")<br>    bandwidth_in_mbps           = optional(number, 50)<br>    requested_vlan              = optional(number, 0)<br>    mcr_name                    = string<br>    sku_tier                    = optional(string, "Standard")<br>    sku_family                  = optional(string, "MeteredData")<br>    auto_create_private_peering = optional(bool, false)<br><br>    ipv4_config = object({<br>      primary_peer_address_prefix   = optional(string, null)<br>      secondary_peer_address_prefix = optional(string, null)<br>    })<br>    ipv6_config = object({<br>      enabled                       = optional(bool, false)<br>      primary_peer_address_prefix   = optional(string, null)<br>      secondary_peer_address_prefix = optional(string, null)<br>    })<br>  }))</pre> | `[]` | no |
| <a name="input_log_analytics_workspace_name"></a> [log\_analytics\_workspace\_name](#input\_log\_analytics\_workspace\_name) | log analytics workspace name | `string` | `null` | no |
| <a name="input_mcr"></a> [mcr](#input\_mcr) | megaport cloud router | <pre>list(object({<br>    name          = string<br>    port_speed    = number<br>    requested_asn = number<br>  }))</pre> | `[]` | no |
| <a name="input_megaport_location"></a> [megaport\_location](#input\_megaport\_location) | megaport location | `any` | n/a | yes |
| <a name="input_prefix"></a> [prefix](#input\_prefix) | prefix | `string` | `"megaport"` | no |
| <a name="input_resource_group"></a> [resource\_group](#input\_resource\_group) | Name of the resource group | `string` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | tags for all hub resources | `map(any)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_express_route_circuit"></a> [express\_route\_circuit](#output\_express\_route\_circuit) | n/a |
| <a name="output_express_route_circuit_peering"></a> [express\_route\_circuit\_peering](#output\_express\_route\_circuit\_peering) | n/a |
| <a name="output_mcr"></a> [mcr](#output\_mcr) | n/a |
<!-- END_TF_DOCS -->
