#!/bin/bash

char_pass="\u2714"
char_delete="\u274c"
char_question="\u2753"
char_notfound="\u26D4"
char_exclamation="\u2757"
char_celebrate="\u2B50"
char_executing="\u23F3"
char_arrow="\u279C"
char_reset="\u27F3"

color_green=$(tput setaf 2)
color_red=$(tput setaf 1)
reset=$(tput sgr0)

# Arguments: Resource Group and Search String
resource_group=$1
search_string=$2

# Login to Azure (uncomment if needed)
# az login

# Get VMs in the resource group matching the search string
vms=$(az vm list -g $resource_group --query "[?contains(name, '$search_string')].name" -o tsv)

echo -e  "\nThe following VMs will be reset:"
echo -e "$vms\n"

# Confirm reset
read -p "Do you want to reset these VMs? (y/n): " confirm

if [[ $confirm == "y" ]]; then
    for vm in $vms; do
        echo -e "${color_red}${char_reset}${reset}  Resetting VM: $vm"
        az vm restart -g $resource_group -n $vm --no-wait
    done
else
    echo "VM reset cancelled."
    return 0
fi
