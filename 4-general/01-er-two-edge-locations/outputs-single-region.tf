
####################################################
# output files
####################################################

locals {
  output_values = templatefile("../../scripts/outputs/values.md", {
    NODES = {
      hub1 = {
        VNET_NAME                   = try(module.hub1.vnet.name, "")
        VNET_RANGES                 = try(join(", ", module.hub1.vnet.address_space), "")
        VM_NAME                     = try(module.hub1_vm.vm.name, "")
        VM_IP                       = try(module.hub1_vm.vm.private_ip_address, "")
        PRIVATE_DNS_INBOUND_IP      = try(local.hub1_dns_in_addr, "")
        SPOKE3_WEB_APP_ENDPOINT_IP  = try(azurerm_private_endpoint.hub1_spoke3_pls_pep.private_service_connection[0].private_ip_address, "")
        SPOKE3_WEB_APP_ENDPOINT_DNS = "${local.hub1_spoke3_pep_host}.hub1.${local.cloud_domain}"
        SPOKE3_APP_SVC_ENDPOINT_IP  = try(azurerm_private_endpoint.hub1_spoke3_apps_pep.private_service_connection[0].private_ip_address, "")
        SPOKE3_APP_SVC_ENDPOINT_DNS = try(module.spoke3_apps.url, "")
        SUBNETS                     = try({ for k, v in module.hub1.subnets : k => v.address_prefixes[0] }, "")
      }
      spoke1 = {
        VNET_NAME   = try(module.spoke1.vnet.name, "")
        VNET_RANGES = try(join(", ", module.spoke1.vnet.address_space), "")
        VM_NAME     = try(module.spoke1_vm.vm.name, "")
        VM_IP       = try(module.spoke1_vm.vm.private_ip_address, "")
        SUBNETS     = try({ for k, v in module.spoke1.subnets : k => v.address_prefixes[0] }, "")
      }
      spoke2 = {
        VNET_NAME   = try(module.spoke2.vnet.name, "")
        VNET_RANGES = try(join(", ", module.spoke2.vnet.address_space), "")
        VM_NAME     = try(module.spoke2_vm.vm.name, "")
        VM_IP       = try(module.spoke2_vm.vm.private_ip_address, "")
        SUBNETS     = try({ for k, v in module.spoke2.subnets : k => v.address_prefixes[0] }, "")
      }
      spoke3 = {
        VNET_NAME   = try(module.spoke3.vnet.name, "")
        VNET_RANGES = try(join(", ", module.spoke3.vnet.address_space), "")
        VM_NAME     = try(module.spoke3_vm.vm.name, "")
        VM_IP       = try(module.spoke3_vm.vm.private_ip_address, "")
        APPS_URL    = try(module.spoke3_apps.url, "")
        SUBNETS     = try({ for k, v in module.spoke3.subnets : k => v.address_prefixes[0] }, "")
      }
      branch2 = {
        VNET_NAME   = try(module.branch2.vnet.name, "")
        VNET_RANGES = try(join(", ", module.branch2.vnet.address_space), "")
        VM_NAME     = try(module.branch2_vm.vm.name, "")
        VM_IP       = try(module.branch2_vm.vm.private_ip_address, "")
        SUBNETS     = try({ for k, v in module.branch2.subnets : k => v.address_prefixes[0] }, "")
      }
    }
  })
}

resource "local_file" "output_files" {
  filename = "output/values.md"
  content  = local.output_values
}
