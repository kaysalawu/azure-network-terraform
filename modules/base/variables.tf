
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

variable "create_private_dns_zone" {
  description = "create private dns zone"
  type        = bool
  default     = false
}

variable "private_dns_zone_name" {
  description = "private dns zone name"
  type        = string
  default     = null
}

variable "private_dns_zone_prefix" {
  description = "private dns prefix"
  type        = string
  default     = null
}

variable "private_dns_zone_linked_external_vnets" {
  description = "private dns zone"
  type        = map(any)
  default     = {}
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

variable "private_dns_ruleset_linked_external_vnets" {
  description = "private dns rulesets"
  type        = map(any)
  default     = {}
}

variable "config_vnet" {
  type = object({
    address_space                = list(string)
    subnets                      = optional(map(any), {})
    nsg_id                       = optional(string)
    dns_servers                  = optional(list(string))
    enable_private_dns_resolver  = optional(bool, false)
    enable_ars                   = optional(bool, false)
    enable_express_route_gateway = optional(bool, false)
    nat_gateway_subnet_names     = optional(list(string), [])
    subnet_names_private_dns     = optional(list(string), [])

    private_dns_inbound_subnet_name  = optional(string, null)
    private_dns_outbound_subnet_name = optional(string, null)
    ruleset_dns_forwarding_rules     = optional(map(any), {})

    express_route_gateway_sku = optional(string, "Standard")

    vpn_gateway_ip_config0_apipa_addresses = optional(list(string), ["169.254.21.1"])
    vpn_gateway_ip_config1_apipa_addresses = optional(list(string), ["169.254.21.5"])
  })
  #default = {}
}

variable "config_s2s_vpngw" {
  type = object({
    enable             = optional(bool, false)
    sku                = optional(string, "VpnGw1AZ")
    active_active      = optional(bool, false)
    create_dashboard   = optional(bool, true)
    enable_diagnostics = optional(bool, false)
    ip_configuration = optional(list(object({
      name                          = string
      subnet_id                     = optional(string)
      public_ip_address_id          = optional(string)
      private_ip_address_allocation = optional(string, "Dynamic")
    })))
    bgp_settings = optional(object({
      asn = optional(string, 65515)
    }))
  })
  default = {
    enable             = false
    sku                = "VpnGw1AZ"
    create_dashboard   = true
    enable_diagnostics = false
    bgp_settings = {
      asn = 65515
    }
  }
}

variable "config_p2s_vpngw" {
  type = object({
    enable             = optional(bool, false)
    sku                = optional(string, "VpnGw1AZ")
    active_active      = optional(bool, false)
    create_dashboard   = optional(bool, true)
    enable_diagnostics = optional(bool, false)

    custom_route_address_prefixes = optional(list(string), [])

    vpn_client_configuration = optional(object({
      address_space = list(string)
      clients = list(object({
        name = string
      }))
    }))

    ip_configuration = optional(list(object({
      name                   = string
      public_ip_address_name = optional(string)
    })))
  })

  default = {
    enable             = false
    sku                = "VpnGw1AZ"
    create_dashboard   = true
    enable_diagnostics = false
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
    enable             = optional(bool, false)
    sku                = optional(string, "ErGw1AZ")
    active_active      = optional(bool, false)
    create_dashboard   = optional(bool, true)
    enable_diagnostics = optional(bool, false)
  })
  default = {
    enable             = false
    sku                = "ErGw1AZ"
    create_dashboard   = true
    enable_diagnostics = false
  }
}

variable "config_firewall" {
  type = object({
    enable             = optional(bool, false)
    firewall_sku       = optional(string, "Basic")
    firewall_policy_id = optional(string, null)
    create_dashboard   = optional(bool, true)
    enable_diagnostics = optional(bool, false)
  })
  default = {
    enable             = false,
    firewall_sku       = "Basic"
    firewall_policy_id = null
    create_dashboard   = true
    enable_diagnostics = false
  }
}

variable "config_nva" {
  type = object({
    enable             = optional(bool, false)
    type               = optional(string, "cisco")
    internal_lb_addr   = optional(string)
    custom_data        = optional(string)
    create_dashboard   = optional(bool, true)
    enable_diagnostics = optional(bool, false)
  })
  default = {
    enable           = false
    type             = "cisco"
    internal_lb_addr = null
    custom_data      = null
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
