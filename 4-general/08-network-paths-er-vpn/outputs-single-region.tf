
####################################################
# output files
####################################################

locals {
  output_values = templatefile("../../scripts/outputs/values.md", {
    NODES = {
      hub1 = {
        VNET_NAME              = try(module.hub1.vnet.name, "")
        VNET_RANGES            = try(join(", ", module.hub1.vnet.address_space), "")
        VM_NAME                = try(module.hub1_vm.vm.name, "")
        VM_IP                  = try(module.hub1_vm.vm.private_ip_address, "")
        PRIVATE_DNS_INBOUND_IP = try(local.hub1_dns_in_addr, "")
        SUBNETS = { for k, v in module.hub1.subnets :
          k => try(v.address_prefixes[0], try(jsondecode(v.body).properties.addressPrefixes[0], ""))
        }
      }
      spoke1 = {
        VNET_NAME   = try(module.spoke1.vnet.name, "")
        VNET_RANGES = try(join(", ", module.spoke1.vnet.address_space), "")
        VM_NAME     = try(module.spoke1_vm.vm.name, "")
        VM_IP       = try(module.spoke1_vm.vm.private_ip_address, "")
        SUBNETS = { for k, v in module.spoke1.subnets :
          k => try(v.address_prefixes[0], try(jsondecode(v.body).properties.addressPrefixes[0], ""))
        }
      }
      branch2 = {
        VNET_NAME   = try(module.branch2.vnet.name, "")
        VNET_RANGES = try(join(", ", module.branch2.vnet.address_space), "")
        VM_NAME     = try(module.branch2_vm.vm.name, "")
        VM_IP       = try(module.branch2_vm.vm.private_ip_address, "")
        SUBNETS = { for k, v in module.branch2.subnets :
          k => try(v.address_prefixes[0], try(jsondecode(v.body).properties.addressPrefixes[0], ""))
        }
      }
    }
  })
}

resource "local_file" "output_files" {
  filename = "output/values.md"
  content  = local.output_values
}
