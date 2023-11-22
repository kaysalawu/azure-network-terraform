#!/bin/bash

terraform_apply() {
  terraform fmt
  terraform init
  terraform apply -auto-approve -lock=false -parallelism=50
}

time terraform_apply
