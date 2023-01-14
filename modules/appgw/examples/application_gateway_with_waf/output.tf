output "application_gateway_id" {
  description = "The ID of the Application Gateway"
  value       = module.application-gateway.application_gateway_id
}

output "authentication_certificate_id" {
  description = " The ID of the Authentication Certificate"
  value       = module.application-gateway.authentication_certificate_id
}

output "backend_address_pool_id" {
  description = "The ID of the Backend Address Pool"
  value       = module.application-gateway.backend_address_pool_id
}

output "backend_http_settings_id" {
  description = "The ID of the Backend HTTP Settings Configuration"
  value       = module.application-gateway.backend_http_settings_id
}

output "backend_http_settings_probe_id" {
  description = "The ID of the Backend HTTP Settings Configuration associated Probe"
  value       = module.application-gateway.backend_http_settings_probe_id
}

output "frontend_ip_configuration_id" {
  description = "The ID of the Frontend IP Configuration"
  value       = module.application-gateway.frontend_ip_configuration_id
}

output "frontend_port_id" {
  description = "The ID of the Frontend Port"
  value       = module.application-gateway.frontend_port_id
}

output "gateway_ip_configuration_id" {
  description = "The ID of the Gateway IP Configuration"
  value       = module.application-gateway.gateway_ip_configuration_id
}

output "http_listener_id" {
  description = "The ID of the HTTP Listener"
  value       = module.application-gateway.http_listener_id
}

output "http_listener_frontend_ip_configuration_id" {
  description = "The ID of the associated Frontend Configuration"
  value       = module.application-gateway.http_listener_frontend_ip_configuration_id
}

output "http_listener_frontend_port_id" {
  description = "The ID of the associated Frontend Port"
  value       = module.application-gateway.http_listener_frontend_port_id
}

output "http_listener_ssl_certificate_id" {
  description = "The ID of the associated SSL Certificate"
  value       = module.application-gateway.http_listener_ssl_certificate_id
}

output "probe_id" {
  description = "The ID of the health Probe"
  value       = module.application-gateway.probe_id
}

output "request_routing_rule_id" {
  description = "The ID of the Request Routing Rule"
  value       = module.application-gateway.request_routing_rule_id
}

output "request_routing_rule_http_listener_id" {
  description = "The ID of the Request Routing Rule associated HTTP Listener"
  value       = module.application-gateway.request_routing_rule_http_listener_id
}

output "request_routing_rule_backend_address_pool_id" {
  description = "The ID of the Request Routing Rule associated Backend Address Pool"
  value       = module.application-gateway.request_routing_rule_backend_address_pool_id
}

output "request_routing_rule_backend_http_settings_id" {
  description = "The ID of the Request Routing Rule associated Backend HTTP Settings Configuration"
  value       = module.application-gateway.request_routing_rule_backend_http_settings_id
}

output "request_routing_rule_redirect_configuration_id" {
  description = "The ID of the Request Routing Rule associated Redirect Configuration"
  value       = module.application-gateway.request_routing_rule_redirect_configuration_id
}

output "request_routing_rule_rewrite_rule_set_id" {
  description = "The ID of the Request Routing Rule associated Rewrite Rule Set"
  value       = module.application-gateway.request_routing_rule_rewrite_rule_set_id
}

output "request_routing_rule_url_path_map_id" {
  description = "The ID of the Request Routing Rule associated URL Path Map"
  value       = module.application-gateway.request_routing_rule_url_path_map_id
}

output "ssl_certificate_id" {
  description = "The ID of the SSL Certificate"
  value       = module.application-gateway.ssl_certificate_id
}

output "ssl_certificate_public_cert_data" {
  description = "The Public Certificate Data associated with the SSL Certificate"
  value       = module.application-gateway.ssl_certificate_public_cert_data
}

output "url_path_map_id" {
  description = "The ID of the URL Path Map"
  value       = module.application-gateway.url_path_map_id
}

output "url_path_map_default_backend_address_pool_id" {
  description = "The ID of the Default Backend Address Pool associated with URL Path Map"
  value       = module.application-gateway.url_path_map_default_backend_address_pool_id
}

output "url_path_map_default_backend_http_settings_id" {
  description = "The ID of the Default Backend HTTP Settings Collection associated with URL Path Map"
  value       = module.application-gateway.url_path_map_default_backend_http_settings_id
}

output "url_path_map_default_redirect_configuration_id" {
  description = "The ID of the Default Redirect Configuration associated with URL Path Map"
  value       = module.application-gateway.url_path_map_default_redirect_configuration_id
}

output "custom_error_configuration_id" {
  description = "The ID of the Custom Error Configuration"
  value       = module.application-gateway.custom_error_configuration_id
}

output "redirect_configuration_id" {
  description = "The ID of the Redirect Configuration"
  value       = module.application-gateway.redirect_configuration_id
}

output "rewrite_rule_set_id" {
  description = "The ID of the Rewrite Rule Set"
  value       = module.application-gateway.rewrite_rule_set_id
}
