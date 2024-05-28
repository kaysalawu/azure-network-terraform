#!/bin/bash

char_pass="\u2714"
char_delete="\u274c"
char_question="\u2753"
char_notfound="\u26D4"
char_exclamation="\u2757"
char_celebrate="\u2B50"
char_executing="\u23F3"
char_arrow="\u279C"

echo -e "\n#######################################"
echo -e "Script: $(basename $0)"
echo "#######################################"

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
    mapfile -t gateways < <(az network vnet-gateway list -g "$rg" --query '[].name' -o tsv)
    for gateway in "${gateways[@]}"; do
        echo -e "$char_executing Processing gateway: $gateway"
        for connection in $(az network vpn-connection list -g "$rg" --vnet-gateway $gateway --query "[?contains(connectionType, 'ExpressRoute')].name" -o tsv); do
            echo -e "$char_question Deleting connection: $connection"
            az network vpn-connection delete -g "$rg" -n "$connection" --no-wait
            echo -e "$char_delete Deleted connection: $connection"
        done
    done
}

check_gateway_connection_status() {
  local all_deleted
  echo -e "$char_executing Checking status of gateway connections ..."
  while true; do
    all_deleted=true
    mapfile -t circuits < <(az network express-route list -g "$rg" --query '[].name' -o tsv)
    for gateway in "${gateways[@]}"; do
      for connection in $(az network vpn-connection list -g "$rg" --vnet-gateway $gateway --query "[?contains(connectionType, 'ExpressRoute')].name" -o tsv); do
        if [[ -n "$connection" ]]; then
          echo -e "     - $char_executing Waiting for gateway/conn $gateway/$connection to delete..."
          all_deleted=false
        fi
      done
    done
    if [[ $all_deleted == true ]]; then
      echo -e "   $char_pass All gateway connections deleted successfully."
      break
    else
      echo -e "   $char_arrow Gateway connections are still deleting. Checking again in 30 seconds..."
      sleep 30
    fi
  done
}

delete_express_route_gateway_connections
check_gateway_connection_status
