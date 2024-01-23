
variable "resource_group" {
  type = string
}

variable "prefix" {
  type = string
}

variable "tags" {
  description = "A map of tags to apply to all resources"
  type        = map(any)
  default     = {}
}

variable "location" {
  type = string
}

variable "subnet_id" {
  type = string
}

variable "disable_bgp_route_propagation" {
  type    = bool
  default = false
}

variable "routes" {
  type = list(object({
    name                   = string
    address_prefix         = list(string)
    next_hop_type          = string
    next_hop_in_ip_address = optional(string, null)
    delay_creation         = optional(string, "0s")
  }))
  default = []
}
