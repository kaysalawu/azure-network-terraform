
variable "resource_group" {
  description = "The name of the resource group in which the route table will be created"
  type        = string
}

variable "prefix" {
  description = "A short prefix to identify the resource"
  type        = string
}

variable "tags" {
  description = "A map of tags to apply to all resources"
  type        = map(any)
  default     = {}
}

variable "location" {
  description = "The location/region where the route table will be created"
  type        = string
}

variable "subnet_ids" {
  description = "A list of subnet IDs to associate with the route table"
  type        = list(string)
}

variable "disable_bgp_route_propagation" {
  type    = bool
  default = false
}

variable "routes" {
  description = "A list of route objects"
  type = list(object({
    name                   = string
    address_prefix         = list(string)
    next_hop_type          = string
    next_hop_in_ip_address = optional(string, null)
    delay_creation         = optional(string, "0s")
  }))
  default = []
}
