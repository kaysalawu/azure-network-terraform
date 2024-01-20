
variable "name" {
  description = "The name of the self-signed certificate."
  type        = string
}

variable "subject" {
  description = "The subject of the self-signed certificate."
  type        = map(any)
}

variable "dns_names" {
  description = "The DNS names to include in the self-signed certificate."
  type        = list(any)
}

variable "ca_private_key_pem" {
  description = "The private key of the CA to sign the self-signed certificate."
  type        = string
}

variable "ca_cert_pem" {
  description = "The certificate of the CA to sign the self-signed certificate."
  type        = string
}

variable "algorithm" {
  description = "The algorithm to use for the self-signed certificate."
  type        = string
  default     = "RSA"
}

variable "rsa_bits" {
  description = "The number of bits to use for the self-signed certificate."
  type        = number
  default     = 4096
}

variable "cert_password" {
  description = "The password to use for the self-signed certificate."
  type        = string
  default     = "Password123"
}
