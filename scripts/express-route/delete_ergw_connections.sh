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

delete_express_route_gateway_connections(){
    # for each ciruit in list_express_route_circuits, delete all gateway connections
    mapfile -t circuits < <(az network express-route list -g "$rg" --query '[].name' -o tsv)
    for circuit in "${circuits[@]}"; do
        echo -e "$char_executing Processing circuit: $circuit"
        for connection in $(az network vpn-connection list -g "$rg" --query "[?contains(connectionType, 'ExpressRoute')].name" -o tsv); do
            echo -e "$char_question Deleting connection: $connection"
            az network vpn-connection delete -g "$rg" -n "$connection"
            echo -e "$char_delete Deleted connection: $connection"
        done
    done
}

delete_express_route_gateway_connections
