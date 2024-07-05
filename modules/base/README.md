

<!-- BEGIN_TF_DOCS -->
## Requirements

No requirements.

## Providers

| Name | Version |
|------|---------|
| <a name="provider_azapi"></a> [azapi](#provider\_azapi) | n/a |
| <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) | n/a |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_azfw"></a> [azfw](#module\_azfw) | ../../modules/azure-firewall | n/a |
| <a name="module_dns_resolver"></a> [dns\_resolver](#module\_dns\_resolver) | ../../modules/private-dns-resolver | n/a |
| <a name="module_ergw"></a> [ergw](#module\_ergw) | ../../modules/vnet-gateway-express-route | n/a |
| <a name="module_nva"></a> [nva](#module\_nva) | ../../modules/network-virtual-appliance | n/a |
| <a name="module_p2s_vpngw"></a> [p2s\_vpngw](#module\_p2s\_vpngw) | ../../modules/vnet-gateway-p2s | n/a |
| <a name="module_s2s_vpngw"></a> [s2s\_vpngw](#module\_s2s\_vpngw) | ../../modules/vnet-gateway-s2s | n/a |

## Resources

| Name | Type |
|------|------|
| [azapi_resource.subnets](https://registry.terraform.io/providers/azure/azapi/latest/docs/resources/resource) | resource |
| [azapi_resource.vnet_flow_log](https://registry.terraform.io/providers/azure/azapi/latest/docs/resources/resource) | resource |
| [azurerm_nat_gateway.nat](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/nat_gateway) | resource |
| [azurerm_nat_gateway_public_ip_association.nat](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/nat_gateway_public_ip_association) | resource |
| [azurerm_network_watcher_flow_log.nsg](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_watcher_flow_log) | resource |
| [azurerm_private_dns_zone_virtual_network_link.dns](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_dns_zone_virtual_network_link) | resource |
| [azurerm_public_ip.ars_pip](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/public_ip) | resource |
| [azurerm_public_ip.nat](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/public_ip) | resource |
| [azurerm_route_server.ars](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/route_server) | resource |
| [azurerm_subnet.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet) | resource |
| [azurerm_subnet_nat_gateway_association.nat](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet_nat_gateway_association) | resource |
| [azurerm_subnet_network_security_group_association.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet_network_security_group_association) | resource |
| [azurerm_subnet_network_security_group_association.this_azapi](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet_network_security_group_association) | resource |
| [azurerm_virtual_network.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_network) | resource |
| [azurerm_log_analytics_workspace.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/log_analytics_workspace) | data source |
| [azurerm_network_watcher.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/network_watcher) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_admin_password"></a> [admin\_password](#input\_admin\_password) | test password. please change for production | `string` | `"Password123"` | no |
| <a name="input_admin_username"></a> [admin\_username](#input\_admin\_username) | test username. please change for production | `string` | `"azureuser"` | no |
| <a name="input_bgp_community"></a> [bgp\_community](#input\_bgp\_community) | bgp community | `string` | `null` | no |
| <a name="input_config_ergw"></a> [config\_ergw](#input\_config\_ergw) | n/a | <pre>object({<br>    enable        = optional(bool, false)<br>    sku           = optional(string, "ErGw1AZ")<br>    active_active = optional(bool, false)<br>  })</pre> | <pre>{<br>  "enable": false,<br>  "sku": "ErGw1AZ"<br>}</pre> | no |
| <a name="input_config_firewall"></a> [config\_firewall](#input\_config\_firewall) | n/a | <pre>object({<br>    enable             = optional(bool, false)<br>    firewall_sku       = optional(string, "Basic")<br>    firewall_policy_id = optional(string, null)<br>  })</pre> | <pre>{<br>  "enable": false,<br>  "firewall_policy_id": null,<br>  "firewall_sku": "Basic"<br>}</pre> | no |
| <a name="input_config_nva"></a> [config\_nva](#input\_config\_nva) | n/a | <pre>object({<br>    enable           = optional(bool, false)<br>    enable_ipv6      = optional(bool, false)<br>    type             = optional(string, "cisco")<br>    ilb_untrust_ip   = optional(string)<br>    ilb_trust_ip     = optional(string)<br>    ilb_untrust_ipv6 = optional(string)<br>    ilb_trust_ipv6   = optional(string)<br>    custom_data      = optional(string)<br>    scenario_option  = optional(string, "TwoNics") # Active-Active, TwoNics<br>    opn_type         = optional(string, "TwoNics") # Primary, Secondary, TwoNics<br>  })</pre> | <pre>{<br>  "custom_data": null,<br>  "enable": false,<br>  "enable_ipv6": false,<br>  "internal_lb_addr": null,<br>  "opn_type": "TwoNics",<br>  "scenario_option": "TwoNics",<br>  "type": "cisco"<br>}</pre> | no |
| <a name="input_config_p2s_vpngw"></a> [config\_p2s\_vpngw](#input\_config\_p2s\_vpngw) | n/a | <pre>object({<br>    enable        = optional(bool, false)<br>    sku           = optional(string, "VpnGw1AZ")<br>    active_active = optional(bool, false)<br><br>    custom_route_address_prefixes = optional(list(string), [])<br><br>    vpn_client_configuration = optional(object({<br>      address_space = optional(list(string))<br>      clients = optional(list(object({<br>        name = string<br>      })))<br>    }))<br><br>    ip_configuration = optional(list(object({<br>      name                   = string<br>      public_ip_address_name = optional(string)<br>    })))<br>  })</pre> | <pre>{<br>  "enable": false,<br>  "ip_configuration": [<br>    {<br>      "name": "ip-config",<br>      "public_ip_address_name": null<br>    }<br>  ],<br>  "sku": "VpnGw1AZ"<br>}</pre> | no |
| <a name="input_config_s2s_vpngw"></a> [config\_s2s\_vpngw](#input\_config\_s2s\_vpngw) | n/a | <pre>object({<br>    enable        = optional(bool, false)<br>    sku           = optional(string, "VpnGw1AZ")<br>    active_active = optional(bool, true)<br><br>    private_ip_address_enabled  = optional(bool, true)<br>    remote_vnet_traffic_enabled = optional(bool, true)<br>    virtual_wan_traffic_enabled = optional(bool, true)<br><br>    ip_configuration = optional(list(object({<br>      name                          = string<br>      subnet_id                     = optional(string)<br>      public_ip_address_name        = optional(string)<br>      private_ip_address_allocation = optional(string)<br>      apipa_addresses               = optional(list(string))<br>      })),<br>      [<br>        { name = "ipconf0" },<br>        { name = "ipconf1" }<br>      ]<br>    )<br>    bgp_settings = optional(object({<br>      asn = optional(string)<br>    }))<br>  })</pre> | <pre>{<br>  "active_active": true,<br>  "bgp_settings": {<br>    "asn": 65515<br>  },<br>  "enable": false,<br>  "ip_configuration": [<br>    {<br>      "name": "ip-config0"<br>    },<br>    {<br>      "name": "ip-config1"<br>    }<br>  ],<br>  "sku": "VpnGw1AZ"<br>}</pre> | no |
| <a name="input_config_vnet"></a> [config\_vnet](#input\_config\_vnet) | n/a | <pre>object({<br>    address_space = list(string)<br>    subnets = optional(map(object({<br>      use_azapi                                     = optional(list(bool), [false])<br>      address_prefixes                              = list(string)<br>      address_prefixes_v6                           = optional(list(string), [])<br>      delegate                                      = optional(list(string), [])<br>      private_endpoint_network_policies             = optional(list(string), ["Disabled"]) # Enabled, Disabled, NetworkSecurityGroupEnabled, RouteTableEnabled<br>      private_link_service_network_policies_enabled = optional(list(bool), [false])<br>    })), {})<br>    nsg_id                       = optional(string)<br>    dns_servers                  = optional(list(string))<br>    bgp_community                = optional(string, null)<br>    ddos_protection_plan_id      = optional(string, null)<br>    encryption_enabled           = optional(bool, false)<br>    encryption_enforcement       = optional(string, "AllowUnencrypted") # DropUnencrypted, AllowUnencrypted<br>    enable_private_dns_resolver  = optional(bool, false)<br>    enable_ars                   = optional(bool, false)<br>    enable_express_route_gateway = optional(bool, false)<br>    nat_gateway_subnet_names     = optional(list(string), [])<br>    subnet_names_private_dns     = optional(list(string), [])<br><br>    enable_vnet_flow_logs           = optional(bool, false)<br>    enable_vnet_flow_logs_analytics = optional(bool, true)<br><br>    private_dns_inbound_subnet_name  = optional(string, null)<br>    private_dns_outbound_subnet_name = optional(string, null)<br>    ruleset_dns_forwarding_rules     = optional(map(any), {})<br><br>    vpn_gateway_ip_config0_apipa_addresses = optional(list(string), ["169.254.21.1"])<br>    vpn_gateway_ip_config1_apipa_addresses = optional(list(string), ["169.254.21.5"])<br>  })</pre> | n/a | yes |
| <a name="input_delegation"></a> [delegation](#input\_delegation) | n/a | <pre>list(object({<br>    name = string<br>    service_delegation = list(object({<br>      name    = string<br>      actions = list(string)<br>    }))<br>  }))</pre> | <pre>[<br>  {<br>    "name": "Microsoft.Web/serverFarms",<br>    "service_delegation": [<br>      {<br>        "actions": [<br>          "Microsoft.Network/virtualNetworks/subnets/action"<br>        ],<br>        "name": "Microsoft.Web/serverFarms"<br>      }<br>    ]<br>  },<br>  {<br>    "name": "Microsoft.Network/dnsResolvers",<br>    "service_delegation": [<br>      {<br>        "actions": [<br>          "Microsoft.Network/virtualNetworks/subnets/join/action"<br>        ],<br>        "name": "Microsoft.Network/dnsResolvers"<br>      }<br>    ]<br>  }<br>]</pre> | no |
| <a name="input_deploy_windows_mgmt"></a> [deploy\_windows\_mgmt](#input\_deploy\_windows\_mgmt) | deploy windows management vm in a management subnet | `bool` | `false` | no |
| <a name="input_dns_zone_linked_rulesets"></a> [dns\_zone\_linked\_rulesets](#input\_dns\_zone\_linked\_rulesets) | private dns rulesets | `map(any)` | `{}` | no |
| <a name="input_dns_zones_linked_to_vnet"></a> [dns\_zones\_linked\_to\_vnet](#input\_dns\_zones\_linked\_to\_vnet) | dns zones linked to vnet | <pre>list(object({<br>    name                 = string<br>    registration_enabled = optional(bool, false)<br>  }))</pre> | `[]` | no |
| <a name="input_enable_diagnostics"></a> [enable\_diagnostics](#input\_enable\_diagnostics) | enable diagnostics | `bool` | `false` | no |
| <a name="input_enable_ipv6"></a> [enable\_ipv6](#input\_enable\_ipv6) | enable ipv6 | `bool` | `false` | no |
| <a name="input_env"></a> [env](#input\_env) | environment name | `string` | `"dev"` | no |
| <a name="input_flow_log_nsg_ids"></a> [flow\_log\_nsg\_ids](#input\_flow\_log\_nsg\_ids) | flow log nsg id | `list(string)` | `[]` | no |
| <a name="input_location"></a> [location](#input\_location) | vnet region location | `string` | n/a | yes |
| <a name="input_log_analytics_workspace_name"></a> [log\_analytics\_workspace\_name](#input\_log\_analytics\_workspace\_name) | log analytics workspace name | `string` | `null` | no |
| <a name="input_mgmt_subnet_address_prefix"></a> [mgmt\_subnet\_address\_prefix](#input\_mgmt\_subnet\_address\_prefix) | management subnet address prefix | `string` | `""` | no |
| <a name="input_network_watcher_name"></a> [network\_watcher\_name](#input\_network\_watcher\_name) | network watcher name | `string` | `null` | no |
| <a name="input_network_watcher_resource_group_name"></a> [network\_watcher\_resource\_group\_name](#input\_network\_watcher\_resource\_group\_name) | network watcher resource group name | `string` | `null` | no |
| <a name="input_nsg_subnet_map"></a> [nsg\_subnet\_map](#input\_nsg\_subnet\_map) | subnets to associate to nsg | `map(any)` | `{}` | no |
| <a name="input_nva_image"></a> [nva\_image](#input\_nva\_image) | source image reference | `map(any)` | <pre>{<br>  "cisco": {<br>    "offer": "cisco-csr-1000v",<br>    "publisher": "cisco",<br>    "sku": "17_3_4a-byol",<br>    "version": "latest"<br>  },<br>  "linux": {<br>    "offer": "0001-com-ubuntu-server-focal",<br>    "publisher": "Canonical",<br>    "sku": "20_04-lts",<br>    "version": "latest"<br>  },<br>  "opnsense": {<br>    "offer": "freebsd-13_1",<br>    "publisher": "thefreebsdfoundation",<br>    "sku": "13_1-release",<br>    "version": "latest"<br>  }<br>}</pre> | no |
| <a name="input_opn_script_uri"></a> [opn\_script\_uri](#input\_opn\_script\_uri) | URI for Custom OPN Script and Config | `string` | `"https://raw.githubusercontent.com/kaysalawu/opnazure/master/scripts/"` | no |
| <a name="input_opn_type"></a> [opn\_type](#input\_opn\_type) | opn type = Primary, Secondary, TwoNics | `string` | `"TwoNics"` | no |
| <a name="input_opn_version"></a> [opn\_version](#input\_opn\_version) | OPN Version | `string` | `"23.7"` | no |
| <a name="input_prefix"></a> [prefix](#input\_prefix) | prefix to append before all resources | `string` | n/a | yes |
| <a name="input_resource_group"></a> [resource\_group](#input\_resource\_group) | resource group name | `any` | n/a | yes |
| <a name="input_scenario_option"></a> [scenario\_option](#input\_scenario\_option) | scenario\_option = Active-Active, TwoNics | `string` | `"TwoNics"` | no |
| <a name="input_shell_script_name"></a> [shell\_script\_name](#input\_shell\_script\_name) | Shell Script to be executed | `string` | `"configureopnsense.sh"` | no |
| <a name="input_ssh_public_key"></a> [ssh\_public\_key](#input\_ssh\_public\_key) | sh public key data | `string` | `null` | no |
| <a name="input_storage_account"></a> [storage\_account](#input\_storage\_account) | storage account object | `any` | `null` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | tags for all hub resources | `map(any)` | `{}` | no |
| <a name="input_trusted_subnet_address_prefix"></a> [trusted\_subnet\_address\_prefix](#input\_trusted\_subnet\_address\_prefix) | trusted subnet address prefix | `string` | `""` | no |
| <a name="input_user_assigned_ids"></a> [user\_assigned\_ids](#input\_user\_assigned\_ids) | resource ids of user assigned identity | `list(string)` | `[]` | no |
| <a name="input_vnets_linked_to_ruleset"></a> [vnets\_linked\_to\_ruleset](#input\_vnets\_linked\_to\_ruleset) | private dns rulesets | <pre>list(object({<br>    name    = string<br>    vnet_id = string<br>  }))</pre> | `[]` | no |
| <a name="input_vpn_client_configuration"></a> [vpn\_client\_configuration](#input\_vpn\_client\_configuration) | vpn client configuration for vnet gateway | <pre>object({<br>    address_space = list(string)<br>    clients = list(object({<br>      name = string<br>    }))<br>  })</pre> | <pre>{<br>  "address_space": [],<br>  "clients": []<br>}</pre> | no |
| <a name="input_walinux_version"></a> [walinux\_version](#input\_walinux\_version) | WALinuxAgent Version | `string` | `"2.9.1.1"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_ars"></a> [ars](#output\_ars) | n/a |
| <a name="output_ars_bgp_asn"></a> [ars\_bgp\_asn](#output\_ars\_bgp\_asn) | n/a |
| <a name="output_ars_bgp_ip0"></a> [ars\_bgp\_ip0](#output\_ars\_bgp\_ip0) | n/a |
| <a name="output_ars_bgp_ip1"></a> [ars\_bgp\_ip1](#output\_ars\_bgp\_ip1) | n/a |
| <a name="output_ars_public_pip"></a> [ars\_public\_pip](#output\_ars\_public\_pip) | n/a |
| <a name="output_ergw"></a> [ergw](#output\_ergw) | n/a |
| <a name="output_ergw_name"></a> [ergw\_name](#output\_ergw\_name) | n/a |
| <a name="output_ergw_public_ip"></a> [ergw\_public\_ip](#output\_ergw\_public\_ip) | n/a |
| <a name="output_firewall"></a> [firewall](#output\_firewall) | n/a |
| <a name="output_firewall_private_ip"></a> [firewall\_private\_ip](#output\_firewall\_private\_ip) | n/a |
| <a name="output_firewall_public_ip"></a> [firewall\_public\_ip](#output\_firewall\_public\_ip) | n/a |
| <a name="output_p2s_client_certificates"></a> [p2s\_client\_certificates](#output\_p2s\_client\_certificates) | n/a |
| <a name="output_p2s_client_certificates_cert_name"></a> [p2s\_client\_certificates\_cert\_name](#output\_p2s\_client\_certificates\_cert\_name) | n/a |
| <a name="output_p2s_client_certificates_cert_pem"></a> [p2s\_client\_certificates\_cert\_pem](#output\_p2s\_client\_certificates\_cert\_pem) | n/a |
| <a name="output_p2s_client_certificates_cert_pfx"></a> [p2s\_client\_certificates\_cert\_pfx](#output\_p2s\_client\_certificates\_cert\_pfx) | n/a |
| <a name="output_p2s_client_certificates_cert_pfx_password"></a> [p2s\_client\_certificates\_cert\_pfx\_password](#output\_p2s\_client\_certificates\_cert\_pfx\_password) | n/a |
| <a name="output_p2s_client_certificates_print"></a> [p2s\_client\_certificates\_print](#output\_p2s\_client\_certificates\_print) | n/a |
| <a name="output_p2s_client_certificates_private_key_pem"></a> [p2s\_client\_certificates\_private\_key\_pem](#output\_p2s\_client\_certificates\_private\_key\_pem) | n/a |
| <a name="output_p2s_vpngw"></a> [p2s\_vpngw](#output\_p2s\_vpngw) | n/a |
| <a name="output_p2s_vpngw_public_ip"></a> [p2s\_vpngw\_public\_ip](#output\_p2s\_vpngw\_public\_ip) | n/a |
| <a name="output_private_dns_forwarding_ruleset"></a> [private\_dns\_forwarding\_ruleset](#output\_private\_dns\_forwarding\_ruleset) | n/a |
| <a name="output_private_dns_inbound_ep"></a> [private\_dns\_inbound\_ep](#output\_private\_dns\_inbound\_ep) | n/a |
| <a name="output_private_dns_outbound_ep"></a> [private\_dns\_outbound\_ep](#output\_private\_dns\_outbound\_ep) | n/a |
| <a name="output_private_dns_resolver"></a> [private\_dns\_resolver](#output\_private\_dns\_resolver) | n/a |
| <a name="output_s2s_vpngw"></a> [s2s\_vpngw](#output\_s2s\_vpngw) | n/a |
| <a name="output_s2s_vpngw_bgp_asn"></a> [s2s\_vpngw\_bgp\_asn](#output\_s2s\_vpngw\_bgp\_asn) | n/a |
| <a name="output_s2s_vpngw_bgp_default_ip0"></a> [s2s\_vpngw\_bgp\_default\_ip0](#output\_s2s\_vpngw\_bgp\_default\_ip0) | n/a |
| <a name="output_s2s_vpngw_bgp_default_ip1"></a> [s2s\_vpngw\_bgp\_default\_ip1](#output\_s2s\_vpngw\_bgp\_default\_ip1) | n/a |
| <a name="output_s2s_vpngw_private_ip0"></a> [s2s\_vpngw\_private\_ip0](#output\_s2s\_vpngw\_private\_ip0) | n/a |
| <a name="output_s2s_vpngw_private_ip1"></a> [s2s\_vpngw\_private\_ip1](#output\_s2s\_vpngw\_private\_ip1) | n/a |
| <a name="output_s2s_vpngw_public_ip0"></a> [s2s\_vpngw\_public\_ip0](#output\_s2s\_vpngw\_public\_ip0) | n/a |
| <a name="output_s2s_vpngw_public_ip1"></a> [s2s\_vpngw\_public\_ip1](#output\_s2s\_vpngw\_public\_ip1) | n/a |
| <a name="output_subnets"></a> [subnets](#output\_subnets) | n/a |
| <a name="output_vnet"></a> [vnet](#output\_vnet) | n/a |
<!-- END_TF_DOCS -->
