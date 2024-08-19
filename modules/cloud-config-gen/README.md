

<!-- BEGIN_TF_DOCS -->
## Requirements

No requirements.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_boot_commands"></a> [boot\_commands](#input\_boot\_commands) | List of cloud-init `bootcmd`s | `list(string)` | `[]` | no |
| <a name="input_cloud_config"></a> [cloud\_config](#input\_cloud\_config) | Cloud config template path. If provided, takes precedence over all other arguments. | `string` | `null` | no |
| <a name="input_config_variables"></a> [config\_variables](#input\_config\_variables) | Additional variables used to render the template passed via `cloud_config` | `map(any)` | `{}` | no |
| <a name="input_container_args"></a> [container\_args](#input\_container\_args) | Arguments for container | `string` | `""` | no |
| <a name="input_container_image"></a> [container\_image](#input\_container\_image) | Container image. | `string` | `null` | no |
| <a name="input_container_name"></a> [container\_name](#input\_container\_name) | Name of the container to be run | `string` | `"container"` | no |
| <a name="input_container_volumes"></a> [container\_volumes](#input\_container\_volumes) | List of volumes | <pre>list(object({<br>    host      = string,<br>    container = string<br>  }))</pre> | `[]` | no |
| <a name="input_docker_args"></a> [docker\_args](#input\_docker\_args) | Extra arguments to be passed for docker | `string` | `null` | no |
| <a name="input_file_defaults"></a> [file\_defaults](#input\_file\_defaults) | Default owner and permissions for files. | <pre>object({<br>    owner       = string<br>    permissions = string<br>  })</pre> | <pre>{<br>  "owner": "root",<br>  "permissions": "0644"<br>}</pre> | no |
| <a name="input_files"></a> [files](#input\_files) | Map of extra files to create on the instance, path as key. Owner and permissions will use defaults if null. | <pre>map(object({<br>    content     = string<br>    owner       = string<br>    permissions = string<br>  }))</pre> | `{}` | no |
| <a name="input_packages"></a> [packages](#input\_packages) | List of packages | `list(string)` | `[]` | no |
| <a name="input_run_commands"></a> [run\_commands](#input\_run\_commands) | List of cloud-init `runcmd`s | `list(string)` | `[]` | no |
| <a name="input_users"></a> [users](#input\_users) | List of usernames to be created. If provided, first user will be used to run the container. | <pre>list(object({<br>    username = string,<br>    uid      = number,<br>  }))</pre> | `[]` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_cloud_config"></a> [cloud\_config](#output\_cloud\_config) | Rendered cloud-config file to be passed as user-data instance metadata. |
<!-- END_TF_DOCS -->
