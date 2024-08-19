

<!-- BEGIN_TF_DOCS -->
## Requirements

No requirements.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_algorithm"></a> [algorithm](#input\_algorithm) | The algorithm to use for the self-signed certificate. | `string` | `"RSA"` | no |
| <a name="input_ca_cert_pem"></a> [ca\_cert\_pem](#input\_ca\_cert\_pem) | The certificate of the CA to sign the self-signed certificate. | `string` | n/a | yes |
| <a name="input_ca_private_key_pem"></a> [ca\_private\_key\_pem](#input\_ca\_private\_key\_pem) | The private key of the CA to sign the self-signed certificate. | `string` | n/a | yes |
| <a name="input_cert_password"></a> [cert\_password](#input\_cert\_password) | The password to use for the self-signed certificate. | `string` | `"Password123"` | no |
| <a name="input_dns_names"></a> [dns\_names](#input\_dns\_names) | The DNS names to include in the self-signed certificate. | `list(any)` | n/a | yes |
| <a name="input_name"></a> [name](#input\_name) | The name of the self-signed certificate. | `string` | n/a | yes |
| <a name="input_rsa_bits"></a> [rsa\_bits](#input\_rsa\_bits) | The number of bits to use for the self-signed certificate. | `number` | `4096` | no |
| <a name="input_subject"></a> [subject](#input\_subject) | The subject of the self-signed certificate. | `map(any)` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_cert_name"></a> [cert\_name](#output\_cert\_name) | n/a |
| <a name="output_cert_pem"></a> [cert\_pem](#output\_cert\_pem) | n/a |
| <a name="output_cert_pfx_password"></a> [cert\_pfx\_password](#output\_cert\_pfx\_password) | n/a |
| <a name="output_private_key_pem"></a> [private\_key\_pem](#output\_private\_key\_pem) | n/a |
<!-- END_TF_DOCS -->
