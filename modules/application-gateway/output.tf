output "application_gateway_id" {
  description = "The ID of the Application Gateway"
  value       = azurerm_application_gateway.main.id
}

output "authentication_certificate_id" {
  description = "The ID of the Authentication Certificate"
  value       = [for k in azurerm_application_gateway.main.authentication_certificate : k.id] #azurerm_application_gateway.main.authentication_certificate.*.id
}

output "backend_address_pool_id" {
  description = "The ID of the Backend Address Pool"
  value       = azurerm_application_gateway.main.backend_address_pool.*.id
}

output "backend_http_settings_id" {
  description = "The ID of the Backend HTTP Settings Configuration"
  value       = azurerm_application_gateway.main.backend_http_settings.*.id
}

output "backend_http_settings_probe_id" {
  description = "The ID of the Backend HTTP Settings Configuration associated Probe"
  value       = azurerm_application_gateway.main.backend_http_settings.*.probe_id
}

output "frontend_ip_configuration_id" {
  description = "The ID of the Frontend IP Configuration"
  value       = azurerm_application_gateway.main.frontend_ip_configuration.*.id
}

output "frontend_port_id" {
  description = "The ID of the Frontend Port"
  value       = azurerm_application_gateway.main.frontend_port.*.id
}

output "gateway_ip_configuration_id" {
  description = "The ID of the Gateway IP Configuration"
  value       = azurerm_application_gateway.main.gateway_ip_configuration.*.id
}

output "http_listener_id" {
  description = "The ID of the HTTP Listener"
  value       = azurerm_application_gateway.main.http_listener.*.id
}

output "http_listener_frontend_ip_configuration_id" {
  description = "The ID of the associated Frontend Configuration"
  value       = azurerm_application_gateway.main.http_listener.*.frontend_ip_configuration_id
}

output "http_listener_frontend_port_id" {
  description = "The ID of the associated Frontend Port"
  value       = azurerm_application_gateway.main.http_listener.*.frontend_port_id
}

output "http_listener_ssl_certificate_id" {
  description = "The ID of the associated SSL Certificate"
  value       = azurerm_application_gateway.main.http_listener.*.ssl_certificate_id
}

output "probe_id" {
  description = "The ID of the health Probe"
  value       = azurerm_application_gateway.main.probe.*.id
}

output "request_routing_rule_id" {
  description = "The ID of the Request Routing Rule"
  value       = azurerm_application_gateway.main.request_routing_rule.*.id
}

output "request_routing_rule_http_listener_id" {
  description = "The ID of the Request Routing Rule associated HTTP Listener"
  value       = azurerm_application_gateway.main.request_routing_rule.*.http_listener_id
}

output "request_routing_rule_backend_address_pool_id" {
  description = "The ID of the Request Routing Rule associated Backend Address Pool"
  value       = azurerm_application_gateway.main.request_routing_rule.*.backend_address_pool_id
}

output "request_routing_rule_backend_http_settings_id" {
  description = "The ID of the Request Routing Rule associated Backend HTTP Settings Configuration"
  value       = azurerm_application_gateway.main.request_routing_rule.*.backend_http_settings_id
}

output "request_routing_rule_redirect_configuration_id" {
  description = "The ID of the Request Routing Rule associated Redirect Configuration"
  value       = azurerm_application_gateway.main.request_routing_rule.*.redirect_configuration_id
}

output "request_routing_rule_rewrite_rule_set_id" {
  description = "The ID of the Request Routing Rule associated Rewrite Rule Set"
  value       = azurerm_application_gateway.main.request_routing_rule.*.rewrite_rule_set_id
}

output "request_routing_rule_url_path_map_id" {
  description = "The ID of the Request Routing Rule associated URL Path Map"
  value       = azurerm_application_gateway.main.request_routing_rule.*.url_path_map_id
}

output "ssl_certificate_id" {
  description = "The ID of the SSL Certificate"
  value       = azurerm_application_gateway.main.ssl_certificate.*.id
}

output "ssl_certificate_public_cert_data" {
  description = "The Public Certificate Data associated with the SSL Certificate"
  value       = azurerm_application_gateway.main.ssl_certificate.*.public_cert_data
}

output "url_path_map_id" {
  description = "The ID of the URL Path Map"
  value       = [for k in azurerm_application_gateway.main.url_path_map : k.id]
}

output "url_path_map_default_backend_address_pool_id" {
  description = "The ID of the Default Backend Address Pool associated with URL Path Map"
  value       = [for k in azurerm_application_gateway.main.url_path_map : k.default_backend_address_pool_id]
}

output "url_path_map_default_backend_http_settings_id" {
  description = "The ID of the Default Backend HTTP Settings Collection associated with URL Path Map"
  value       = [for k in azurerm_application_gateway.main.url_path_map : k.default_backend_http_settings_id]
}

output "url_path_map_default_redirect_configuration_id" {
  description = "The ID of the Default Redirect Configuration associated with URL Path Map"
  value       = [for k in azurerm_application_gateway.main.url_path_map : k.default_redirect_configuration_id]
}

output "custom_error_configuration_id" {
  description = "The ID of the Custom Error Configuration"
  value       = azurerm_application_gateway.main.custom_error_configuration.*.id
}

output "redirect_configuration_id" {
  description = "The ID of the Redirect Configuration"
  value       = azurerm_application_gateway.main.custom_error_configuration.*.id
}

output "rewrite_rule_set_id" {
  description = "The ID of the Rewrite Rule Set"
  value       = azurerm_application_gateway.main.rewrite_rule_set.*.id
}
