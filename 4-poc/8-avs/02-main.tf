
# vm startup scripts
#----------------------------

locals {
  prefix = "avs"

  hub_nva_asn   = "65000"
  hub_vpngw_asn = "65515"
  hub_ergw_asn  = "65515"
  hub_ars_asn   = "65515"

  #mypip         = chomp(data.http.mypip.response_body)

  vm_script_targets_region1 = [
    #{ name = "avs", dns = local.avs_vm_dns, ip = local.avs_vm_addr },
    { name = "hub   ", dns = local.hub_vm_dns, ip = local.hub_vm_addr },
    { name = "core1 ", dns = local.core1_vm_dns, ip = local.core1_vm_addr },
    { name = "core2 ", dns = local.core2_vm_dns, ip = local.core2_vm_addr },
    { name = "yellow ", dns = local.yellow_vm_dns, ip = local.yellow_vm_addr, ping = false },
  ]
  vm_startup = templatefile("../../scripts/server.sh", {
    TARGETS = concat(local.vm_script_targets_region1)
  })
  onprem_unbound_config = templatefile("../../scripts/unbound.sh", {
    ONPREM_LOCAL_RECORDS = local.onprem_local_records
    REDIRECTED_HOSTS     = local.onprem_redirected_hosts
    FORWARD_ZONES        = local.onprem_forward_zones
    TARGETS              = local.vm_script_targets_region1
  })
  onprem_unbound_vars = {
    ONPREM_LOCAL_RECORDS = local.onprem_local_records
    REDIRECTED_HOSTS     = local.onprem_redirected_hosts
    FORWARD_ZONES        = local.onprem_forward_zones
    TARGETS              = local.vm_script_targets_region1
  }
  onprem_local_records = [
    { name = (local.avs_vm_dns), record = local.avs_vm_addr },
    { name = (local.onprem_vm_dns), record = local.onprem_vm_addr },
  ]
  onprem_forward_zones = [
    { zone = "${local.cloud_domain}.", targets = [local.hub_dns_in_addr, ] },
    { zone = ".", targets = [local.azuredns, ] },
  ]
  onprem_redirected_hosts = []
}

####################################################
# addresses
####################################################

resource "azurerm_public_ip" "avs_nva_pip" {
  resource_group_name = azurerm_resource_group.rg.name
  name                = "${local.avs_prefix}nva-pip"
  location            = local.avs_location
  sku                 = "Standard"
  allocation_method   = "Static"
}
