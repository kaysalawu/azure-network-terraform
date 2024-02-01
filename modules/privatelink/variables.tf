
variable "resource_group" {
  description = "resource group name"
  type        = any
}

variable "prefix" {
  description = "prefix to append before all resources"
  type        = string
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

variable "nat_ip_config" {
  type = list(object({
    name               = string
    primary            = optional(bool, true)
    subnet_id          = string
    private_ip_address = optional(string, "")
    lb_frontend_ids    = optional(list(any), [])
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

variable "log_analytics_workspace_name" {
  description = "log analytics workspace name"
  type        = string
  default     = null
}
