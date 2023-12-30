
variable "location" {
  description = "(Optional) The location/region where the core network will be created. The full list of Azure regions can be found at https://azure.microsoft.com/regions"
  type        = string
  default     = ""
}

variable "resource_group_name" {
  description = "(Required) The name of the resource group where the load balancer resources will be imported."
  type        = string
}

variable "prefix" {
  description = "(Required) Default prefix to use with your resource names."
  type        = string
  default     = "azure_lb"
}

variable "enable_ha_ports" {
  description = "(Optional) Enable HA ports. Defaults to false."
  type        = bool
  default     = false
}

variable "allocation_method" {
  description = "(Required) Defines how an IP address is assigned. Options are Static or Dynamic."
  type        = string
  default     = "Static"
}

variable "tags" {
  type    = map(string)
  default = {}
}

variable "type" {
  description = "(Optional) Defined if the loadbalancer is private or public"
  type        = string
  default     = "public"
}

variable "frontend_subnet_id" {
  description = "(Optional) Frontend subnet id to use when in private mode"
  type        = string
  default     = ""
}

variable "frontend_private_ip_address" {
  description = "(Optional) Private ip address to assign to frontend. Use it with type = private"
  type        = string
  default     = ""
}

variable "frontend_private_ip_address_allocation" {
  description = "(Optional) Frontend ip allocation type (Static or Dynamic)"
  type        = string
  default     = "Dynamic"
}

variable "lb_sku" {
  description = "(Optional) The SKU of the Azure Load Balancer. Accepted values are Basic and Standard."
  type        = string
  default     = "Standard"
}

variable "pip_sku" {
  description = "(Optional) The SKU of the Azure Public IP. Accepted values are Basic and Standard."
  type        = string
  default     = "Standard"
}

variable "name" {
  description = "(Optional) Name of the load balancer. If it is set, the 'prefix' variable will be ignored."
  type        = string
  default     = ""
}

variable "pip_name" {
  description = "(Optional) Name of public ip. If it is set, the 'prefix' variable will be ignored."
  type        = string
  default     = ""
}

variable "frontend_ip_configuration" {
  description = "(Optional) Name of the frontend ip configuration for private load balancer. If it is set, the 'prefix' variable will be ignored."
  type = list(object({
    name                          = string
    zones                         = optional(list(string), ["1", "2", "3"]) # ["1", "2", "3"], "Zone-redundant"
    subnet_id                     = optional(string, null)
    private_ip_address_version    = optional(string, "IPv4")    # IPv4 or IPv6
    private_ip_address_allocation = optional(string, "Dynamic") # Static or Dynamic
    private_ip_address            = optional(string, null)
    public_ip_address_id          = optional(string, null)
    public_ip_prefix_id           = optional(string, null)
  }))
  default = []
}

variable "probes" {
  description = "(Optional) Protocols to be used for lb health probes. Format as [protocol, port, request_path]"
  type = list(object({
    name         = string
    protocol     = optional(string, "Tcp")
    port         = optional(string, "80")
    request_path = optional(string, null)
    interval     = optional(number, 5)
  }))
  default = []
}

variable "lb_rules" {
  description = "(Optional) Protocols to be used for lb rules. Format as [frontend_port, protocol, backend_port]"
  type = list(object({
    name                           = string
    protocol                       = optional(string, "Tcp") # Tcp, Udp, All
    frontend_port                  = optional(string, "80")  # 0-65534
    backend_port                   = optional(string, "80")  # 0-65534
    frontend_ip_configuration_name = string
    backend_address_pool_name      = optional(list(string), [])
    enable_floating_ip             = optional(bool, false)
    probe_name                     = string
    idle_timeout_in_minutes        = optional(number, 30)
    load_distribution              = optional(string, "Default") # Default, SourceIP, SourceIPProtocol

  }))
  default = []
}

variable "nat_rules" {
  description = "(Optional) Protocols to be used for nat rules. Format as [frontend_port, protocol, backend_port]"
  type = list(object({
    name                           = string
    protocol                       = optional(string, "Tcp") # Tcp, Udp, All
    frontend_port                  = optional(string, "80")  # 0-65534
    backend_port                   = optional(string, "80")  # 0-65534
    frontend_ip_configuration_name = string
  }))
  default = []
}

variable "lb_probe_unhealthy_threshold" {
  description = "Number of times the load balancer health probe has an unsuccessful attempt before considering the endpoint unhealthy."
  type        = number
  default     = 1
}

variable "backend_pools" {
  type = list(object({
    name = string
    interfaces = optional(list(object({
      ip_configuration_name = string
      network_interface_id  = string
    })), [])
    addresses = optional(list(object({
      name                                = string
      virtual_network_id                  = optional(string, null)
      ip_address                          = optional(string, null)
      backend_address_ip_configuration_id = optional(string, null)
    })), [])
  }))
  default = []
}

variable "private_dns_zone" {
  description = "private dns zone"
  type        = string
  default     = null
}

variable "dns_host" {
  description = "load balancer dns host name"
  type        = string
  default     = null
}

