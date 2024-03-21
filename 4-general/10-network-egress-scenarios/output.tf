
####################################################
# output files
####################################################

locals {
  output_values = templatefile("../../scripts/outputs/values.md", {
    NODES = {
      ecs = {
        VNET_NAME   = try(module.ecs.vnet.name, "")
        VNET_RANGES = try(join(", ", module.ecs.vnet.address_space), "")
        SUBNETS     = try({ for k, v in module.ecs.subnets : k => v.address_prefixes[0] }, "")
      }
      # onprem = {
      #   VNET_NAME   = try(module.onprem.vnet.name, "")
      #   VNET_RANGES = try(join(", ", module.onprem.vnet.address_space), "")
      #   VM_NAME     = try(module.onprem_vm.vm.name, "")
      #   VM_IP       = try(module.onprem_vm.vm.private_ip_address, "")
      #   SUBNETS     = try({ for k, v in module.onprem.subnets : k => v.address_prefixes[0] }, "")
      # }
    }
  })
}

resource "local_file" "output_files" {
  filename = "output/values.md"
  content  = local.output_values
}
