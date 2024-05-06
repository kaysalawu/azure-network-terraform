
variable "resource_group" {
  description = "resource group name"
  type        = any
}

variable "prefix" {
  description = "prefix to append before all resources"
  type        = string
}

variable "location" {
  description = "location for network manager and other resources"
  type        = string
  default     = null
}

variable "tags" {
  description = "tags for all hub resources"
  type        = map(any)
  default     = {}
}

variable "use_azpapi" {
  description = "use azpapi"
  type        = bool
  default     = false
}

variable "network_manager_id" {
  description = "network manager id"
  type        = string
}

variable "network_groups" {
  description = "network group"
  type = list(object({
    name           = string
    description    = optional(string)
    member_type    = optional(string, "VirtualNetwork")
    static_members = optional(list(string))
  }))
  default = []
}

variable "connectivity_configurations" {
  description = "connectivity configuration"
  type = list(object({
    name                  = string
    network_group_name    = string
    connectivity_topology = optional(string)
    global_mesh_enabled   = optional(bool, false)
    deploy                = optional(bool, false)

    hub = optional(object({
      resource_id   = string
      resource_type = optional(string, "Microsoft.Network/virtualNetworks")
    }), null)

    applies_to_group = object({
      group_connectivity  = optional(string, "None")
      global_mesh_enabled = optional(bool, false)
      use_hub_gateway     = optional(bool, false)
    })
  }))
  default = []
}

variable "security_admin_configurations" {
  description = "security admin configuration"

  type = list(object({
    name                = string
    description         = optional(string)
    apply_default_rules = optional(bool, true)
    deploy              = optional(bool, false)

    rule_collections = optional(list(object({
      name              = string
      description       = optional(string)
      network_group_ids = list(string)
      rules = list(object({
        name                    = string
        description             = optional(string)
        action                  = string
        direction               = string
        priority                = number
        protocol                = string
        destination_port_ranges = list(string)
        source = list(object({
          address_prefix_type = string
          address_prefix      = string
        }))
        destinations = list(object({
          address_prefix_type = string
          address_prefix      = string
        }))
      }))
    })))
  }))
  default = []
}

variable "connectivity_deployment" {
  description = "connectivity deployment"
  type = object({
    configuration_names = optional(list(string), [])
    configuration_ids   = optional(list(string), [])
  })
  default = {}
}

variable "security_deployment" {
  description = "security deployment"
  type = object({
    configuration_names = optional(list(string), [])
    configuration_ids   = optional(list(string), [])
  })
  default = {}
}
