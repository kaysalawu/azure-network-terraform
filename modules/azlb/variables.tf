
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

variable "remote_port" {
  description = "Protocols to be used for remote vm access. [protocol, backend_port].  Frontend port will be automatically generated starting at 50000 and in the output."
  type        = map(any)
  default     = {}
}

variable "lb_port" {
  description = "Protocols to be used for lb rules. Format as [frontend_port, protocol, backend_port]"
  type        = map(any)
  default     = {}
}

variable "enable_ha_ports" {
  description = "(Optional) Enable HA ports. Defaults to false."
  type        = bool
  default     = false
}

variable "enable_floating_ip" {
  description = "(Optional) Enable floating IP. Defaults to false."
  type        = bool
  default     = false
}

variable "idle_timeout_in_minutes" {
  description = "(Optional) The timeout for the TCP idle connection. The value can be set between 4 and 30 minutes. The default value is 4 minutes."
  type        = number
  default     = 30
}

variable "load_distribution" {
  description = "(Optional) The load distribution policy for this rule. Defaults to 'Default'. Possible values are Default, SourceIP, SourceIPProtocol."
  type        = string
  default     = "Default"
}

variable "lb_probe_unhealthy_threshold" {
  description = "Number of times the load balancer health probe has an unsuccessful attempt before considering the endpoint unhealthy."
  type        = number
  default     = 1
}

variable "lb_probe_interval" {
  description = "Interval in seconds the load balancer health probe rule does a check"
  type        = number
  default     = 5
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

variable "lb_probe" {
  description = "(Optional) Protocols to be used for lb health probes. Format as [protocol, port, request_path]"
  type        = map(any)
  default     = {}
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

variable "backend_address_pools" {
  type = object({
    name = string
    interfaces = optional(list(object({
      name                  = string
      ip_configuration_name = string
      network_interface_id  = string
    })), [])
    addresses = optional(list(object({
      name                                = string
      virtual_network_id                  = optional(string, null)
      ip_address                          = optional(string, null)
      backend_address_ip_configuration_id = optional(string, null)
    })), [])
  })
  default = {
    name       = ""
    interfaces = []
    addresses  = []
  }
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

