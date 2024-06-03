
####################################################
# output files
####################################################

locals {
  output_values = templatefile("../../scripts/outputs/values.md", {
    NODES = {
      hub1 = {
        VNET_NAME                        = try(module.hub1.vnet.name, "")
        VNET_RANGES                      = try(join(", ", module.hub1.vnet.address_space), "")
        VM_NAME                          = try(module.hub1_vm.vm.name, "")
        VM_IP                            = try(module.hub1_vm.vm.private_ip_address, "")
        PRIVATE_DNS_INBOUND_IP           = try(local.hub1_dns_in_addr, "")
        PRIVATELINK_SERVICE_ENDPOINT_IP  = local.hub1_spoke3_pls_pep_ip
        PRIVATELINK_SERVICE_ENDPOINT_DNS = "${local.hub1_spoke3_pep_host}.hub1.${local.cloud_domain}"
        "SPOKE3_BLOB_URL (Sample)"       = "https://${local.spoke3_storage_account_name}.blob.core.windows.net/spoke3/spoke3.txt"
        PRIVATELINK_BLOB_ENDPOINT_IP     = local.hub1_spoke3_blob_pep_ip
        PRIVATELINK_BLOB_ENDPOINT_DNS    = "${local.hub1_spoke3_pep_host}.hub1.${local.cloud_domain}"
        SUBNETS = { for k, v in module.hub1.subnets :
          k => try(v.address_prefixes[0], try(jsondecode(v.body).properties.addressPrefixes[0], ""))
        }
      }
      hub2 = {
        VNET_NAME                        = try(module.hub2.vnet.name, "")
        VNET_RANGES                      = try(join(", ", module.hub2.vnet.address_space), "")
        VM_NAME                          = try(module.hub2_vm.vm.name, "")
        VM_IP                            = try(module.hub2_vm.vm.private_ip_address, "")
        PRIVATE_DNS_INBOUND_IP           = try(local.hub2_dns_in_addr, "")
        PRIVATELINK_SERVICE_ENDPOINT_IP  = local.hub2_spoke6_pls_pep_ip
        PRIVATELINK_SERVICE_ENDPOINT_DNS = "${local.hub2_spoke6_pep_host}.hub2.${local.cloud_domain}"
        "SPOKE6_BLOB_URL (Sample)"       = "https://${local.spoke6_storage_account_name}.blob.core.windows.net/spoke6/spoke6.txt"
        PRIVATELINK_BLOB_ENDPOINT_IP     = local.hub2_spoke6_blob_pep_ip
        PRIVATELINK_BLOB_ENDPOINT_DNS    = "${local.hub2_spoke6_pep_host}.hub2.${local.cloud_domain}"
        SUBNETS = { for k, v in module.hub2.subnets :
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
