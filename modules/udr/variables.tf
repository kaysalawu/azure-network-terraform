
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

variable "destinations" {
  type    = map(any)
  default = {}
}

variable "next_hop_type" {
  type    = string
  default = "VirtualAppliance"
}

variable "next_hop_in_ip_address" {
  type    = string
  default = null
}

variable "disable_bgp_route_propagation" {
  type    = bool
  default = false
}
