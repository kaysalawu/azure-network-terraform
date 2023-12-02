
variable "resource_group" {
  description = "resource group name"
  type        = any
}

variable "prefix" {
  description = "prefix to append before all resources"
  type        = string
}

variable "name" {
  description = "virtual machine name"
  type        = string
}

variable "location" {
  description = "vnet region location"
  type        = string
}

variable "tags" {
  description = "tags for all hub resources"
  type        = map(any)
  default     = null
}

variable "docker_image_name" {
  description = "docker image to run"
  type        = string
  default     = "kennethreitz/httpbin:latest"
}

variable "docker_registry_url" {
  description = "docker registry url"
  type        = string
  default     = "https://index.docker.io"
}

variable "subnet_id" {
  description = "subnet id to deploy app service"
  type        = string
  default     = null
}
