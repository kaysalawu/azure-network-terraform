
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

variable "admin_username" {
  description = "private dns zone name"
  type        = string
  default     = "azureuser"
}

variable "admin_password" {
  description = "private dns zone name"
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

variable "vnet_config" {
  type = list(object({
    address_space               = list(string)
    subnets                     = optional(map(any), {})
    nsg_id                      = optional(string)
    dns_servers                 = optional(list(string))
    enable_private_dns_resolver = optional(bool, false)
    enable_ars                  = optional(bool, false)
    enable_er_gateway           = optional(bool, false)
    nat_gateway_subnet_names    = optional(list(string), [])
    subnet_names_private_dns    = optional(list(string), [])

    private_dns_inbound_subnet_name  = optional(string, null)
    private_dns_outbound_subnet_name = optional(string, null)

    enable_firewall    = optional(bool, false)
    firewall_sku       = optional(string, "Basic")
    firewall_policy_id = optional(string, null)

    er_gateway_sku = optional(string, "Standard")

    enable_vpn_gateway                     = optional(bool, false)
    vpn_gateway_sku                        = optional(string, "VpnGw2AZ")
    vpn_gateway_asn                        = optional(string, 65515)
    vpn_gateway_ip_config0_apipa_addresses = optional(list(string), ["169.254.21.1"])
    vpn_gateway_ip_config1_apipa_addresses = optional(list(string), ["169.254.21.5"])
  }))
  default = []
}

variable "vm_config" {
  type = list(object({
    name                 = string
    subnet               = string
    vnet_number          = optional(string, 0)
    dns_host             = optional(string)
    zone                 = optional(string, null)
    size                 = optional(string, "Standard_B2s")
    private_ip           = optional(string, null)
    enable_public_ip     = optional(bool, false)
    custom_data          = optional(string, null)
    enable_ip_forwarding = optional(bool, false)
    use_vm_extension     = optional(bool, false)
    source_image         = optional(string, "ubuntu")
    dns_servers          = optional(list(string), [])
    delay_creation       = optional(string, "0s")
  }))
  default = []
}

/* variable "metric_categories_firewall" {
  type    = list(string)
  default = ["AllMetrics"]
} */

/* variable "log_categories_firewall" {
  type = list(string)
  default = [
    "AzureFirewallApplicationRule",
    "AzureFirewallNetworkRule",
    "AzureFirewallDnsProxy"
  ]
} */

variable "metric_categories_firewall" {
  type = list(any)
  default = [
    {
      "enabled" = false,
      "retentionPolicy" = {
        "days" : 0,
        "enabled" = false
      },
      "category" = "AllMetrics"
    }
  ]
}

variable "log_categories_firewall" {
  type = list(any)
  default = [
    {
      "category"      = "AZFWNetworkRule",
      "categoryGroup" = null,
      "enabled"       = true,
      "retentionPolicy" = {
        "days"    = 0,
        "enabled" = false
      }
    },
    {
      "category"      = "AZFWApplicationRule",
      "categoryGroup" = null,
      "enabled"       = true,
      "retentionPolicy" = {
        "days"    = 0,
        "enabled" = false
      }
    },
    {
      "category"      = "AZFWNatRule",
      "categoryGroup" = null,
      "enabled"       = true,
      "retentionPolicy" = {
        "days"    = 0,
        "enabled" = false
      }
    },
    {
      "category"      = "AZFWThreatIntel",
      "categoryGroup" = null,
      "enabled"       = false,
      "retentionPolicy" = {
        "days"    = 0,
        "enabled" = false
      }
    },
    {
      "category"      = "AZFWIdpsSignature",
      "categoryGroup" = null,
      "enabled"       = false,
      "retentionPolicy" = {
        "days"    = 0,
        "enabled" = false
      }
    },
    {
      "category"      = "AZFWDnsQuery",
      "categoryGroup" = null,
      "enabled"       = false,
      "retentionPolicy" = {
        "days"    = 0,
        "enabled" = false
      }
    },
    {
      "category"      = "AZFWFqdnResolveFailure",
      "categoryGroup" = null,
      "enabled"       = false,
      "retentionPolicy" = {
        "days"    = 0,
        "enabled" = false
      }
    },
    {
      "category"      = "AZFWFatFlow",
      "categoryGroup" = null,
      "enabled"       = false,
      "retentionPolicy" = {
        "days"    = 0,
        "enabled" = false
      }
    },
    {
      "category"      = "AZFWFlowTrace",
      "categoryGroup" = null,
      "enabled"       = false,
      "retentionPolicy" = {
        "days"    = 0,
        "enabled" = false
      }
    },
    {
      "category"      = "AZFWApplicationRuleAggregation",
      "categoryGroup" = null,
      "enabled"       = false,
      "retentionPolicy" = {
        "days"    = 0,
        "enabled" = false
      }
    },
    {
      "category"      = "AZFWNetworkRuleAggregation",
      "categoryGroup" = null,
      "enabled"       = false,
      "retentionPolicy" = {
        "days"    = 0,
        "enabled" = false
      }
    },
    {
      "category"      = "AZFWNatRuleAggregation",
      "categoryGroup" = null,
      "enabled"       = false,
      "retentionPolicy" = {
        "days"    = 0,
        "enabled" = false
      }
    }
  ]
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
