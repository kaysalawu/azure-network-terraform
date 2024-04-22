
####################################################
# private key
####################################################

resource "tls_private_key" "this" {
  algorithm = var.algorithm
  rsa_bits  = var.rsa_bits
}

####################################################
# cert
####################################################

resource "tls_cert_request" "this" {
  private_key_pem = tls_private_key.this.private_key_pem
  subject {
    common_name         = var.subject["common_name"]
    organization        = var.subject["organization"]
    organizational_unit = var.subject["organizational_unit"]
    street_address      = split(",", var.subject["street_address"])
    locality            = var.subject["locality"]
    province            = var.subject["province"]
    country             = var.subject["country"]
  }
  dns_names = var.dns_names
}

####################################################
# signed cert (pem)
####################################################

resource "tls_locally_signed_cert" "this" {
  cert_request_pem      = tls_cert_request.this.cert_request_pem
  ca_private_key_pem    = var.ca_private_key_pem
  ca_cert_pem           = var.ca_cert_pem
  validity_period_hours = 8760
  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "server_auth",
    "client_auth",
  ]
}
