#!/bin/bash

time terraform_destroy

clockz
rm -rf .terraform
rm .terraform.lock.hcl
rm terraform.tfstate.backup
terraform init
