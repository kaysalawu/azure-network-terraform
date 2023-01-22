
output "cloud_config" {
  description = "Rendered cloud-config file to be passed as user-data instance metadata."
  value       = local.cloud_config
}
