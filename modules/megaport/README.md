

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_megaport"></a> [megaport](#requirement\_megaport) | 0.4.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_azure_location"></a> [azure\_location](#input\_azure\_location) | azure region | `any` | n/a | yes |
| <a name="input_circuits"></a> [circuits](#input\_circuits) | megaport circuits | <pre>list(object({<br>    name                       = string<br>    location                   = string<br>    peering_location           = string<br>    peering_type               = optional(string, "AzurePrivatePeering")<br>    advertised_public_prefixes = optional(list(string))<br>    service_provider_name      = optional(string, "Megaport")<br>    bandwidth_in_mbps          = optional(number, 50)<br>    requested_vlan             = optional(number, 0)<br>    mcr_name                   = string<br>    sku_tier                   = optional(string, "Standard")<br>    sku_family                 = optional(string, "MeteredData")<br><br>    primary_peer_address_prefix_ipv4   = optional(string, null)<br>    secondary_peer_address_prefix_ipv4 = optional(string, null)<br>    primary_peer_address_prefix_ipv6   = optional(string, null)<br>    secondary_peer_address_prefix_ipv6 = optional(string, null)<br><br>    # mcr_config_block creates layer2 and layer3 config on megaport and azure sides<br>    mcr_config = object({<br>      enable_auto_peering    = optional(bool, false) # auto-assign addresses<br>      create_private_peering = optional(bool, false) # use provided addresses<br>    })<br><br>    # azure_config_block is only used when all mcr_config attributes are false<br>    # creates layer2 and layer3 config on azure and megaport sides<br>    azure_config = object({<br>      create_ipv4_peering = optional(bool, false)<br>      create_ipv6_peering = optional(bool, false)<br>    })<br>  }))</pre> | `[]` | no |
| <a name="input_deploy"></a> [deploy](#input\_deploy) | deploy | `bool` | `true` | no |
| <a name="input_gateway_connections"></a> [gateway\_connections](#input\_gateway\_connections) | express route connection to gateway | <pre>list(object({<br>    shared_key                   = optional(string, "nokey")<br>    express_route_circuit_name   = string<br>    virtual_network_gateway_name = optional(string, null)<br>    express_route_gateway_name   = optional(string, null)<br>    associated_route_table_id    = optional(string, null)<br>    inbound_route_map_id         = optional(string, null)<br>    outbound_route_map_id        = optional(string, null)<br>    propagated_route_table = optional(list(object({<br>      labels          = optional(list(string), [])<br>      route_table_ids = optional(list(string), [])<br>    })), null)<br>  }))</pre> | `[]` | no |
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
