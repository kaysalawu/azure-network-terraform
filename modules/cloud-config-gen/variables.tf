
variable "packages" {
  description = "List of packages"
  type        = list(string)
  default     = []
}

variable "boot_commands" {
  description = "List of cloud-init `bootcmd`s"
  type        = list(string)
  default     = []
}

variable "cloud_config" {
  description = "Cloud config template path. If provided, takes precedence over all other arguments."
  type        = string
  default     = null
}

variable "config_variables" {
  description = "Additional variables used to render the template passed via `cloud_config`"
  type        = map(any)
  default     = {}
}

variable "container_args" {
  description = "Arguments for container"
  type        = string
  default     = ""
}

variable "container_image" {
  description = "Container image."
  type        = string
  default     = null
}

variable "container_name" {
  description = "Name of the container to be run"
  type        = string
  default     = "container"
}

variable "container_volumes" {
  description = "List of volumes"
  type = list(object({
    host      = string,
    container = string
  }))
  default = []
}

variable "docker_args" {
  description = "Extra arguments to be passed for docker"
  type        = string
  default     = null
}

variable "file_defaults" {
  description = "Default owner and permissions for files."
  type = object({
    owner       = string
    permissions = string
  })
  default = {
    owner       = "root"
    permissions = "0644"
  }
}

variable "files" {
  description = "Map of extra files to create on the instance, path as key. Owner and permissions will use defaults if null."
  type = map(object({
    content     = string
    owner       = string
    permissions = string
  }))
  default = {}
}

variable "run_commands" {
  description = "List of cloud-init `runcmd`s"
  type        = list(string)
  default     = []
}

variable "users" {
  description = "List of usernames to be created. If provided, first user will be used to run the container."
  type = list(object({
    username = string,
    uid      = number,
  }))
  default = [
  ]
}
