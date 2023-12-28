
variable "megaport_access_key" {
  description = "megaport access key"
}

variable "megaport_secret_key" {
  description = "megaport secret key"
}

module "megaport" {
  source         = "../../modules/megaport"
  resource_group = azurerm_resource_group.rg.name
  prefix         = lower("salawu-${local.prefix}")
  location       = azurerm_resource_group.rg.location
  access_key     = var.megaport_access_key
  secret_key     = var.megaport_secret_key

  mcr = [
    {
      name          = "mcr"
      location      = "Interxion FRA6"
      port_speed    = 1000
      requested_asn = 64512
    }
  ]

  connection = [
    {
      mcr_name    = "mcr"
      vxc_name    = "branch2"
      rate_limit  = 50
      service_key = azurerm_express_route_circuit.branch2_er.service_key
    }
  ]
}
