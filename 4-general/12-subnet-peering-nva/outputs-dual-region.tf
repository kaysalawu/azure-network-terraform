
####################################################
# output files
####################################################

locals {
  output_values = templatefile("../../scripts/outputs/values.md", {
    NODES = {
      hub1 = {
        VNET_NAME   = try(module.hub1.vnet.name, "")
        VNET_RANGES = try(join(", ", module.hub1.vnet.address_space), "")
        # VM_NAME                = try(module.hub1_vm.vm.name, "")
        # VM_IP                  = try(module.hub1_vm.vm.private_ip_address, "")
        # PRIVATE_DNS_INBOUND_IP = try(local.hub1_dns_in_addr, "")
        SUBNETS = { for k, v in module.hub1.subnets :
          k => try(v.address_prefixes[0], try(jsondecode(v.body).properties.addressPrefixes[0], ""))
        }
      }
      hub2 = {
        VNET_NAME   = try(module.hub2.vnet.name, "")
        VNET_RANGES = try(join(", ", module.hub2.vnet.address_space), "")
        # VM_NAME                = try(module.hub2_vm.vm.name, "")
        # VM_IP                  = try(module.hub2_vm.vm.private_ip_address, "")
        # PRIVATE_DNS_INBOUND_IP = try(local.hub2_dns_in_addr, "")
        SUBNETS = { for k, v in module.hub2.subnets :
          k => try(v.address_prefixes[0], try(jsondecode(v.body).properties.addressPrefixes[0], ""))
        }
      }
      spoke4 = {
        VNET_NAME   = try(module.spoke4.vnet.name, "")
        VNET_RANGES = try(join(", ", module.spoke4.vnet.address_space), "")
        # VM_NAME     = try(module.spoke4_vm.vm.name, "")
        VM_IP = try(module.spoke4_vm.vm.private_ip_address, "")
        SUBNETS = { for k, v in module.spoke4.subnets :
          k => try(v.address_prefixes[0], try(jsondecode(v.body).properties.addressPrefixes[0], ""))
        }
      }
      branch1 = {
        VNET_NAME   = try(module.branch1.vnet.name, "")
        VNET_RANGES = try(join(", ", module.branch1.vnet.address_space), "")
        VM_NAME     = try(module.branch1_vm.vm.name, "")
        VM_IP       = try(module.branch1_vm.vm.private_ip_address, "")
        SUBNETS = { for k, v in module.branch1.subnets :
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
