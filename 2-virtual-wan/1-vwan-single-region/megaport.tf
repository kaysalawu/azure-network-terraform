
variable "megaport_access_key" {
  description = "megaport access key"
}

variable "megaport_secret_key" {
  description = "megaport secret key"
}

# data "http" "megaport_locations" {
#   url = "https://api.megaport.com/v2/locations"
# }

module "megaport" {
  source         = "../../modules/megaport"
  resource_group = azurerm_resource_group.rg.name
  prefix         = lower("salawu-${local.prefix}")
  location       = local.region1
  access_key     = var.megaport_access_key
  secret_key     = var.megaport_secret_key

  mcr = [
    # {
    #   name          = "mcr"
    #   location      = "Interxion FRA6"
    #   port_speed    = 1000
    #   requested_asn = 64512
    # }
  ]

  connection = [
    # {
    #   mcr_name     = "mcr"
    #   vxc_name     = "branch2"
    #   rate_limit   = 50
    #   service_key  = azurerm_express_route_circuit.branch2_er.service_key
    #   circuit_name = azurerm_express_route_circuit.branch2_er.name

    #   private_peering = {
    #     peer_asn         = 65515
    #     requested_vlan   = 200
    #     primary_subnet   = local.csp_range1
    #     secondary_subnet = local.csp_range2
    #   }

    #   gateway_connection = {
    #     name                       = "branch2"
    #     virtual_network_gateway_id = module.branch2.ergw.id
    #     express_route_circuit_id   = azurerm_express_route_circuit.branch2_er.id
    #     authorization_key          = azurerm_express_route_circuit_authorization.branch2_er.authorization_key
    #   }

    #   # microsoft_peering = {
    #   #   peer_asn         = 12076
    #   #   requested_vlan   = 201
    #   #   primary_subnet   = local.csp_range3
    #   #   secondary_subnet = local.csp_range4
    #   # }
    # }
  ]
}

# output "test" {
#   value = tolist(module.megaport.test["mcr"].router)[0].assigned_asn
# }

####################################################
# output files
####################################################

locals {
  megaport_files = {
    "megaport-locations.json" = jsonencode(data.http.megaport_locations.body)
  }
}

resource "local_file" "megaport_files" {
  for_each = local.megaport_files
  filename = each.key
  content  = each.value
}
