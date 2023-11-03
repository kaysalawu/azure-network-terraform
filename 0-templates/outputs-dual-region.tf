
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
        DNS_IN_IP                   = try(local.hub1_dns_in_addr, "")
        SPOKE3_WEB_APP_ENDPOINT_IP  = try(azurerm_private_endpoint.hub1_spoke3_pls_pep.private_service_connection[0].private_ip_address, "")
        SPOKE3_WEB_APP_ENDPOINT_DNS = "${local.hub1_spoke3_pep_host}.hub1.${local.cloud_domain}"
        SPOKE3_APP_SVC_ENDPOINT_IP  = try(azurerm_private_endpoint.hub1_spoke3_apps_pep.private_service_connection[0].private_ip_address, "")
        SPOKE3_APP_SVC_ENDPOINT_DNS = try(module.spoke3_apps.url, "")
        SUBNETS                     = try({ for k, v in module.hub1.subnets : k => v.address_prefixes[0] }, "")
      }
      hub2 = {
        VNET_NAME                   = try(module.hub2.vnet.name, "")
        VNET_RANGES                 = try(join(", ", module.hub2.vnet.address_space), "")
        VM_NAME                     = try(module.hub2_vm.vm.name, "")
        VM_IP                       = try(module.hub2_vm.vm.private_ip_address, "")
        DNS_IN_IP                   = try(local.hub2_dns_in_addr, "")
        SPOKE6_WEB_APP_ENDPOINT_IP  = try(azurerm_private_endpoint.hub2_spoke6_pls_pep.private_service_connection[0].private_ip_address, "")
        SPOKE6_WEB_APP_ENDPOINT_DNS = "${local.hub2_spoke6_pep_host}.hub2.${local.cloud_domain}"
        SPOKE6_APP_SVC_ENDPOINT_IP  = try(azurerm_private_endpoint.hub2_spoke6_apps_pep.private_service_connection[0].private_ip_address, "")
        SPOKE6_APP_SVC_ENDPOINT_DNS = try(module.spoke6_apps.url, "")
        SUBNETS                     = try({ for k, v in module.hub2.subnets : k => v.address_prefixes[0] }, "")
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
      spoke5 = {
        VNET_NAME   = try(module.spoke5.vnet.name, "")
        VNET_RANGES = try(join(", ", module.spoke5.vnet.address_space), "")
        VM_NAME     = try(module.spoke5_vm.vm.name, "")
        VM_IP       = try(module.spoke5_vm.vm.private_ip_address, "")
        SUBNETS     = try({ for k, v in module.spoke5.subnets : k => v.address_prefixes[0] }, "")
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
      branch3 = {
        VNET_NAME   = try(module.branch3.vnet.name, "")
        VNET_RANGES = try(join(", ", module.branch3.vnet.address_space), "")
        VM_NAME     = try(module.branch3_vm.vm.name, "")
        VM_IP       = try(module.branch3_vm.vm.private_ip_address, "")
        SUBNETS     = try({ for k, v in module.branch3.subnets : k => v.address_prefixes[0] }, "")
      }
    }
  })
}

resource "local_file" "output_files" {
  filename = "output/values.md"
  content  = local.output_values
}
