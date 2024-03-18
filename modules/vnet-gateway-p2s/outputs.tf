
locals {
  client_certificates_print = flatten([
    for client, data in module.client_certificates : [
      { client_name = client, file_ext = ".pem", file_name = "cert", data = data.cert_pem },
      #{ client_name = client, file_ext = ".pfx", file_name = "cert", data = data.cert_pfx },
      { client_name = client, file_ext = ".txt", file_name = "password", data = data.cert_pfx_password },
      { client_name = client, file_ext = ".pem", file_name = "key", data = data.private_key_pem }
    ]
  ])
}

output "gateway" {
  value = azurerm_virtual_network_gateway.this
}

output "public_ip" {
  value = {
    for v in var.ip_configuration : v.name => try(
      data.azurerm_public_ip.this[v.name].ip_address,
      azurerm_public_ip.this[v.name].ip_address
    )
  }
}

output "client_certificates" {
  value = module.client_certificates
}

output "client_certificates_cert_name" {
  value = { for client, data in module.client_certificates : client => data.cert_name }
}

output "client_certificates_private_key_pem" {
  value = { for client, data in module.client_certificates : client => data.private_key_pem }
}

output "client_certificates_cert_pem" {
  value = { for client, data in module.client_certificates : client => data.cert_pem }
}

output "client_certificates_cert_pfx" {
  value = { for client, data in module.client_certificates : client => data.cert_pfx }
}

output "client_certificates_cert_pfx_password" {
  value = { for client, data in module.client_certificates : client => data.cert_pfx_password }
}

resource "local_file" "certificate_files" {
  for_each = { for client in local.client_certificates_print :
    "${client.client_name}-${client.file_name}-${client.file_ext}" => client
  }
  content  = each.value.data
  filename = "output/p2s/${each.value.client_name}/${each.value.client_name}_${each.value.file_name}${each.value.file_ext}"
}
