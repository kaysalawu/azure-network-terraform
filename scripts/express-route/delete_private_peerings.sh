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

delete_express_route_private_peerings(){
  # for each ciruit in list_express_route_circuits, delete all peerings
  mapfile -t circuits < <(az network express-route list -g "$rg" --query '[].name' -o tsv)
  for circuit in "${circuits[@]}"; do
    echo -e "$char_executing Processing circuit: $circuit"
    for peering in $(az network express-route peering list -g "$rg" --circuit-name "$circuit" --query '[].name' -o tsv); do
      echo -e "   $char_delete Deleting: $peering"
      az network express-route peering delete -g "$rg" --circuit-name "$circuit" --name "$peering"
    done
  done
  echo -e "$char_celebrate Done!"
}

delete_express_route_private_peerings
