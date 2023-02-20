#!/bin/bash

uri=$1
echo $uri

RG="$(cut -d'/' -f5 <<<$uri)"
Vnet="$(cut -d'/' -f9 <<<$uri)"
Subnet="$(cut -d'/' -f11 <<<$uri)"

echo "RG = $RG"
echo "Vnet = $Vnet"
echo "Subnet = $Subnet"

az network vnet subnet update -g $RG -n $Subnet --vnet-name $Vnet --network-security-group null || true
az network vnet subnet delete -g $RG -n $Subnet --vnet-name $Vnet || true


