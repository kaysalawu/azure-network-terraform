
####################################################
# output files
####################################################

locals {
  output_values = templatefile("../../scripts/outputs/values.md", {
    NODES = {
      hub = {
        VNET_NAME   = try(module.hub.vnet.name, "")
        VNET_RANGES = try(join(", ", module.hub.vnet.address_space), "")
        SUBNETS = { for k, v in module.hub.subnets :
          k => try(v.address_prefixes[0],
          try(jsondecode(v.body).properties.addressPrefixes[0], ""))
      } }
    }
  })
}

resource "local_file" "output_files" {
  filename = "output/values.md"
  content  = local.output_values
}
