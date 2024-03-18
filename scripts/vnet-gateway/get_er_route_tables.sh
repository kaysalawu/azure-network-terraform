#!/bin/bash

char_pass="\u2714"
char_delete="\u274c"
char_question="\u2753"
char_notfound="\u26D4"
char_exclamation="\u2757"
char_celebrate="\u2B50"
char_executing="\u23F3"
char_arrow="\u279C"

rg=$1
echo -e "\nResource group: $rg\n"

usage() {
  echo "Usage: $0 <resource-group>"
  echo "-h, --help       Display help"
}

if [ -z $rg ]; then
  usage && echo
  return 1
fi

get_route_tables(){
  # for each ciruit in list_express_route_circuits, get all route tables
  mapfile -t circuits < <(az network express-route list -g "$rg" --query '[].name' -o tsv)
  for circuit in "${circuits[@]}"; do
    echo -e "\n$char_executing AzurePrivatePeering (Primary): $circuit"
    az network express-route list-route-tables -g "$rg" --name "$circuit" --path primary --peering-name AzurePrivatePeering --query value -o table --only-show-errors
    echo -e "\n$char_executing AzurePrivatePeering (Secondary): $circuit"
    az network express-route list-route-tables -g "$rg" --name "$circuit" --path secondary --peering-name AzurePrivatePeering --query value -o table --only-show-errors
  done
  echo -e "$char_celebrate Done!"
}

get_route_tables

