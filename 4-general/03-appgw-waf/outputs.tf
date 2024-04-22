
####################################################
# output files
####################################################

# terraform output

output "values" {
  value = {
    hub1_appgw_pip       = azurerm_public_ip.hub1_appgw_pip.ip_address
    hub1_host_good_juice = "good-juice-${local.hub1_appgw_pip}.nip.io"
    hub1_host_bad_juice  = "bad-juice-${local.hub1_appgw_pip}.nip.io"
  }
}

# local file

####################################################
# output files
####################################################

locals {
  output_values = templatefile("../../scripts/outputs/values.md", {
    NODES = {
      hub1 = {
        appgw_pip       = azurerm_public_ip.hub1_appgw_pip.ip_address
        fqdn_good_juice = "good-juice-${local.hub1_appgw_pip}.nip.io"
        gqdn_bad_juice  = "bad-juice-${local.hub1_appgw_pip}.nip.io"
      }
    }
  })
}

resource "local_file" "output_files" {
  filename = "output/values.md"
  content  = local.output_values
}

