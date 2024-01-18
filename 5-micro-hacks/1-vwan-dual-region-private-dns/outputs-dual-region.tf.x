
####################################################
# output files
####################################################

locals {
  output_values = templatefile("../../scripts/outputs/values.md", {
    NODES = {
      shared1 = {
        VNET_NAME                   = try(module.shared1.vnet.name, "")
        VNET_RANGES                 = try(join(", ", module.shared1.vnet.address_space), "")
        VM_NAME                     = try(module.shared1_vm.vm.name, "")
        VM_IP                       = try(module.shared1_vm.vm.private_ip_address, "")
        PRIVATE_DNS_INBOUND_IP      = try(local.shared1_dns_in_addr, "")
        SPOKE3_WEB_APP_ENDPOINT_IP  = try(azurerm_private_endpoint.shared1_spoke3_pls_pep.private_service_connection[0].private_ip_address, "")
        SPOKE3_WEB_APP_ENDPOINT_DNS = "${local.shared1_spoke3_pep_host}.shared1.${local.cloud_domain}"
        SPOKE3_APP_SVC_ENDPOINT_IP  = try(azurerm_private_endpoint.shared1_spoke3_apps_pep.private_service_connection[0].private_ip_address, "")
        SPOKE3_APP_SVC_ENDPOINT_DNS = try(module.spoke3_apps.url, "")
        SUBNETS                     = try({ for k, v in module.shared1.subnets : k => v.address_prefixes[0] }, "")
      }
      shared2 = {
        VNET_NAME                   = try(module.shared2.vnet.name, "")
        VNET_RANGES                 = try(join(", ", module.shared2.vnet.address_space), "")
        VM_NAME                     = try(module.shared2_vm.vm.name, "")
        VM_IP                       = try(module.shared2_vm.vm.private_ip_address, "")
        PRIVATE_DNS_INBOUND_IP      = try(local.shared2_dns_in_addr, "")
        SPOKE6_WEB_APP_ENDPOINT_IP  = try(azurerm_private_endpoint.shared2_spoke6_pls_pep.private_service_connection[0].private_ip_address, "")
        SPOKE6_WEB_APP_ENDPOINT_DNS = "${local.shared2_spoke6_pep_host}.shared2.${local.cloud_domain}"
        SPOKE6_APP_SVC_ENDPOINT_IP  = try(azurerm_private_endpoint.shared2_spoke6_apps_pep.private_service_connection[0].private_ip_address, "")
        SPOKE6_APP_SVC_ENDPOINT_DNS = try(module.spoke6_apps.url, "")
        SUBNETS                     = try({ for k, v in module.shared2.subnets : k => v.address_prefixes[0] }, "")
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
      spoke4 = {
        VNET_NAME   = try(module.spoke4.vnet.name, "")
        VNET_RANGES = try(join(", ", module.spoke4.vnet.address_space), "")
        VM_NAME     = try(module.spoke4_vm.vm.name, "")
        VM_IP       = try(module.spoke4_vm.vm.private_ip_address, "")
        SUBNETS     = try({ for k, v in module.spoke4.subnets : k => v.address_prefixes[0] }, "")
      }
      spoke4 = {
        VNET_NAME   = try(module.spoke4.vnet.name, "")
        VNET_RANGES = try(join(", ", module.spoke4.vnet.address_space), "")
        VM_NAME     = try(module.spoke4_vm.vm.name, "")
        VM_IP       = try(module.spoke4_vm.vm.private_ip_address, "")
        SUBNETS     = try({ for k, v in module.spoke4.subnets : k => v.address_prefixes[0] }, "")
      }
      spoke6 = {
        VNET_NAME   = try(module.spoke6.vnet.name, "")
        VNET_RANGES = try(join(", ", module.spoke6.vnet.address_space), "")
        VM_NAME     = try(module.spoke6_vm.vm.name, "")
        VM_IP       = try(module.spoke6_vm.vm.private_ip_address, "")
        SUBNETS     = try({ for k, v in module.spoke6.subnets : k => v.address_prefixes[0] }, "")
      }
      branch1 = {
        VNET_NAME   = try(module.branch1.vnet.name, "")
        VNET_RANGES = try(join(", ", module.branch1.vnet.address_space), "")
        VM_NAME     = try(module.branch1_vm.vm.name, "")
        VM_IP       = try(module.branch1_vm.vm.private_ip_address, "")
        SUBNETS     = try({ for k, v in module.branch1.subnets : k => v.address_prefixes[0] }, "")
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
