

variable "prefix" {
  description = "prefix"
  type        = string
  default     = "megaport"
}

variable "location" {
  description = "azure region"
}

variable "resource_group" {
  description = "Name of the resource group"
  type        = string
}

variable "access_key" {
  description = "megaport access key"
}

variable "secret_key" {
  description = "megaport secret key"
}

variable "megaport_locations" {
  description = "megaport locations"
  type        = list(string)
  default = [
    "Telehouse North",
    "Equinix AM1",
    "Interxion FRA6"
  ]
}

variable "mcr" {
  description = "megaport cloud router"
  type = list(object({
    name          = string
    location      = string
    port_speed    = number
    requested_asn = number
  }))
  default = [
    {
      name          = "er1"
      location      = "Interxion FRA6"
      port_speed    = 1000
      requested_asn = 64512
    }
  ]
}

variable "connection" {
  description = "megaport connection"
  type = list(object({
    vxc_name       = string
    rate_limit     = number
    requested_vlan = optional(number, 0)
    service_key    = string
    circuit_name   = string
    mcr_name       = string

    private_peering = optional(object({
      peer_asn         = number
      requested_vlan   = number
      primary_subnet   = optional(string, "172.16.0.0/30")
      secondary_subnet = optional(string, "172.16.0.4/30")
      shared_key       = optional(string, null)
    }), null)

    microsoft_peering = optional(object({
      peer_asn         = number
      requested_vlan   = number
      primary_subnet   = string
      secondary_subnet = string
      shared_key       = string
      public_prefixes  = list(string)
    }), null)

    gateway_connection = optional(object({
      name                       = string
      virtual_network_gateway_id = string
      express_route_circuit_id   = string
      authorization_key          = string
    }), null)

    auto_create_private_peering   = optional(bool, false)
    auto_create_microsoft_peering = optional(bool, false)
  }))
}
