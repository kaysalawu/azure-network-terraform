# Azure Application Gateway Terraform Module

Azure Application Gateway provides HTTP based load balancing that enables in creating routing rules for traffic based on HTTP. Traditional load balancers operate at the transport level and then route the traffic using source IP address and port to deliver data to a destination IP and port. Application Gateway using additional attributes such as URI (Uniform Resource Identifier) path and host headers to route the traffic.

Classic load balances operate at OSI layer 4 - TCP and UDP, while Application Gateway operates at application layer OSI layer 7 for load balancing.

This terraform module quickly creates a desired application gateway with additional options like WAF, Custom Error Configuration, SSL offloading with SSL policies, URL path mapping and many other options.

## Module Usage for

* [Application Gateway with SSL](application_gateway_with_ssl/)
* [Application Gateway with WAF](application_gateway_with_waf/)
* [A Simple HTTP Application Gateway](simple_http_application_gateway/)

## Terraform Usage

To run this example you need to execute following Terraform commands

```hcl
terraform init
terraform plan
terraform apply
```

Run `terraform destroy` when you don't need these resources.
