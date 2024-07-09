

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
| <a name="provider_time"></a> [time](#provider\_time) | n/a |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [azurerm_express_route_circuit.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/express_route_circuit) | resource |
| [azurerm_express_route_circuit_authorization.vnet](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/express_route_circuit_authorization) | resource |
| [azurerm_express_route_circuit_authorization.vwan](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/express_route_circuit_authorization) | resource |
| [azurerm_express_route_circuit_peering.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/express_route_circuit_peering) | resource |
| [azurerm_express_route_connection.vwan](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/express_route_connection) | resource |
| [azurerm_portal_dashboard.express_route](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/portal_dashboard) | resource |
| [azurerm_virtual_network_gateway_connection.vnet](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_network_gateway_connection) | resource |
| [megaport_azure_connection.primary](https://registry.terraform.io/providers/megaport/megaport/0.4.0/docs/resources/azure_connection) | resource |
| [megaport_azure_connection.secondary](https://registry.terraform.io/providers/megaport/megaport/0.4.0/docs/resources/azure_connection) | resource |
| [megaport_mcr.this](https://registry.terraform.io/providers/megaport/megaport/0.4.0/docs/resources/mcr) | resource |
| [time_sleep.wait_for_peering](https://registry.terraform.io/providers/hashicorp/time/latest/docs/resources/sleep) | resource |
| [time_sleep.wait_for_primary](https://registry.terraform.io/providers/hashicorp/time/latest/docs/resources/sleep) | resource |
| [azurerm_subscription.current](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/subscription) | data source |
| [azurerm_virtual_network_gateway.vnet](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/virtual_network_gateway) | data source |
| [megaport_location.this](https://registry.terraform.io/providers/megaport/megaport/0.4.0/docs/data-sources/location) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_azure_location"></a> [azure\_location](#input\_azure\_location) | azure region | `any` | n/a | yes |
| <a name="input_circuits"></a> [circuits](#input\_circuits) | megaport circuits | <pre>list(object({<br>    name                       = string<br>    location                   = string<br>    peering_location           = string<br>    peering_type               = optional(string, "AzurePrivatePeering")<br>    advertised_public_prefixes = optional(list(string))<br>    service_provider_name      = optional(string, "Megaport")<br>    bandwidth_in_mbps          = optional(number, 50)<br>    requested_vlan             = optional(number, 0)<br>    mcr_name                   = string<br>    sku_tier                   = optional(string, "Standard")<br>    sku_family                 = optional(string, "MeteredData")<br>    enable_mcr_auto_peering    = optional(bool, false) # auto-assign circuit addresses<br>    enable_mcr_peering         = optional(bool, false) # creates layer2 circuit only, layer3 peering will be created on azure side *<br><br>    ipv4_config = object({<br>      primary_peer_address_prefix   = optional(string, null)<br>      secondary_peer_address_prefix = optional(string, null)<br>    })<br>    ipv6_config = optional(object({<br>      enabled                       = optional(bool, false)<br>      create_azure_private_peering  = optional(bool, false) # * creates azure private peering, used when enable_mcr_peering = false and enable_mcr_auto_peering = false<br>      primary_peer_address_prefix   = optional(string, null)<br>      secondary_peer_address_prefix = optional(string, null)<br>    }), {})<br>  }))</pre> | `[]` | no |
| <a name="input_gateway_connections"></a> [gateway\_connections](#input\_gateway\_connections) | express route connection to gateway | <pre>list(object({<br>    express_route_circuit_name   = string<br>    virtual_network_gateway_name = optional(string, null)<br>    express_route_gateway_name   = optional(string, null)<br>  }))</pre> | `[]` | no |
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
