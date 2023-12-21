
output "cert_name" {
  value = var.name
}

output "private_key_pem" {
  value = tls_private_key.this.private_key_pem
}

output "cert_pem" {
  value = tls_locally_signed_cert.this.cert_pem
}

output "cert_pfx" {
  value = pkcs12_from_pem.this.result
}

# output "cert_pfx_path" {
#   value = "${var.cert_output_path}/${var.name}.p12"
# }

output "password" {
  value = var.password
}
