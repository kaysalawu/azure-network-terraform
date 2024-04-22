
variable "resource_group" {
  description = "resource group name"
  type        = any
}

variable "prefix" {
  description = "prefix to append before all resources"
  type        = string
}

variable "env" {
  description = "environment name"
  type        = string
  default     = "dev"
}

variable "location" {
  description = "vnet region location"
  type        = string
}

variable "tags" {
  description = "tags for all hub resources"
  type        = map(any)
  default     = {}
}

variable "storage_account" {
  description = "storage account object"
  type        = any
  default     = null
}

variable "enable_diagnostics" {
  description = "enable diagnostics"
  type        = bool
  default     = false
}

variable "log_analytics_workspace_name" {
  description = "log analytics workspace name"
  type        = string
  default     = null
}

variable "network_watcher_resource_group" {
  description = "network watcher resource group"
  type        = string
  default     = null
}

variable "network_watcher_name" {
  description = "network watcher name"
  type        = string
  default     = null
}

variable "flow_log_nsg_ids" {
  description = "flow log nsg id"
  type        = list(string)
  default     = []
}

variable "admin_username" {
  description = "test username. please change for production"
  type        = string
  default     = "azureuser"
}

variable "admin_password" {
  description = "test password. please change for production"
  type        = string
  default     = "Password123"
}

variable "ssh_public_key" {
  description = "sh public key data"
  type        = string
  default     = null
}

variable "dns_zones_linked_to_vnet" {
  description = "dns zones linked to vnet"
  type = list(object({
    name                 = string
    registration_enabled = optional(bool, false)
  }))
  default = []
}

variable "nsg_subnet_map" {
  description = "subnets to associate to nsg"
  type        = map(any)
  default     = {}
}

variable "dns_zone_linked_rulesets" {
  description = "private dns rulesets"
  type        = map(any)
  default     = {}
}

variable "vnets_linked_to_ruleset" {
  description = "private dns rulesets"
  type = list(object({
    name    = string
    vnet_id = string
  }))
  default = []
}

variable "config_vnet" {
  type = object({
    address_space                = list(string)
    subnets                      = optional(map(any), {})
    nsg_id                       = optional(string)
    dns_servers                  = optional(list(string))
    bgp_community                = optional(string, null)
    ddos_protection_plan_id      = optional(string, null)
    encryption_enabled           = optional(bool, false)
    encryption_enforcement       = optional(string, "AllowUnencrypted") # DropUnencrypted, AllowUnencrypted
    enable_private_dns_resolver  = optional(bool, false)
    enable_ars                   = optional(bool, false)
    enable_express_route_gateway = optional(bool, false)
    nat_gateway_subnet_names     = optional(list(string), [])
    subnet_names_private_dns     = optional(list(string), [])

    private_dns_inbound_subnet_name  = optional(string, null)
    private_dns_outbound_subnet_name = optional(string, null)
    ruleset_dns_forwarding_rules     = optional(map(any), {})

    vpn_gateway_ip_config0_apipa_addresses = optional(list(string), ["169.254.21.1"])
    vpn_gateway_ip_config1_apipa_addresses = optional(list(string), ["169.254.21.5"])
  })
}

variable "config_s2s_vpngw" {
  type = object({
    enable        = optional(bool, false)
    sku           = optional(string, "VpnGw1AZ")
    active_active = optional(bool, true)

    private_ip_address_enabled  = optional(bool, true)
    remote_vnet_traffic_enabled = optional(bool, true)
    virtual_wan_traffic_enabled = optional(bool, true)

    ip_configuration = optional(list(object({
      name                          = string
      subnet_id                     = optional(string)
      public_ip_address_name        = optional(string)
      private_ip_address_allocation = optional(string)
      apipa_addresses               = optional(list(string))
      })),
      [
        { name = "ipconf0" },
        { name = "ipconf1" }
      ]
    )
    bgp_settings = optional(object({
      asn = optional(string)
    }))
  })
  default = {
    enable        = false
    sku           = "VpnGw1AZ"
    active_active = true
    ip_configuration = [
      { name = "ip-config0" },
      { name = "ip-config1" }
    ]
    bgp_settings = {
      asn = 65515
    }
  }
}

variable "config_p2s_vpngw" {
  type = object({
    enable        = optional(bool, false)
    sku           = optional(string, "VpnGw1AZ")
    active_active = optional(bool, false)

    custom_route_address_prefixes = optional(list(string), [])

    vpn_client_configuration = optional(object({
      address_space = optional(list(string))
      clients = optional(list(object({
        name = string
      })))
    }))

    ip_configuration = optional(list(object({
      name                   = string
      public_ip_address_name = optional(string)
    })))
  })

  default = {
    enable = false
    sku    = "VpnGw1AZ"
    ip_configuration = [
      { name = "ip-config", public_ip_address_name = null },
    ]
  }
}

variable "vpn_client_configuration" {
  description = "vpn client configuration for vnet gateway"
  type = object({
    address_space = list(string)
    clients = list(object({
      name = string
    }))
  })
  default = {
    address_space = []
    clients       = []
  }
}

variable "config_ergw" {
  type = object({
    enable        = optional(bool, false)
    sku           = optional(string, "ErGw1AZ")
    active_active = optional(bool, false)
  })
  default = {
    enable = false
    sku    = "ErGw1AZ"
  }
}

variable "config_firewall" {
  type = object({
    enable             = optional(bool, false)
    firewall_sku       = optional(string, "Basic")
    firewall_policy_id = optional(string, null)
  })
  default = {
    enable             = false,
    firewall_sku       = "Basic"
    firewall_policy_id = null
  }
}

variable "config_nva" {
  type = object({
    enable           = optional(bool, false)
    type             = optional(string, "cisco")
    ilb_untrust_ip   = optional(string)
    ilb_trust_ip     = optional(string)
    ilb_untrust_ipv6 = optional(string)
    ilb_trust_ipv6   = optional(string)
    custom_data      = optional(string)
    scenario_option  = optional(string, "TwoNics") # Active-Active, TwoNics
    opn_type         = optional(string, "TwoNics") # Primary, Secondary, TwoNics
    enable_ipv6      = optional(bool, false)
  })
  default = {
    enable           = false
    type             = "cisco"
    internal_lb_addr = null
    custom_data      = null
    scenario_option  = "TwoNics"
    opn_type         = "TwoNics"
    enable_ipv6      = false
  }
}

variable "delegation" {
  type = list(object({
    name = string
    service_delegation = list(object({
      name    = string
      actions = list(string)
    }))
  }))
  default = [
    {
      name = "Microsoft.Web/serverFarms"
      service_delegation = [
        {
          name    = "Microsoft.Web/serverFarms"
          actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
        }
      ]
    },
    {
      name = "Microsoft.Network/dnsResolvers"
      service_delegation = [
        {
          name    = "Microsoft.Network/dnsResolvers"
          actions = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
        }
      ]
    }
  ]
}

variable "user_assigned_ids" {
  description = "resource ids of user assigned identity"
  type        = list(string)
  default     = []
}

variable "nva_image" {
  description = "source image reference"
  type        = map(any)
  default = {
    "cisco" = {
      publisher = "cisco"
      offer     = "cisco-csr-1000v"
      sku       = "17_3_4a-byol"
      version   = "latest"
    }
    "linux" = {
      publisher = "Canonical"
      offer     = "0001-com-ubuntu-server-focal"
      sku       = "20_04-lts"
      version   = "latest"
    }
    "opnsense" = {
      publisher = "thefreebsdfoundation"
      offer     = "freebsd-13_1"
      sku       = "13_1-release"
      version   = "latest"
    }
  }
}

# parameters
#--------------------------------------------------

variable "opn_script_uri" {
  description = "URI for Custom OPN Script and Config"
  type        = string
  default     = "https://raw.githubusercontent.com/kaysalawu/opnazure/master/scripts/"
}

variable "shell_script_name" {
  description = "Shell Script to be executed"
  type        = string
  default     = "configureopnsense.sh"
}

variable "opn_version" {
  description = "OPN Version"
  type        = string
  default     = "23.7"
}

variable "walinux_version" {
  description = "WALinuxAgent Version"
  type        = string
  default     = "2.9.1.1"
}

variable "scenario_option" {
  description = "scenario_option = Active-Active, TwoNics"
  type        = string
  default     = "TwoNics"
}

variable "opn_type" {
  description = "opn type = Primary, Secondary, TwoNics"
  type        = string
  default     = "TwoNics"
}

variable "deploy_windows_mgmt" {
  description = "deploy windows management vm in a management subnet"
  type        = bool
  default     = false
}

variable "mgmt_subnet_address_prefix" {
  description = "management subnet address prefix"
  type        = string
  default     = ""
}

variable "trusted_subnet_address_prefix" {
  description = "trusted subnet address prefix"
  type        = string
  default     = ""
}

variable "enable_ipv6" {
  description = "enable ipv6"
  type        = bool
  default     = true
}
