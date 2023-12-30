
variable "prefix" {
  description = "prefix to append before all resources"
  type        = string
}

variable "firewall_policy_id" {
  description = "firewall policy id"
  type        = string
}

variable "application_rule_collection" {
  type = list(object({
    name     = string
    priority = number
    action   = string
    rule = list(object({
      name              = string
      protocols         = list(string)
      source_ip_groups  = list(string)
      destination_fqdns = list(string)
      destination_ports = list(string)
    }))
  }))
  default = []
}

variable "network_rule_collection" {
  type = list(object({
    name     = string
    priority = number
    action   = string
    rule = list(object({
      name                  = string
      protocols             = list(string)
      source_addresses      = list(string)
      destination_addresses = list(string)
      destination_ports     = list(string)
    }))
  }))
  default = []
}

variable "nat_rule_collection" {
  type = list(object({
    name     = string
    priority = number
    action   = string
    rule = list(object({
      name                  = string
      protocols             = list(string)
      source_addresses      = list(string)
      destination_addresses = string
      destination_ports     = list(string)
      translated_address    = string
      translated_port       = string
    }))
  }))
  default = []
}
