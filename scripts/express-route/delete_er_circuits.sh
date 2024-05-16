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

delete_express_route_circuits(){
  mapfile -t circuits < <(az network express-route list -g "$rg" --query '[].name' -o tsv)
  for circuit in "${circuits[@]}"; do
    echo -e "$char_executing Deleting circuit: $circuit"
    az network express-route delete -g "$rg" --name "$circuit" --no-wait
    done
}

check_circuit_status() {
  local all_deleted
  echo -e "$char_executing Checking status of circuits ..."
  while true; do
    all_deleted=true
    mapfile -t circuits < <(az network express-route list -g "$rg" --query '[].name' -o tsv)
    for circuit in "${circuits[@]}"; do
        if [[ -n "$circuit" ]]; then
            echo -e "     - $circuit still deleting ..."
            all_deleted=false
        fi
    done
    if [[ $all_deleted == true ]]; then
        echo -e "   $char_pass All circuits deleted successfully."
        break
        else
        echo -e "   $char_arrow Circuits are still deleting. Checking again in 10 seconds..."
        sleep 10
    fi
  done
}

delete_express_route_circuits
check_circuit_status
