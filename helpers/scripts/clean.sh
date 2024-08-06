#!/bin/bash

rm -rf .terraform
rm .terraform.lock.hcl
rm terraform.tfstate.backup
terraform init
