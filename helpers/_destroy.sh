#!/bin/bash

terraform_destroy() {
  terraform init
  terraform destroy -auto-approve -lock=false -parallelism=50
}

time terraform_destroy
